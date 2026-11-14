package com.goldenfeather.golden_feather_eld.services

import android.annotation.SuppressLint
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
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import com.goldenfeather.golden_feather_eld.MainActivity
import com.goldenfeather.golden_feather_eld.R
import com.goldenfeather.golden_feather_eld.bluetooth.BleReconnectPolicy
import com.goldenfeather.golden_feather_eld.database.LocationDatabaseHelper
import com.goldenfeather.golden_feather_eld.database.NetworkUploader
import com.goldenfeather.golden_feather_eld.location.LastKnownLocationSource
import com.goldenfeather.golden_feather_eld.location.TrackingLocationFilter
import com.goldenfeather.golden_feather_eld.logging.NativeLogStore
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

        private const val PREFS_NAME = "traccar_config"
        private const val KEY_TRACKING_ENABLED = "tracking_enabled"

        // Defaults
        private const val DEFAULT_INTERVAL = 5000L
        private const val DEFAULT_DISTANCE = 50f
    }

    private var locationManager: LocationManager? = null
    private var isTracking = false
    private lateinit var dbHelper: LocationDatabaseHelper
    private lateinit var networkUploader: NetworkUploader
    private var locationFilter: TrackingLocationFilter? = null
    private var wakeLock: PowerManager.WakeLock? = null

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

    private val prefs by lazy { getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE) }

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
                startForegroundTracking()
            }
            ACTION_STOP -> {
                isSessionActive = false
                stopReconnectLoop()
                stopTracking()
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
            null -> {
                // Android may restart a START_STICKY service with a null intent
                // after a process kill. A foreground service MUST call
                // startForeground promptly or the system throws
                // ForegroundServiceDidNotStartInTimeException.
                if (isTrackingEnabledPref()) {
                    isSessionActive = true
                    startForegroundTracking()
                } else {
                    stopSelf()
                }
            }
        }
        return START_STICKY
    }

    private fun isTrackingEnabledPref(): Boolean =
        prefs.getBoolean(KEY_TRACKING_ENABLED, false)

    // Decision 2 (P1): Reconnect Loop. Callback from BluetoothPlugin.
    override fun onConnectionStateChange(isConnected: Boolean, macAddress: String?) {
        if (!macAddress.isNullOrEmpty()) {
            targetMacAddress = macAddress
        }
        if (isConnected) {
            NativeLogStore.info("BLE connected. Resetting reconnect counter.", "TRACKING_SVC")
            consecutiveFailures = 0
            stopReconnectLoop()
            updateTrackingNotification(notificationText())
        } else {
            consecutiveFailures++
            NativeLogStore.warn(
                "BLE disconnected (consecutiveFailures=$consecutiveFailures). Triggering reconnect loop.",
                "TRACKING_SVC"
            )
            scheduleReconnect()
        }
    }

    // Decision 2 (P1): Reconnect Loop. Handle manual mode toggle with counter reset policy.
    private fun applyManualMode(enabled: Boolean) {
        isManualMode = enabled
        if (enabled) {
            NativeLogStore.info(
                "Manual mode enabled. Halting reconnect loop and resetting counter.",
                "TRACKING_SVC"
            )
            stopReconnectLoop()
            consecutiveFailures = 0
        }
    }

    // Decision 2 (P1): Reconnect Loop. Schedule next reconnection attempt.
    private fun scheduleReconnect() {
        val mac = targetMacAddress
            ?: BluetoothPlugin.instance?.lastMacAddress
            ?: getSharedPreferences("eld_config", Context.MODE_PRIVATE)
                .getString("last_mac_address", null)

        // Explicit stop condition check before scheduling
        if (!BleReconnectPolicy.canAttemptReconnect(isSessionActive, isManualMode, mac)) {
            NativeLogStore.info(
                "Reconnect suppressed (isSessionActive=$isSessionActive, " +
                    "isManualMode=$isManualMode, mac=$mac)",
                "TRACKING_SVC"
            )
            return
        }

        val delaySeconds = BleReconnectPolicy.getBackoffDelaySeconds(consecutiveFailures - 1)
        val delayMs = delaySeconds * 1000L

        val handler = getOrCreateReconnectHandler()
        stopReconnectLoop()

        reconnectRunnable = Runnable {
            if (!BleReconnectPolicy.canAttemptReconnect(isSessionActive, isManualMode, mac)) {
                NativeLogStore.info("Reconnect attempt cancelled by stop conditions.", "TRACKING_SVC")
                stopReconnectLoop()
                return@Runnable
            }

            NativeLogStore.warn(
                "Reconnect executing attempt #$consecutiveFailures to $mac with delay ${delaySeconds}s",
                "TRACKING_SVC"
            )

            if (BleReconnectPolicy.shouldTriggerAlert(consecutiveFailures)) {
                notifyReconnectAlert(consecutiveFailures, mac!!)
            }

            val plugin = BluetoothPlugin.instance
            val initiated = plugin?.executeConnect(mac!!) ?: false
            if (!initiated) {
                consecutiveFailures++
                scheduleReconnect()
            }
        }

        handler.postDelayed(reconnectRunnable!!, delayMs)
    }

    private fun notifyReconnectAlert(attempt: Int, mac: String) {
        NativeLogStore.warn("Reconnect alert triggered for attempt #$attempt", "TRACKING_SVC")
        updateTrackingNotification("ELD disconnected. Reconnect attempt #$attempt...")
        BluetoothPlugin.instance?.emitReconnectAlert(attempt)
    }

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
            NativeLogStore.error("Failed to update notification: ${e.message}", "TRACKING_SVC")
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
        BluetoothPlugin.instance?.removeConnectionStateListener(this)
        stopReconnectLoop()
        reconnectThread?.quitSafely()
        reconnectThread = null
        reconnectHandler = null
        releaseWakeLock()
    }

    private fun startForegroundTracking() {
        if (isTracking) return

        startForeground(NOTIFICATION_ID, buildNotification())
        startLocationTracking()
    }

    @SuppressLint("MissingPermission")
    private fun startLocationTracking() {
        val interval = prefs.getLong("interval", DEFAULT_INTERVAL)
        val distance = prefs.getFloat("distance", DEFAULT_DISTANCE)
        val accuracy = prefs.getString("accuracy", "medium")
        val angle = prefs.getInt("angle", 0)
        val heartbeat = prefs.getLong("heartbeat", 0L)
        val stopDetection = prefs.getBoolean("stop_detection", true)

        locationFilter = TrackingLocationFilter(
            minDistanceMeters = distance,
            minAngleDegrees = angle,
            heartbeatSeconds = heartbeat,
            accuracyThresholdMeters = TrackingLocationFilter.accuracyThresholdMeters(accuracy),
            stopDetection = stopDetection
        )

        if (prefs.getBoolean("wakelock", false)) {
            acquireWakeLock()
        }

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
            NativeLogStore.info(
                "Native location tracking started (interval=${interval}ms, distance=${distance}m, " +
                    "accuracy=$accuracy, angle=$angle, heartbeat=${heartbeat}s)",
                "TRACKING_SVC"
            )

            // بذر فوري بآخر قفل حديث: قراءة فقط، بلا تخزين أو رفع. يمنع
            // بقاء الواجهة فارغة حتى أول دورة تحديث (5 دقائق/75 متراً).
            seedLastKnownLocation()

            // Flush anything queued while the app was dead/offline.
            networkUploader.triggerUpload(
                prefs.getString("serverUrl", "") ?: "",
                prefs.getString("deviceId", "") ?: ""
            )
        } catch (e: SecurityException) {
            NativeLogStore.error("Missing location permissions: ${e.message}", "TRACKING_SVC")
        } catch (e: Exception) {
            NativeLogStore.error("Failed to start location tracking: ${e.message}", "TRACKING_SVC")
        }
    }

    private fun stopTracking() {
        try {
            locationManager?.removeUpdates(this)
        } catch (e: Exception) {
            NativeLogStore.error("Failed to remove updates: ${e.message}", "TRACKING_SVC")
        }
        isTracking = false
        releaseWakeLock()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "GoldenFeatherEld::TrackingWakeLock"
            ).apply {
                setReferenceCounted(false)
                acquire()
            }
            NativeLogStore.info("Wake lock acquired", "TRACKING_SVC")
        } catch (e: Exception) {
            NativeLogStore.error("Failed to acquire wake lock: ${e.message}", "TRACKING_SVC")
        }
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.let { if (it.isHeld) it.release() }
        } catch (_: Exception) {
        }
        wakeLock = null
    }

    private fun notificationText(): String =
        prefs.getString("notification_text", null)?.takeIf { it.isNotBlank() }
            ?: "Tracking in progress..."

    private fun buildNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Golden Feather ELD")
            .setContentText(notificationText())
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
        // In `bleDevice` mode phone GPS must not feed the queue or the live UI:
        // the ELD owns the position stream and `pushLocation` emits its fixes.
        if (currentSourceMode() == "bleDevice") {
            return
        }

        // Live UI always gets the fix, even when the upload filter rejects it.
        broadcastLocation(location, System.currentTimeMillis(), "phone")

        val filter = locationFilter
        if (filter != null && !filter.shouldAccept(location)) {
            return
        }

        // 1. Save to SQLite (queue offline-safe)
        dbHelper.insertLocation(location, source = "phone")

        // 2. Trigger upload (retry/backoff is owned by NetworkUploader)
        networkUploader.triggerUpload(
            prefs.getString("serverUrl", "") ?: "",
            prefs.getString("deviceId", "") ?: ""
        )
    }

    private fun currentSourceMode(): String =
        prefs.getString("source_mode", "hybrid") ?: "hybrid"

    /**
     * يبثّ آخر قفل حديث إلى Flutter دون حفظه أو رفعه. النافذة قصيرة في
     * [LastKnownLocationSource] حتى لا يُعرض موقع قديم كأنه الحالي.
     */
    private fun seedLastKnownLocation() {
        if (currentSourceMode() == "bleDevice") return
        val seeded = LastKnownLocationSource.latest(this) ?: return
        NativeLogStore.info("Seeded last known location.", "TRACKING_SVC")
        broadcastLocation(seeded, seeded.time, "phone")
    }

    private fun broadcastLocation(location: Location, timestampMillis: Long, source: String) {
        val intent = Intent(ACTION_LOCATION_UPDATE).apply {
            setPackage(packageName)
            putExtra("latitude", location.latitude)
            putExtra("longitude", location.longitude)
            putExtra("speed", location.speed.toDouble())
            putExtra("bearing", location.bearing.toDouble())
            putExtra("altitude", location.altitude)
            putExtra("accuracy", location.accuracy.toDouble())
            putExtra("timestamp", timestampMillis)
            putExtra("source", source)
        }
        sendBroadcast(intent)
    }
}
