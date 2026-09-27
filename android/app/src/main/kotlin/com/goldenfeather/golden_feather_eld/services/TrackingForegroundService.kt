package com.goldenfeather.golden_feather_eld.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import com.goldenfeather.golden_feather_eld.MainActivity
import com.goldenfeather.golden_feather_eld.R
import com.goldenfeather.golden_feather_eld.database.LocationDatabaseHelper
import com.goldenfeather.golden_feather_eld.database.NetworkUploader

class TrackingForegroundService : Service(), LocationListener {

    companion object {
        const val CHANNEL_ID = "tracking_service"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "START_TRACKING"
        const val ACTION_STOP = "STOP_TRACKING"
        const val ACTION_LOCATION_UPDATE = "ACTION_LOCATION_UPDATE"
        
        // Defaults
        private const val DEFAULT_INTERVAL = 5000L
        private const val DEFAULT_DISTANCE = 50f
    }

    private var locationManager: LocationManager? = null
    private var isTracking = false
    private lateinit var dbHelper: LocationDatabaseHelper
    private lateinit var networkUploader: NetworkUploader

    override fun onCreate() {
        super.onCreate()
        dbHelper = LocationDatabaseHelper(this)
        networkUploader = NetworkUploader(this)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startForeground()
            ACTION_STOP -> stopForeground()
        }
        return START_STICKY
    }

    private fun startForeground() {
        if (isTracking) return

        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)

        startLocationTracking()
    }

    private fun startLocationTracking() {
        val prefs = getSharedPreferences("traccar_config", Context.MODE_PRIVATE)
        val interval = prefs.getLong("interval", DEFAULT_INTERVAL)
        val distance = prefs.getFloat("distance", DEFAULT_DISTANCE)

        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager

        try {
            locationManager?.requestLocationUpdates(
                LocationManager.GPS_PROVIDER,
                interval,
                distance,
                this,
                Looper.getMainLooper()
            )
            
            if (locationManager?.isProviderEnabled(LocationManager.NETWORK_PROVIDER) == true) {
                locationManager?.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    interval,
                    distance,
                    this,
                    Looper.getMainLooper()
                )
            }
            
            isTracking = true
            Log.i("TRACKING_SVC", "Native location tracking started.")
        } catch (e: SecurityException) {
            Log.e("TRACKING_SVC", "Missing location permissions", e)
        } catch (e: Exception) {
            Log.e("TRACKING_SVC", "Failed to start location tracking", e)
        }
    }

    private fun stopForeground() {
        try {
            locationManager?.removeUpdates(this)
        } catch (e: Exception) {
            Log.e("TRACKING_SVC", "Failed to remove updates", e)
        }
        isTracking = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun buildNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Golden Feather ELD")
            .setContentText("Tracking in progress...")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Tracking Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onLocationChanged(location: Location) {
        Log.i("TRACKING_SVC", "New Location: ${location.latitude}, ${location.longitude}")

        // 1. Save to SQLite
        dbHelper.insertLocation(location)

        // 2. Trigger Upload
        val prefs = getSharedPreferences("traccar_config", Context.MODE_PRIVATE)
        val serverUrl = prefs.getString("serverUrl", "") ?: ""
        val deviceId = prefs.getString("deviceId", "") ?: ""
        networkUploader.triggerUpload(serverUrl, deviceId)

        // 3. Broadcast for Flutter UI
        val intent = Intent(ACTION_LOCATION_UPDATE).apply {
            putExtra("latitude", location.latitude)
            putExtra("longitude", location.longitude)
            putExtra("speed", location.speed.toDouble())
            putExtra("bearing", location.bearing.toDouble())
            putExtra("altitude", location.altitude)
            putExtra("accuracy", location.accuracy.toDouble())
            putExtra("timestamp", System.currentTimeMillis())
        }
        sendBroadcast(intent)
    }
}
