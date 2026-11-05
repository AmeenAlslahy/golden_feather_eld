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
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import com.goldenfeather.golden_feather_eld.MainActivity
import com.goldenfeather.golden_feather_eld.R
import com.goldenfeather.golden_feather_eld.bluetooth.BleReconnectPolicy
import com.goldenfeather.golden_feather_eld.database.LocationDatabaseHelper
import com.goldenfeather.golden_feather_eld.database.NetworkUploader
import com.goldenfeather.golden_feather_eld.location.LastKnownLocationSource
import com.goldenfeather.golden_feather_eld.plugins.BleConnectionStateListener
import com.goldenfeather.golden_feather_eld.plugins.BluetoothPlugin

// Decision 2 (P1): Reconnect Loop.
// Manages the infinite exponential backoff BLE reconnection loop inside the Foreground Service.
class TrackingForegroundService : Service(), LocationListener, BleConnectionStateListener {

    companion object {
        const val CHANNEL_ID = "tracking_service"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "START_TRACKING"
        const val ACTION_STOP = "STOP_TRACKING"
        const val ACTION_LOCATION_UPDATE = "ACTION_LOCATION_UPDATE"
        
        // Decision 2 (P1): Reconnect Loop actions
        const val ACTION_SET_MANUAL_MODE = "com.goldenfeather.eld.SET_MANUAL_MODE"
        const val ACTION_SET_SESSION_ACTIVE = "com.goldenfeather.eld.SET_SESSION_ACTIVE"
        const val ACTION_SET_SESSION_STATE = "com.goldenfeather.eld.SET_SESSION_STATE"

        // Defaults
        private const val DEFAULT_INTERVAL = 5000L
        private const val DEFAULT_DISTANCE = 50f
    }

    private var locationManager: LocationManager? = null
    private var isTracking = false
    private lateinit var dbHelper: LocationDatabaseHelper
    private lateinit var networkUploader: NetworkUploader

    // Decision 2 (P1): Reconnect Loop state variables.
    // Dedicated HandlerThread ensures BLE reconnection attempts, IPC, and disk I/O
    // do not block the Android Main UI Thread (preventing UI freezes and ANRs).
    private var reconnectThread: HandlerThread? = null
    private var reconnectHandler: Handler? = null
    internal var reconnectRunnable: Runnable? = null

    internal fun getOrCreateReconnectHandler(): Handler {
        if (reconnectHandler == null) {
            val thread = HandlerThread("BleReconnectThread").apply { start() }
            reconnectThread = thread
            reconnectHandler = Handler(thread.looper)
        }
        return reconnectHandler!!
    }

    internal fun setReconnectHandlerForTesting(handler: Handler) {
        this.reconnectHandler = handler
    }

    @Volatile
    var consecutiveFailures: Int = 0
        private set

    @Volatile
    var isSessionActive: Boolean = false

    @Volatile
    var isManualMode: Boolean = false

    @Volatile
    var targetMacAddress: String? = null

    override fun onCreate() {
        super.onCreate()
        dbHelper = LocationDatabaseHelper(this)
        networkUploader = NetworkUploader(this)
        createNotificationChannel()

        // Decision 2 (P1): Reconnect Loop. Register listener on BluetoothPlugin.
        BluetoothPlugin.instance?.addConnectionStateListener(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                isSessionActive = true
                startForeground()
            }
            ACTION_STOP -> {
                isSessionActive = false
                stopReconnectLoop()
                stopForeground()
            }
            ACTION_SET_MANUAL_MODE -> {
                val manual = intent.getBooleanExtra("manualMode", false)
                applyManualMode(manual)
            }
            ACTION_SET_SESSION_ACTIVE -> {
                val active = intent.getBooleanExtra("sessionActive", true)
                isSessionActive = active
                if (!active) stopReconnectLoop()
            }
            ACTION_SET_SESSION_STATE -> {
                val active = intent.getBooleanExtra("sessionActive", false)
                val manual = intent.getBooleanExtra("manualMode", false)
                val clearMac = intent.getBooleanExtra("clearMac", false)
                isSessionActive = active
                applyManualMode(manual)
                if (clearMac) {
                    targetMacAddress = null
                    consecutiveFailures = 0
                }
                if (!active || manual) {
                    stopReconnectLoop()
                }
            }
        }
        return START_STICKY
    }

    // Decision 2 (P1): Reconnect Loop. Callback from BluetoothPlugin.
    override fun onConnectionStateChange(isConnected: Boolean, macAddress: String?) {
        if (!macAddress.isNullOrEmpty()) {
            targetMacAddress = macAddress
        }
        if (isConnected) {
            Log.i("TRACKING_SVC", "Decision 2 (P1): BLE Connected. Resetting reconnect counter.")
            consecutiveFailures = 0
            stopReconnectLoop()
            updateTrackingNotification("Tracking in progress...")
        } else {
            // Consecutive failures incremented on disconnect per policy
            consecutiveFailures++
            Log.w("TRACKING_SVC", "Decision 2 (P1): BLE Disconnected (consecutiveFailures=$consecutiveFailures). Triggering reconnect loop.")
            scheduleReconnect()
        }
    }

    // Decision 2 (P1): Reconnect Loop. Handle manual mode toggle with counter reset policy.
    private fun applyManualMode(enabled: Boolean) {
        isManualMode = enabled
        if (enabled) {
            Log.i("TRACKING_SVC", "Decision 2 (P1): Manual mode enabled. Halting reconnect loop immediately and resetting counter.")
            stopReconnectLoop()
            consecutiveFailures = 0
        } else {
            Log.i("TRACKING_SVC", "Decision 2 (P1): Manual mode disabled.")
        }
    }

    // Decision 2 (P1): Reconnect Loop. Schedule next reconnection attempt.
    private fun scheduleReconnect() {
        val mac = targetMacAddress
            ?: BluetoothPlugin.instance?.lastMacAddress
            ?: getSharedPreferences("eld_config", Context.MODE_PRIVATE).getString("last_mac_address", null)

        // Explicit stop condition check before scheduling
        if (!BleReconnectPolicy.canAttemptReconnect(isSessionActive, isManualMode, mac)) {
            Log.i("TRACKING_SVC", "Decision 2 (P1): Reconnect suppressed (isSessionActive=$isSessionActive, isManualMode=$isManualMode, mac=$mac)")
            return
        }

        // Backoff based on failure count
        val delaySeconds = BleReconnectPolicy.getBackoffDelaySeconds(consecutiveFailures - 1)
        val delayMs = delaySeconds * 1000L

        val handler = getOrCreateReconnectHandler()
        stopReconnectLoop()

        reconnectRunnable = Runnable {
            // Explicit stop condition check before attempt
            if (!BleReconnectPolicy.canAttemptReconnect(isSessionActive, isManualMode, mac)) {
                Log.i("TRACKING_SVC", "Decision 2 (P1): Reconnect attempt cancelled by stop conditions.")
                stopReconnectLoop()
                return@Runnable
            }

            Log.w("TRACKING_SVC", "Decision 2 (P1): Reconnect executing attempt #$consecutiveFailures to $mac with delay ${delaySeconds}s")

            // Threshold alerts: 5, 10, 15...
            if (BleReconnectPolicy.shouldTriggerAlert(consecutiveFailures)) {
                notifyReconnectAlert(consecutiveFailures, mac!!)
            }

            val plugin = BluetoothPlugin.instance
            val initiated = plugin?.executeConnect(mac!!) ?: false
            if (!initiated) {
                // If initial connect call failed immediately, increment and schedule next retry
                consecutiveFailures++
                scheduleReconnect()
            }
        }

        handler.postDelayed(reconnectRunnable!!, delayMs)
    }

    // Decision 2 (P1): Reconnect Loop. Notify alert at attempts 5, 10, 15...
    private fun notifyReconnectAlert(attempt: Int, mac: String) {
        Log.w("TRACKING_SVC", "Decision 2 (P1): Reconnect alert triggered for attempt #$attempt")
        updateTrackingNotification("ELD Disconnected: Reconnect attempt #$attempt...")

        // Emit event via BluetoothPlugin EventChannel to Flutter
        BluetoothPlugin.instance?.emitReconnectAlert(attempt)
    }

    // Decision 2 (P1): Reconnect Loop. Update foreground notification content.
    private fun updateTrackingNotification(text: String) {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Golden Feather ELD")
                .setContentText(text)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build()
            notificationManager?.notify(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.e("TRACKING_SVC", "Failed to update notification", e)
        }
    }

    // Decision 2 (P1): Reconnect Loop. Stop pending reconnect callbacks.
    fun stopReconnectLoop() {
        reconnectRunnable?.let {
            reconnectHandler?.removeCallbacks(it)
        }
        reconnectRunnable = null
    }

    override fun onDestroy() {
        super.onDestroy()
        // Decision 2 (P1): Reconnect Loop. Complete cleanup on destroy to avoid memory leaks or battery drain.
        BluetoothPlugin.instance?.removeConnectionStateListener(this)
        stopReconnectLoop()
        reconnectThread?.quitSafely()
        reconnectThread = null
        reconnectHandler = null
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

            // بذر فوري بآخر قفل حديث: قراءة فقط، بلا تخزين أو رفع. يمنع
            // بقاء الواجهة فارغة حتى أول دورة تحديث (5 دقائق/75 متراً).
            seedLastKnownLocation()
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
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.createNotificationChannel(channel)
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
        broadcastLocation(location, System.currentTimeMillis())
    }

    /**
     * يبثّ آخر قفل حديث إلى Flutter دون حفظه أو رفعه. النافذة قصيرة في
     * [LastKnownLocationSource] حتى لا يُعرض موقع قديم كأنه الحالي.
     */
    private fun seedLastKnownLocation() {
        val seeded = LastKnownLocationSource.latest(this) ?: return
        Log.i("TRACKING_SVC", "Seeded last known location.")
        broadcastLocation(seeded, seeded.time)
    }

    private fun broadcastLocation(location: Location, timestampMillis: Long) {
        val intent = Intent(ACTION_LOCATION_UPDATE).apply {
            putExtra("latitude", location.latitude)
            putExtra("longitude", location.longitude)
            putExtra("speed", location.speed.toDouble())
            putExtra("bearing", location.bearing.toDouble())
            putExtra("altitude", location.altitude)
            putExtra("accuracy", location.accuracy.toDouble())
            putExtra("timestamp", timestampMillis)
        }
        sendBroadcast(intent)
    }
}
