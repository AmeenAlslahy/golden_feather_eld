package com.goldenfeather.golden_feather_eld.services

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.goldenfeather.golden_feather_eld.bluetooth.BleReconnectPolicy
import com.goldenfeather.golden_feather_eld.plugins.BluetoothPlugin
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.android.controller.ServiceController
import org.robolectric.annotation.Config

/**
 * Robolectric Unit Tests for Decision 2 (P1): TrackingForegroundService Reconnect Loop.
 * Runs on JVM without requiring an attached physical Android device.
 */
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
class TrackingForegroundServiceTest {

    private lateinit var context: Context
    private lateinit var bluetoothPlugin: BluetoothPlugin
    private lateinit var serviceController: ServiceController<TrackingForegroundService>
    private lateinit var service: TrackingForegroundService

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        BluetoothPlugin.destroy()
        bluetoothPlugin = BluetoothPlugin(context)

        serviceController = Robolectric.buildService(TrackingForegroundService::class.java)
        service = serviceController.get()
    }

    @After
    fun tearDown() {
        service.stopReconnectLoop()
        serviceController.destroy()
        BluetoothPlugin.destroy()
    }

    // -------------------------------------------------------------------------
    // Test 1: onCreate -> listener registered on BluetoothPlugin;
    //         onDestroy -> Handler nullified, listener removed, no memory leak.
    // -------------------------------------------------------------------------
    @Test
    fun testOnCreateRegistersListenerAndOnDestroyCleansUp() {
        // 1. onCreate -> listener registered
        serviceController.create()
        assertTrue(
            "TrackingForegroundService should register itself as a listener on BluetoothPlugin in onCreate()",
            bluetoothPlugin.hasConnectionStateListener(service)
        )

        // 2. onDestroy -> listener removed, thread safely stopped
        serviceController.destroy()
        assertFalse(
            "TrackingForegroundService should unregister itself from BluetoothPlugin in onDestroy()",
            bluetoothPlugin.hasConnectionStateListener(service)
        )
    }

    // -------------------------------------------------------------------------
    // Test 2: Simulate 5 onConnectionStateChange(false) -> verify exponential backoff sequence (2s, 4s, 8s, 16s, 30s)
    // -------------------------------------------------------------------------
    @Test
    fun testSimulateFiveDisconnectsVerifyBackoffSequence() {
        serviceController.create()
        service.isSessionActive = true
        service.isManualMode = false
        val targetMac = "11:22:33:44:55:66"

        val expectedDelays = listOf(2L, 4L, 8L, 16L, 30L)

        for (i in 0 until 5) {
            service.onConnectionStateChange(false, targetMac)
            val currentFailures = service.consecutiveFailures
            assertEquals(i + 1, currentFailures)

            val expectedDelay = expectedDelays[i]
            val calculatedDelay = BleReconnectPolicy.getBackoffDelaySeconds(currentFailures - 1)
            assertEquals(expectedDelay, calculatedDelay)
        }
    }

    // -------------------------------------------------------------------------
    // Test 3: verify emitReconnectAlert(5) is called exactly once at attempt #5
    // -------------------------------------------------------------------------
    @Test
    fun testEmitReconnectAlertCalledAtAttemptFiveOnlyOnce() {
        serviceController.create()
        service.isSessionActive = true
        service.isManualMode = false
        val targetMac = "11:22:33:44:55:66"

        // Initial disconnect sets failure #1
        service.onConnectionStateChange(false, targetMac)
        assertEquals(1, service.consecutiveFailures)
        assertEquals(0, bluetoothPlugin.alertEmitCount)

        // Retries 1, 2, 3, 4 should NOT emit any alert
        for (i in 1..4) {
            service.reconnectRunnable?.run()
        }
        assertEquals(5, service.consecutiveFailures)
        assertEquals(0, bluetoothPlugin.alertEmitCount)

        // Retry 5 must trigger alert exactly once
        service.reconnectRunnable?.run()
        assertEquals(6, service.consecutiveFailures)
        assertEquals(1, bluetoothPlugin.alertEmitCount)
        assertEquals(5, bluetoothPlugin.lastEmittedAlertAttempt)

        // Retry 6 does NOT re-emit alert
        service.reconnectRunnable?.run()
        assertEquals(7, service.consecutiveFailures)
        assertEquals(1, bluetoothPlugin.alertEmitCount)
    }

    // -------------------------------------------------------------------------
    // Test 4: verify that after STATE_CONNECTED, no alert is emitted and counter resets to 0
    // -------------------------------------------------------------------------
    @Test
    fun testStateConnectedStopsLoopAndResetsConsecutiveFailures() {
        serviceController.create()
        service.isSessionActive = true
        service.isManualMode = false
        val targetMac = "11:22:33:44:55:66"

        // Simulate 4 failures
        for (i in 1..4) {
            service.onConnectionStateChange(false, targetMac)
        }
        assertEquals(4, service.consecutiveFailures)

        // STATE_CONNECTED arrives
        service.onConnectionStateChange(true, targetMac)
        assertEquals(0, service.consecutiveFailures)
        assertEquals(0, bluetoothPlugin.alertEmitCount)
    }

    // -------------------------------------------------------------------------
    // Test 5: manualMode = true halts reconnect loop and resets counter
    // -------------------------------------------------------------------------
    @Test
    fun testManualModeHaltsReconnectLoop() {
        serviceController.create()
        service.isSessionActive = true
        service.isManualMode = false
        val targetMac = "11:22:33:44:55:66"

        // 3 failures
        for (i in 1..3) {
            service.onConnectionStateChange(false, targetMac)
        }
        assertEquals(3, service.consecutiveFailures)

        // Enable manual mode via Intent
        val intent = android.content.Intent(TrackingForegroundService.ACTION_SET_MANUAL_MODE).apply {
            putExtra("manualMode", true)
        }
        service.onStartCommand(intent, 0, 1)

        assertTrue(service.isManualMode)
        assertEquals(0, service.consecutiveFailures)
        assertFalse(
            BleReconnectPolicy.canAttemptReconnect(
                service.isSessionActive,
                service.isManualMode,
                service.targetMacAddress
            )
        )
    }
}
