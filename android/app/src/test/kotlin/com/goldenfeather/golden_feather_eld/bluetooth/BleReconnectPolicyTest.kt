package com.goldenfeather.golden_feather_eld.bluetooth

import org.junit.Assert.*
import org.junit.Test

/**
 * JVM Unit Tests for Decision 2 (P1): Reconnect Loop Policy.
 */
class BleReconnectPolicyTest {

    @Test
    fun testExponentialBackoffWithCeiling() {
        assertEquals(2L, BleReconnectPolicy.getBackoffDelaySeconds(0))
        assertEquals(4L, BleReconnectPolicy.getBackoffDelaySeconds(1))
        assertEquals(8L, BleReconnectPolicy.getBackoffDelaySeconds(2))
        assertEquals(16L, BleReconnectPolicy.getBackoffDelaySeconds(3))
        assertEquals(30L, BleReconnectPolicy.getBackoffDelaySeconds(4))
        assertEquals(30L, BleReconnectPolicy.getBackoffDelaySeconds(5))
        assertEquals(30L, BleReconnectPolicy.getBackoffDelaySeconds(10))
        assertEquals(30L, BleReconnectPolicy.getBackoffDelaySeconds(30))
    }

    @Test
    fun testAlertThresholdEveryFiveAttempts() {
        assertFalse(BleReconnectPolicy.shouldTriggerAlert(0))
        assertFalse(BleReconnectPolicy.shouldTriggerAlert(1))
        assertFalse(BleReconnectPolicy.shouldTriggerAlert(4))
        assertTrue(BleReconnectPolicy.shouldTriggerAlert(5))
        assertFalse(BleReconnectPolicy.shouldTriggerAlert(6))
        assertFalse(BleReconnectPolicy.shouldTriggerAlert(9))
        assertTrue(BleReconnectPolicy.shouldTriggerAlert(10))
        assertTrue(BleReconnectPolicy.shouldTriggerAlert(15))
        assertTrue(BleReconnectPolicy.shouldTriggerAlert(20))
    }

    @Test
    fun testCanAttemptReconnectConditions() {
        // Normal active state
        assertTrue(BleReconnectPolicy.canAttemptReconnect(
            isSessionActive = true,
            isManualMode = false,
            macAddress = "AA:BB:CC:DD:EE:FF"
        ))

        // Suppressed when manualMode = true
        assertFalse(BleReconnectPolicy.canAttemptReconnect(
            isSessionActive = true,
            isManualMode = true,
            macAddress = "AA:BB:CC:DD:EE:FF"
        ))

        // Suppressed when session is inactive (logout)
        assertFalse(BleReconnectPolicy.canAttemptReconnect(
            isSessionActive = false,
            isManualMode = false,
            macAddress = "AA:BB:CC:DD:EE:FF"
        ))

        // Suppressed when MAC address is null or empty
        assertFalse(BleReconnectPolicy.canAttemptReconnect(
            isSessionActive = true,
            isManualMode = false,
            macAddress = null
        ))
        assertFalse(BleReconnectPolicy.canAttemptReconnect(
            isSessionActive = true,
            isManualMode = false,
            macAddress = ""
        ))
    }
}

