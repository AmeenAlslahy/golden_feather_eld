package com.goldenfeather.golden_feather_eld.plugins

import com.goldenfeather.golden_feather_eld.database.LocationDatabaseHelper
import com.goldenfeather.golden_feather_eld.database.NetworkUploader
import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.goldenfeather.golden_feather_eld.services.TrackingForegroundService
import com.goldenfeather.golden_feather_eld.services.TrackingServiceManager

/**
 * TraccarPlugin - تتبع GPS حقيقي للتواصل مع خادم Traccar
 * يرسل المواقع عبر MethodChannel و EventChannel
 */
class TraccarPlugin(
    private val context: Context
) : MethodCallHandler {

    private var isTracking = false
    private var eventSink: EventChannel.EventSink? = null
    
    private val locationReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == TrackingForegroundService.ACTION_LOCATION_UPDATE) {
                val data = mutableMapOf<String, Any>()
                data["latitude"] = intent.getDoubleExtra("latitude", 0.0)
                data["longitude"] = intent.getDoubleExtra("longitude", 0.0)
                data["speed"] = intent.getDoubleExtra("speed", 0.0)
                data["bearing"] = intent.getDoubleExtra("bearing", 0.0)
                data["altitude"] = intent.getDoubleExtra("altitude", 0.0)
                data["accuracy"] = intent.getDoubleExtra("accuracy", 0.0)
                data["timestamp"] = intent.getLongExtra("timestamp", System.currentTimeMillis())
                
                sendEventToFlutter(data)
            }
        }
    }
    private var cachedLocationData: Map<String, Any>? = null
    private val handler = Handler(Looper.getMainLooper())
    
    private val dbHelper by lazy { LocationDatabaseHelper(context) }
    private val networkUploader by lazy { NetworkUploader(dbHelper) }
    private var connectivityManager: ConnectivityManager? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    companion object {
        const val METHOD_CHANNEL = "com.goldenfeather.eld/traccar"
        const val EVENT_CHANNEL = "com.goldenfeather.eld/traccar/events"

        // إعدادات افتراضية
        private const val DEFAULT_INTERVAL = 5000L  // 5 ثواني
        private const val DEFAULT_DISTANCE = 50f    // 50 متر
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
        if (sink != null) {
            val filter = IntentFilter(TrackingForegroundService.ACTION_LOCATION_UPDATE)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(locationReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                context.registerReceiver(locationReceiver, filter)
            }
            if (cachedLocationData != null) {
                sink.success(cachedLocationData)
                cachedLocationData = null
                android.util.Log.i("TRACCAR_PLUGIN", "Sent cached location on sink attach")
            }
        } else {
            try {
                context.unregisterReceiver(locationReceiver)
            } catch (e: Exception) {
                // Ignore if not registered
            }
        }
    }

    private fun sendEventToFlutter(data: Map<String, Any>) {
        if (eventSink != null) {
            eventSink?.success(data)
            android.util.Log.i("TRACCAR_PLUGIN", "Event sent to Flutter")
        } else {
            cachedLocationData = data
            android.util.Log.i("TRACCAR_PLUGIN", "Event cached, sink is null")
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "setConfig" -> setConfig(call, result)
                "start" -> startTracking(result)
                "stop" -> stopTracking(result)
                "isTracking" -> result.success(isTracking)
                "requestPosition" -> requestPosition(call, result)
                "getLogs" -> result.success(emptyList<Map<String, Any>>())
                "clearLogs" -> {
                    // مسح السجلات - لا يوجد تخزين Native حالياً
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("TRACCAR_ERROR", e.message, null)
        }
    }

    private fun setConfig(call: MethodCall, result: Result) {
        // استخراج إعدادات التتبع من Dart
        val serverUrl = call.argument<String>("serverUrl") ?: ""
        val deviceId = call.argument<String>("deviceId") ?: ""
        
        val locationConfig = call.argument<Map<String, Any>>("location")
        val interval = (locationConfig?.get("intervalSeconds") as? Number)?.toLong() ?: DEFAULT_INTERVAL
        val distance = (locationConfig?.get("distanceMeters") as? Number)?.toFloat() ?: DEFAULT_DISTANCE

        // تخزين الإعدادات محلياً
        val prefs = context.getSharedPreferences("traccar_config", Context.MODE_PRIVATE)
        prefs.edit()
            .putLong("interval", interval * 1000)
            .putFloat("distance", distance)
            .putString("serverUrl", serverUrl)
            .putString("deviceId", deviceId)
            .apply()

        result.success(true)
    }

    @SuppressLint("MissingPermission")
    private fun startTracking(result: Result) {
        android.util.Log.i("TRACCAR_PLUGIN", "startTracking called from Flutter")
        if (isTracking) {
            android.util.Log.i("TRACCAR_PLUGIN", "Already tracking, returning success")
            result.success(true)
            return
        }

        val hasPermission = checkLocationPermission()
        if (!hasPermission) {
            result.error("PERMISSION_DENIED", "Location permission not granted", null)
            return
        }

        try {
            setupNetworkListener()
            isTracking = true
            TrackingServiceManager.start(context)
            android.util.Log.i("TRACCAR_PLUGIN", "TrackingServiceManager started successfully")
            result.success(true)
        } catch (e: SecurityException) {
            android.util.Log.e("TRACCAR_PLUGIN", "Security exception", e)
            result.error("SECURITY_ERROR", "Security exception: ${e.message}", null)
        } catch (e: Exception) {
            android.util.Log.e("TRACCAR_PLUGIN", "Failed to start tracking", e)
            result.error("START_ERROR", "Failed to start tracking: ${e.message}", null)
        }
    }

    private fun stopTracking(result: Result) {
        try {
            teardownNetworkListener()
            isTracking = false
            TrackingServiceManager.stop(context)
            result.success(true)
        } catch (e: Exception) {
            result.error("STOP_ERROR", "Failed to stop tracking: ${e.message}", null)
        }
    }

    @SuppressLint("MissingPermission")
    private fun requestPosition(call: MethodCall, result: Result) {
        val hasPermission = checkLocationPermission()
        if (!hasPermission) {
            result.error("PERMISSION_DENIED", "Location permission not granted", null)
            return
        }

        val alarm = call.argument<String>("alarm")
        val locManager = context.getSystemService(Context.LOCATION_SERVICE) as android.location.LocationManager

        var location = locManager.getLastKnownLocation(android.location.LocationManager.GPS_PROVIDER)
        if (location == null) {
            location = locManager.getLastKnownLocation(android.location.LocationManager.NETWORK_PROVIDER)
        }

        if (location != null) {
            // 1. Insert into DB
            dbHelper.insertLocation(location)
            
            // 2. Trigger Upload
            val prefs = context.getSharedPreferences("traccar_config", Context.MODE_PRIVATE)
            val serverUrl = prefs.getString("serverUrl", "") ?: ""
            val deviceId = prefs.getString("deviceId", "") ?: ""
            networkUploader.triggerUpload(serverUrl, deviceId)

            val data = locationToMap(location, alarm)
            sendEventToFlutter(data)
            result.success(data)
        } else {
            android.util.Log.e("TRACCAR_PLUGIN", "requestPosition: No last known location available")
            result.error("NO_LOCATION", "No last known location", null)
        }
    }

    private fun setupNetworkListener() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            networkCallback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    super.onAvailable(network)
                    android.util.Log.i("TRACCAR_PLUGIN", "Network restored. Triggering upload queue...")
                    val prefs = context.getSharedPreferences("traccar_config", Context.MODE_PRIVATE)
                    val serverUrl = prefs.getString("serverUrl", "") ?: ""
                    val deviceId = prefs.getString("deviceId", "") ?: ""
                    networkUploader.triggerUpload(serverUrl, deviceId)
                }
            }
            val request = NetworkRequest.Builder()
                .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .build()
            connectivityManager?.registerNetworkCallback(request, networkCallback!!)
        }
    }

    private fun teardownNetworkListener() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            networkCallback?.let {
                connectivityManager?.unregisterNetworkCallback(it)
            }
            networkCallback = null
        }
    }

    private fun checkLocationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
                    PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun locationToMap(location: Location, alarm: String?): Map<String, Any> {
        val map = mutableMapOf<String, Any>(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "speed" to location.speed.toDouble(),
            "bearing" to location.bearing.toDouble(),
            "altitude" to location.altitude,
            "accuracy" to location.accuracy.toDouble(),
            "timestamp" to System.currentTimeMillis()
        )
        if (alarm != null) {
            map["alarm"] = alarm
        }
        return map
    }
}
