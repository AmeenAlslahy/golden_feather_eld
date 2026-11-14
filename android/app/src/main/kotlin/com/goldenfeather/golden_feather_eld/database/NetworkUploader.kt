package com.goldenfeather.golden_feather_eld.database

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import com.goldenfeather.golden_feather_eld.logging.NativeLogStore
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * OsmAnd-protocol uploader with a Traccar-style retry strategy.
 *
 * Fixes vs. the previous implementation:
 *  - speed is converted from m/s to knots (OsmAnd/Traccar expect knots)
 *  - any 2xx response counts as success, not only 200
 *  - `alarm` is forwarded to the server (SOS/panic button)
 *  - exponential backoff 5s -> 5min instead of hammering a dead server on
 *    every GPS fix, plus an explicit connectivity check
 *  - battery level / charging flag are sent so the server can show device health
 */
class NetworkUploader(private val context: Context) {

    private val dbHelper = LocationDatabaseHelper(context)

    companion object {
        private const val TAG = "TRACCAR_PLUGIN"
        private const val BASE_BACKOFF_SECONDS = 5L
        private const val MAX_BACKOFF_SECONDS = 300L
        private const val MPS_TO_KNOTS = 1.9438444924406

        // Shared across the service and the Flutter plugin (both create their own
        // NetworkUploader); without this, two instances could upload the same row
        // twice and double-count positions on the server.
        private val executor = Executors.newSingleThreadScheduledExecutor { runnable ->
            Thread(runnable, "TraccarUploader").apply { isDaemon = true }
        }
        private val lock = Any()

        @Volatile
        private var uploadScheduled = false

        @Volatile
        private var consecutiveFailures = 0

        fun resetBackoff() {
            consecutiveFailures = 0
        }

        fun currentBackoffSeconds(): Long = backoffSeconds(consecutiveFailures)

        internal fun backoffSeconds(failures: Int): Long {
            if (failures <= 0) return 0L
            var delay = BASE_BACKOFF_SECONDS
            repeat((failures - 1).coerceAtMost(10)) {
                delay *= 2
            }
            return delay.coerceAtMost(MAX_BACKOFF_SECONDS)
        }
    }

    fun triggerUpload(serverUrl: String, deviceId: String) {
        if (serverUrl.isBlank() || deviceId.isBlank()) return
        schedule(delaySeconds = 0L, serverUrl = serverUrl, deviceId = deviceId)
    }

    private fun schedule(delaySeconds: Long, serverUrl: String, deviceId: String) {
        synchronized(lock) {
            if (uploadScheduled) return
            uploadScheduled = true
        }
        executor.schedule(
            {
                var retryDelay = 0L
                try {
                    retryDelay = runUpload(serverUrl, deviceId)
                } catch (e: Exception) {
                    NativeLogStore.error("Upload loop crashed: ${e.message}")
                    retryDelay = backoffSeconds(consecutiveFailures + 1)
                } finally {
                    synchronized(lock) { uploadScheduled = false }
                }
                if (retryDelay > 0) {
                    schedule(retryDelay, serverUrl, deviceId)
                }
            },
            delaySeconds,
            TimeUnit.SECONDS
        )
    }

    /** @return delay in seconds before the next attempt, or 0 when the queue is empty. */
    private fun runUpload(serverUrl: String, deviceId: String): Long {
        if (!isNetworkAvailable()) {
            NativeLogStore.warn(
                "No network. ${dbHelper.pendingCount()} fix(es) kept in the offline queue."
            )
            return backoffSeconds(consecutiveFailures + 1)
        }

        var pending = dbHelper.getPendingLocations()
        while (pending.isNotEmpty()) {
            for (loc in pending) {
                val success = uploadSingleLocation(serverUrl, deviceId, loc)
                if (success) {
                    dbHelper.deleteLocation(loc.id)
                    consecutiveFailures = 0
                } else {
                    consecutiveFailures++
                    val delay = backoffSeconds(consecutiveFailures)
                    NativeLogStore.warn(
                        "Upload failed (attempt $consecutiveFailures). Retrying in " +
                            "${delay}s. Queue: ${dbHelper.pendingCount()}"
                    )
                    return delay
                }
            }
            pending = dbHelper.getPendingLocations()
        }
        return 0L
    }

    private fun uploadSingleLocation(serverUrl: String, deviceId: String, loc: LocationModel): Boolean {
        return try {
            val baseUrl = if (serverUrl.endsWith("/")) serverUrl.dropLast(1) else serverUrl
            val encodedId = URLEncoder.encode(deviceId, "UTF-8")
            val speedKnots = loc.speed * MPS_TO_KNOTS
            val builder = StringBuilder(baseUrl)
                .append("/?id=").append(encodedId)
                .append("&lat=").append(loc.latitude)
                .append("&lon=").append(loc.longitude)
                .append("&timestamp=").append(loc.timestamp)
                .append("&speed=").append(String.format(java.util.Locale.US, "%.2f", speedKnots))
                .append("&bearing=").append(loc.bearing)
                .append("&altitude=").append(loc.altitude)
                .append("&accuracy=").append(loc.accuracy)

            if (!loc.alarm.isNullOrBlank()) {
                builder.append("&alarm=").append(URLEncoder.encode(loc.alarm, "UTF-8"))
            }

            batteryFields()?.let { builder.append(it) }

            val connection = URL(builder.toString()).openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            connection.instanceFollowRedirects = true
            connection.setRequestProperty("User-Agent", "GoldenFeather-ELD/1.0")

            val responseCode = connection.responseCode
            connection.disconnect()

            val success = responseCode in 200..299
            if (success) {
                NativeLogStore.info("Uploaded location ${loc.id} (source=${loc.source ?: "phone"})")
            } else {
                NativeLogStore.warn("Upload rejected for location ${loc.id}: HTTP $responseCode")
            }
            success
        } catch (e: Exception) {
            NativeLogStore.warn("Failed to upload location ${loc.id}: ${e.message}")
            false
        }
    }

    private fun batteryFields(): String? {
        return try {
            val manager = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager ?: return null
            val level = manager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            if (level !in 0..100) return null
            val charging = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                manager.isCharging
            } else {
                false
            }
            "&batt=$level&charge=$charging"
        } catch (_: Exception) {
            null
        }
    }

    fun isNetworkAvailable(): Boolean {
        return try {
            val manager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = manager.activeNetwork ?: return false
            val capabilities = manager.getNetworkCapabilities(network) ?: return false
            capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        } catch (_: Exception) {
            true
        }
    }
}
