package com.goldenfeather.golden_feather_eld.location

import android.location.Location
import android.os.SystemClock
import kotlin.math.abs

/**
 * Traccar-style location filter.
 *
 * `LocationManager.requestLocationUpdates(interval, distance)` already applies
 * the interval/distance part on Android. This filter adds the pieces the app
 * advertised in its settings but never honoured:
 *
 *  - accuracy threshold derived from `accuracy` config
 *  - angle filter (`angle` config)
 *  - heartbeat: always accept one fix per `heartbeat` seconds
 *  - stop detection: ignore tiny movements while stationary
 */
class TrackingLocationFilter(
    private val minDistanceMeters: Float,
    private val minAngleDegrees: Int,
    private val heartbeatSeconds: Long,
    private val accuracyThresholdMeters: Float,
    private val stopDetection: Boolean
) {

    private var lastAccepted: Location? = null
    private var lastAcceptedAtMs: Long = 0L

    fun shouldAccept(location: Location, nowMs: Long = SystemClock.elapsedRealtime()): Boolean {
        // Reject wildly inaccurate fixes: they poison both the queue and the map.
        if (accuracyThresholdMeters > 0f && location.accuracy > accuracyThresholdMeters) {
            return false
        }

        val previous = lastAccepted
        if (previous == null) {
            markAccepted(location, nowMs)
            return true
        }

        // Heartbeat: never let the server believe the device went silent.
        if (heartbeatSeconds > 0 && nowMs - lastAcceptedAtMs >= heartbeatSeconds * 1000L) {
            markAccepted(location, nowMs)
            return true
        }

        val distance = previous.distanceTo(location)

        if (distance >= minDistanceMeters) {
            if (minAngleDegrees <= 0) {
                markAccepted(location, nowMs)
                return true
            }
            val angleDelta = angleDifference(previous.bearing, location.bearing)
            if (angleDelta >= minAngleDegrees || distance >= minDistanceMeters * 3f) {
                markAccepted(location, nowMs)
                return true
            }
            return false
        }

        // Stop detection: a stationary vehicle should not flood the server even
        // when the GPS reports noise above the distance filter.
        if (stopDetection && distance < minDistanceMeters && speedMps(location) < 0.5) {
            return false
        }

        return false
    }

    private fun markAccepted(location: Location, nowMs: Long) {
        lastAccepted = Location(location)
        lastAcceptedAtMs = nowMs
    }

    private fun speedMps(location: Location): Float {
        return if (location.hasSpeed()) location.speed else 0f
    }

    private fun angleDifference(a: Float, b: Float): Int {
        var diff = abs(a - b) % 360f
        if (diff > 180f) diff = 360f - diff
        return diff.toInt()
    }

    companion object {
        /** Maps the persisted `accuracy` setting to a maximum accepted radius. */
        fun accuracyThresholdMeters(accuracy: String?): Float = when (accuracy?.lowercase()) {
            "highest" -> 20f
            "high" -> 50f
            "low" -> 500f
            else -> 150f
        }
    }
}
