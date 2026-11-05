package com.goldenfeather.golden_feather_eld.bluetooth

/**
 * Decision 2 (P1): Reconnect Loop Policy.
 * Pure business logic extracted for deterministic JVM unit testing.
 */
object BleReconnectPolicy {

    /**
     * Exponential backoff delays in seconds:
     * Attempt 0 (1st failure): 2s
     * Attempt 1 (2nd failure): 4s
     * Attempt 2 (3rd failure): 8s
     * Attempt 3 (4th failure): 16s
     * Attempt 4+ (5th failure and onwards): 30s (ceiling)
     */
    fun getBackoffDelaySeconds(failuresBeforeAttempt: Int): Long {
        return when (failuresBeforeAttempt) {
            0 -> 2L
            1 -> 4L
            2 -> 8L
            3 -> 16L
            else -> 30L
        }
    }

    /**
     * Alert threshold: every 5 consecutive failures (5, 10, 15, 20...).
     */
    fun shouldTriggerAlert(consecutiveFailures: Int): Boolean {
        return consecutiveFailures > 0 && (consecutiveFailures % 5 == 0)
    }

    /**
     * Evaluates if a reconnection attempt can be scheduled or executed.
     * All conditions must be satisfied:
     * - Session is active (driver logged in, tracking active)
     * - Not in manual mode (manual mode pauses/cancels reconnect)
     * - Target MAC address is known and not empty
     */
    fun canAttemptReconnect(
        isSessionActive: Boolean,
        isManualMode: Boolean,
        macAddress: String?
    ): Boolean {
        return isSessionActive && !isManualMode && !macAddress.isNullOrEmpty()
    }
}

