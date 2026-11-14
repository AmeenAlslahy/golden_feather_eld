package com.goldenfeather.golden_feather_eld.plugins

import com.goldenfeather.golden_feather_eld.database.LocationDatabaseHelper
import com.goldenfeather.golden_feather_eld.database.NetworkUploader
import com.goldenfeather.golden_feather_eld.logging.NativeLogStore
import com.goldenfeather.golden_feather_eld.services.TrackingForegroundService
import com.goldenfeather.golden_feather_eld.services.TrackingServiceManager
import com.goldenfeather.golden_feather_eld.location.LastKnownLocationSource
import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * TraccarPlugin - تتبع GPS حقيقي للتواصل مع خادم Traccar
 * يرسل المواقع عبر MethodChannel و EventChannel
 *
 * The native side is the single source of truth for tracking state. It persists
 * `tracking_enabled`, so `isTracking` survives a process restart and the boot
 * receiver can decide whether to resume.
 */
class TraccarPlugin(
    private val context: Context
) : MethodCallHandler {

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
                intent.getStringExtra("source")?.let { data["source"] = it }

                sendEventToFlutter(data)
            }
        }
    }
    private var cachedLocationData: Map<String, Any>? = null

    private val dbHelper by lazy { LocationDatabaseHelper(context) }
    private val networkUploader by lazy { NetworkUploader(context) }
    private var connectivityManager: ConnectivityManager? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    private val prefs: SharedPreferences
        get() = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    companion object {
        const val METHOD_CHANNEL = "com.goldenfeather.eld/traccar"
        const val EVENT_CHANNEL = "com.goldenfeather.eld/traccar/events"

        private const val PREFS_NAME = "traccar_config"
        private const val KEY_TRACKING_ENABLED = "tracking_enabled"

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
                NativeLogStore.info("Sent cached location on sink attach")
            } else {
                seedLastKnownLocation(sink)
            }
        } else {
            try {
                context.unregisterReceiver(locationReceiver)
            } catch (_: Exception) {
                // Ignore if not registered
            }
        }
    }

    private fun sendEventToFlutter(data: Map<String, Any>) {
        if (eventSink != null) {
            eventSink?.success(data)
        } else {
            cachedLocationData = data
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "setConfig" -> setConfig(call, result)
                "start" -> startTracking(result)
                "stop" -> stopTracking(result)
                "isTracking" -> result.success(isTrackingEnabled())
                "requestPosition" -> requestPosition(call, result)
                "pushLocation" -> pushLocation(call, result)
                "getLastKnownPosition" -> getLastKnownPosition(result)
                "getLogs" -> result.success(NativeLogStore.snapshot())
                "clearLogs" -> {
                    NativeLogStore.clear()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            NativeLogStore.error("Method ${call.method} failed: ${e.message}")
            result.error("TRACCAR_ERROR", e.message, null)
        }
    }

    // ========== الإعدادات ==========

    private fun setConfig(call: MethodCall, result: Result) {
        val serverUrl = call.argument<String>("serverUrl") ?: ""
        val deviceId = call.argument<String>("deviceId") ?: ""
        val locationConfig = call.argument<Map<String, Any>>("location")

        fun number(key: String, fallback: Double): Double {
            val raw = locationConfig?.get(key) ?: call.argument<Any>(key)
            return (raw as? Number)?.toDouble() ?: fallback
        }

        fun bool(key: String, fallback: Boolean): Boolean {
            val raw = locationConfig?.get(key) ?: call.argument<Any>(key)
            return raw as? Boolean ?: fallback
        }

        val intervalSeconds = number("intervalSeconds", DEFAULT_INTERVAL / 1000.0)
        val distanceMeters = number("distanceMeters", DEFAULT_DISTANCE.toDouble())
        val accuracy = (locationConfig?.get("accuracy") as? String)
            ?: call.argument<String>("accuracy")
            ?: "medium"
        val angle = number("angleDegrees", 0.0).toInt()
        val heartbeat = number("heartbeatIntervalSeconds", 0.0).toLong()
        val stopDetection = bool("stopDetection", true)
        val buffer = bool("buffer", true)
        val wakeLock = call.argument<Boolean>("wakeLock")
            ?: call.argument<Boolean>("wakelock")
            ?: bool("wakelock", false)
        val preferPlatformProviders = call.argument<Boolean>("preferPlatformProviders") ?: false
        val sourceMode = call.argument<String>("sourceMode") ?: "hybrid"
        val notificationText = call.argument<String>("notificationText")
            ?: locationConfig?.get("notificationText") as? String
            ?: "Tracking in progress..."

        prefs.edit()
            .putLong("interval", intervalSeconds.toLong() * 1000L)
            .putFloat("distance", distanceMeters.toFloat())
            .putString("accuracy", accuracy)
            .putInt("angle", angle)
            .putLong("heartbeat", heartbeat)
            .putBoolean("stop_detection", stopDetection)
            .putBoolean("buffer", buffer)
            .putBoolean("wakelock", wakeLock)
            .putBoolean("prefer_platform_providers", preferPlatformProviders)
            .putString("notification_text", notificationText)
            .putString("source_mode", sourceMode)
            .putString("serverUrl", serverUrl)
            .putString("deviceId", deviceId)
            .apply()

        NativeLogStore.info(
            "Config applied (server configured=${serverUrl.isNotBlank()}, " +
                "interval=${intervalSeconds.toLong()}s, distance=${distanceMeters.toInt()}m, " +
                "accuracy=$accuracy, heartbeat=${heartbeat}s, buffer=$buffer, wakelock=$wakeLock)"
        )
        result.success(true)
    }

    // ========== التحكم ==========

    @SuppressLint("MissingPermission")
    private fun startTracking(result: Result) {
        NativeLogStore.info("startTracking called from Flutter")
        if (isTrackingEnabled()) {
            NativeLogStore.info("Already tracking, returning success")
            result.success(true)
            return
        }

        if (!checkLocationPermission()) {
            result.error("PERMISSION_DENIED", "Location permission not granted", null)
            return
        }

        try {
            setupNetworkListener()
            prefs.edit().putBoolean(KEY_TRACKING_ENABLED, true).apply()
            TrackingServiceManager.start(context)
            NativeLogStore.info("Tracking service started")
            result.success(true)
        } catch (e: SecurityException) {
            NativeLogStore.error("Security exception: ${e.message}")
            result.error("SECURITY_ERROR", "Security exception: ${e.message}", null)
        } catch (e: Exception) {
            NativeLogStore.error("Failed to start tracking: ${e.message}")
            result.error("START_ERROR", "Failed to start tracking: ${e.message}", null)
        }
    }

    private fun stopTracking(result: Result) {
        try {
            teardownNetworkListener()
            prefs.edit().putBoolean(KEY_TRACKING_ENABLED, false).apply()
            TrackingServiceManager.stop(context)
            result.success(true)
        } catch (e: Exception) {
            result.error("STOP_ERROR", "Failed to stop tracking: ${e.message}", null)
        }
    }

    private fun isTrackingEnabled(): Boolean =
        prefs.getBoolean(KEY_TRACKING_ENABLED, false)

    // ========== المواقع ==========

    @SuppressLint("MissingPermission")
    private fun requestPosition(call: MethodCall, result: Result) {
        if (!checkLocationPermission()) {
            result.error("PERMISSION_DENIED", "Location permission not granted", null)
            return
        }

        val alarm = call.argument<String>("alarm")
        val locManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

        var location = locManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
        if (location == null) {
            location = locManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
        }

        if (location != null) {
            dbHelper.insertLocation(location, alarm = alarm, source = "phone")
            triggerUpload()
            val data = locationToMap(location, alarm)
            sendEventToFlutter(data)
            result.success(data)
        } else {
            NativeLogStore.error("requestPosition: No last known location available")
            result.error("NO_LOCATION", "No last known location", null)
        }
    }

    /**
     * Accepts a fix produced outside Android's LocationManager (BLE ELD device,
     * NMEA parser, replayed frame). Speed must be metres per second.
     *
     * The fix goes through the same SQLite queue + uploader as phone GPS, so BLE
     * tracking keeps working offline and uses the same retry policy.
     */
    private fun pushLocation(call: MethodCall, result: Result) {
        val latitude = (call.argument<Any>("latitude") as? Number)?.toDouble()
        val longitude = (call.argument<Any>("longitude") as? Number)?.toDouble()
        if (latitude == null || longitude == null ||
            latitude !in -90.0..90.0 || longitude !in -180.0..180.0
        ) {
            result.error("INVALID_LOCATION", "Valid latitude/longitude required", null)
            return
        }

        val speed = (call.argument<Any>("speed") as? Number)?.toDouble() ?: 0.0
        val bearing = (call.argument<Any>("bearing") as? Number)?.toDouble() ?: 0.0
        val altitude = (call.argument<Any>("altitude") as? Number)?.toDouble() ?: 0.0
        val accuracy = (call.argument<Any>("accuracy") as? Number)?.toDouble() ?: 0.0
        val alarm = call.argument<String>("alarm")
        val source = call.argument<String>("source") ?: "ble"

        val rawTimestamp = (call.argument<Any>("timestamp") as? Number)?.toLong()
            ?: (System.currentTimeMillis() / 1000)
        // Accept both epoch seconds and epoch milliseconds.
        val timestampSeconds = if (rawTimestamp > 100_000_000_000L) {
            rawTimestamp / 1000
        } else {
            rawTimestamp
        }

        dbHelper.insertRawLocation(
            latitude = latitude,
            longitude = longitude,
            speedMps = speed,
            bearing = bearing,
            altitude = altitude,
            accuracy = accuracy,
            timestampSeconds = timestampSeconds,
            alarm = alarm,
            source = source
        )
        triggerUpload()

        val data = mutableMapOf<String, Any>(
            "latitude" to latitude,
            "longitude" to longitude,
            "speed" to speed,
            "bearing" to bearing,
            "altitude" to altitude,
            "accuracy" to accuracy,
            "timestamp" to timestampSeconds * 1000,
            "source" to source
        )
        if (alarm != null) data["alarm"] = alarm
        sendEventToFlutter(data)
        result.success(data)
    }

    private fun triggerUpload() {
        networkUploader.triggerUpload(
            prefs.getString("serverUrl", "") ?: "",
            prefs.getString("deviceId", "") ?: ""
        )
    }

    /**
     * قراءة فقط لآخر قفل حديث من نظام التشغيل. لا تُدخل في SQLite ولا ترفع
     * إلى Traccar — على عكس [requestPosition] التي تُطلق دورة رفع كاملة.
     */
    @SuppressLint("MissingPermission")
    private fun getLastKnownPosition(result: Result) {
        if (!checkLocationPermission()) {
            result.error("PERMISSION_DENIED", "Location permission not granted", null)
            return
        }
        // In BLE-only mode the ELD owns the position stream; seeding the UI with
        // a stale phone fix would claim a location the device never reported.
        if (isBleOnlySourceMode()) {
            result.success(null)
            return
        }

        val location = LastKnownLocationSource.latest(context)
        if (location == null) {
            NativeLogStore.info("getLastKnownPosition: No fresh cached fix")
            result.success(null)
            return
        }
        result.success(locationToMap(location, null, location.time))
    }

    @SuppressLint("MissingPermission")
    private fun seedLastKnownLocation(sink: EventChannel.EventSink) {
        if (isBleOnlySourceMode()) return
        val location = LastKnownLocationSource.latest(context) ?: return
        sink.success(locationToMap(location, null, location.time))
        NativeLogStore.info("Seeded last known location on sink attach")
    }

    private fun isBleOnlySourceMode(): Boolean =
        (prefs.getString("source_mode", "hybrid") ?: "hybrid") == "bleDevice"

    // ========== الشبكة ==========

    private fun setupNetworkListener() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            connectivityManager =
                context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            networkCallback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    super.onAvailable(network)
                    NativeLogStore.info("Network restored. Flushing upload queue...")
                    triggerUpload()
                }
            }
            val request = NetworkRequest.Builder()
                .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .build()
            try {
                connectivityManager?.registerNetworkCallback(request, networkCallback!!)
            } catch (_: Exception) {
                // Already registered / permission missing.
            }
        }
    }

    private fun teardownNetworkListener() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            networkCallback?.let {
                try {
                    connectivityManager?.unregisterNetworkCallback(it)
                } catch (_: Exception) {
                }
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

    private fun locationToMap(
        location: Location,
        alarm: String?,
        timestampMillis: Long = System.currentTimeMillis()
    ): Map<String, Any> {
        val map = mutableMapOf<String, Any>(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "speed" to location.speed.toDouble(),
            "bearing" to location.bearing.toDouble(),
            "altitude" to location.altitude,
            "accuracy" to location.accuracy.toDouble(),
            "timestamp" to timestampMillis,
            "source" to "phone"
        )
        if (alarm != null) {
            map["alarm"] = alarm
        }
        return map
    }
}
