package com.goldenfeather.golden_feather_eld.plugins

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.ParcelUuid
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.UUID
import java.util.concurrent.CopyOnWriteArraySet
import com.goldenfeather.golden_feather_eld.services.TrackingForegroundService

// Decision 2 (P1): Reconnect Loop.
// Listener interface allowing background services (like TrackingForegroundService)
// to observe BLE connection state transitions directly without Flutter method channel overhead.
interface BleConnectionStateListener {
    fun onConnectionStateChange(isConnected: Boolean, macAddress: String?)
}

/**
 * BluetoothPlugin - اتصال BLE مع جهاز ELD
 * Decision 2 (P1): Reconnect Loop - Executor layer without timers.
 *
 * Singleton lifecycle rule:
 * - Uses applicationContext ONLY; never holds or leaks Activity references.
 * - Created in MainActivity.configureFlutterEngine with applicationContext.
 */
class BluetoothPlugin(
    private var context: Context? = null
) : FlutterPlugin, MethodCallHandler {

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    private var bluetoothManager: BluetoothManager? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var scanner: BluetoothLeScanner? = null
    private var connectedGatt: BluetoothGatt? = null
    private var eventSink: EventChannel.EventSink? = null

    // Decision 2 (P1): Reconnect Loop. Registered listeners (e.g. TrackingForegroundService).
    private val connectionListeners = CopyOnWriteArraySet<BleConnectionStateListener>()

    // Sub-decision (pending owner approval): Persistent storage of last MAC address across process restarts.
    @Volatile
    var lastMacAddress: String? = null

    @Volatile
    var isSessionActive: Boolean = false

    @Volatile
    var isManualMode: Boolean = false

    @Volatile
    var alertEmitCount: Int = 0
        internal set

    @Volatile
    var lastEmittedAlertAttempt: Int = 0
        internal set

    init {
        // Singleton — use applicationContext only, no activity reference.
        instance = this
        // Hydrate last known MAC if available
        lastMacAddress = try {
            context?.getSharedPreferences("eld_config", Context.MODE_PRIVATE)
                ?.getString("last_mac_address", null)
        } catch (_: Exception) {
            null
        }
    }

    companion object {
        const val METHOD_CHANNEL = "com.goldenfeather.eld/bluetooth"
        const val EVENT_CHANNEL = "com.goldenfeather.eld/bluetooth/events"

        // UUIDs قياسية لـ ELD Adapters (OBD-II BLE)
        val ELD_SERVICE_UUID: UUID = UUID.fromString("0000ffe0-0000-1000-8000-00805f9b34fb")
        val ELD_CHARACTERISTIC_UUID: UUID = UUID.fromString("0000ffe1-0000-1000-8000-00805f9b34fb")

        // Decision 2 (P1): Reconnect Loop. Singleton reference for native service access.
        // Singleton — use applicationContext only, no activity reference.
        @Volatile
        var instance: BluetoothPlugin? = null
            private set

        fun destroy() {
            instance?.let { plugin ->
                plugin.connectionListeners.clear()
                plugin.setEventSink(null)
                plugin.alertEmitCount = 0
                plugin.lastEmittedAlertAttempt = 0
            }
            instance = null
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL).apply {
            setMethodCallHandler(this@BluetoothPlugin)
        }
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL).apply {
            setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    setEventSink(events)
                }
                override fun onCancel(arguments: Any?) {
                    setEventSink(null)
                }
            })
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        destroy()
        setEventSink(null)
        connectionListeners.clear()
        context = null
    }

    // Decision 2 (P1): Reconnect Loop. Register listener.
    fun addConnectionStateListener(listener: BleConnectionStateListener) {
        connectionListeners.add(listener)
    }

    // Decision 2 (P1): Reconnect Loop. Unregister listener.
    fun removeConnectionStateListener(listener: BleConnectionStateListener) {
        connectionListeners.remove(listener)
    }

    fun hasConnectionStateListener(listener: BleConnectionStateListener): Boolean {
        return connectionListeners.contains(listener)
    }

    // Decision 2 (P1): Reconnect Loop. Emit reconnect alert event to Flutter EventChannel.
    fun emitReconnectAlert(attemptNumber: Int) {
        lastEmittedAlertAttempt = attemptNumber
        alertEmitCount++
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(mapOf(
                "type" to "ble_reconnect_retry_event",
                "attemptNumber" to attemptNumber
            ))
        }
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "startScan" -> startScan(result)
                "stopScan" -> stopScan(result)
                "connect" -> connectDevice(call, result)
                // Decision 2 (P1): Reconnect Loop. Pure executor without timers.
                "executeConnect" -> executeConnectChannel(call, result)
                // Decision 2 (P1): Reconnect Loop. Synchronize session state from Flutter.
                "setSessionState" -> setSessionStateChannel(call, result)
                "disconnect" -> disconnectDevice(result)
                "isConnected" -> result.success(connectedGatt != null)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("BLUETOOTH_ERROR", e.message, null)
        }
    }

    // Decision 2 (P1): Reconnect Loop. Synchronize session & manual mode state from Flutter.
    private fun setSessionStateChannel(call: MethodCall, result: Result) {
        val active = call.argument<Boolean>("isActive") ?: false
        val manual = call.argument<Boolean>("isManualMode") ?: false
        val clearMac = call.argument<Boolean>("clearMac") ?: false

        isSessionActive = active
        isManualMode = manual

        if (clearMac) {
            lastMacAddress = null
            try {
                context?.getSharedPreferences("eld_config", Context.MODE_PRIVATE)
                    ?.edit()
                    ?.remove("last_mac_address")
                    ?.apply()
            } catch (_: Exception) {}
        }

        // Forward state update to TrackingForegroundService
        val ctx = context
        if (ctx != null) {
            try {
                val intent = Intent(ctx, TrackingForegroundService::class.java).apply {
                this.action = TrackingForegroundService.ACTION_SET_SESSION_STATE
                putExtra("sessionActive", active)
                putExtra("manualMode", manual)
                putExtra("clearMac", clearMac)
            }
                ctx.startService(intent)
            } catch (_: Exception) {}
        }

        result.success(true)
    }

    @SuppressLint("MissingPermission")
    private fun startScan(result: Result) {
        val hasPermission = checkBluetoothPermission()
        if (!hasPermission) {
            result.error("PERMISSION_DENIED", "Bluetooth permission not granted", null)
            return
        }

        val ctx = context ?: run {
            result.error("NO_CONTEXT", "Context is null", null)
            return
        }
        bluetoothManager = ctx.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter

        if (bluetoothAdapter == null || !bluetoothAdapter!!.isEnabled) {
            result.error("BT_DISABLED", "Bluetooth is disabled", null)
            return
        }

        scanner = bluetoothAdapter?.bluetoothLeScanner
        val scanSettings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        val scanFilters = listOf(
            ScanFilter.Builder()
                .setServiceUuid(ParcelUuid(ELD_SERVICE_UUID))
                .build()
        )

        scanner?.startScan(scanFilters, scanSettings, scanCallback)
        result.success(true)
    }

    @SuppressLint("MissingPermission")
    private fun stopScan(result: Result) {
        scanner?.stopScan(scanCallback)
        scanner = null
        result.success(true)
    }

    @SuppressLint("MissingPermission")
    private fun connectDevice(call: MethodCall, result: Result) {
        val macAddress = call.argument<String>("macAddress") ?: run {
            result.error("NO_MAC", "MAC address required", null)
            return
        }
        val ok = executeConnect(macAddress)
        if (ok) {
            result.success(true)
        } else {
            result.error("CONNECT_FAILED", "Failed to initiate connection to $macAddress", null)
        }
    }

    // Decision 2 (P1): Reconnect Loop. MethodChannel endpoint for executeConnect.
    private fun executeConnectChannel(call: MethodCall, result: Result) {
        val macAddress = call.argument<String>("macAddress") ?: run {
            result.error("NO_MAC", "MAC address required", null)
            return
        }
        val ok = executeConnect(macAddress)
        result.success(ok)
    }

    /**
     * Decision 2 (P1): Reconnect Loop.
     * Pure connection executor. Devoid of any retry loop or timer logic.
     * Initiates GATT connection and returns true if initiated successfully.
     */
    @SuppressLint("MissingPermission")
    fun executeConnect(macAddress: String): Boolean {
        if (!checkBluetoothPermission()) {
            return false
        }

        val ctx = context ?: return false
        bluetoothManager = ctx.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter

        if (bluetoothAdapter == null || !bluetoothAdapter!!.isEnabled) {
            return false
        }

        lastMacAddress = macAddress
        try {
            ctx.getSharedPreferences("eld_config", Context.MODE_PRIVATE)
                .edit()
                .putString("last_mac_address", macAddress)
                .apply()
        } catch (_: Exception) {}

        val device = try {
            bluetoothAdapter?.getRemoteDevice(macAddress)
        } catch (e: Exception) {
            null
        } ?: return false

        try {
            connectedGatt?.close()
        } catch (_: Exception) {}

        connectedGatt = device.connectGatt(ctx, false, gattCallback)
        return connectedGatt != null
    }

    @SuppressLint("MissingPermission")
    private fun disconnectDevice(result: Result) {
        connectedGatt?.disconnect()
        connectedGatt?.close()
        connectedGatt = null
        result.success(true)
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device
            val data = mapOf(
                "name" to (device.name ?: "Unknown"),
                "macAddress" to device.address,
                "rssi" to result.rssi
            )
            eventSink?.success(mapOf("type" to "deviceFound", "data" to data))
        }

        override fun onScanFailed(errorCode: Int) {
            eventSink?.success(mapOf("type" to "scanFailed", "error" to errorCode))
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            val address = gatt.device?.address
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    Handler(Looper.getMainLooper()).post {
                        eventSink?.success(mapOf("type" to "connected", "macAddress" to (address ?: "")))
                    }
                    // Decision 2 (P1): Reconnect Loop. Notify native listeners.
                    for (listener in connectionListeners) {
                        listener.onConnectionStateChange(true, address)
                    }
                    gatt.discoverServices()
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    Handler(Looper.getMainLooper()).post {
                        eventSink?.success(mapOf("type" to "disconnected", "macAddress" to (address ?: "")))
                    }
                    // Decision 2 (P1): Reconnect Loop. Notify native listeners (e.g. TrackingForegroundService).
                    for (listener in connectionListeners) {
                        listener.onConnectionStateChange(false, address)
                    }
                    try {
                        connectedGatt?.close()
                    } catch (_: Exception) {}
                    connectedGatt = null
                }
            }
        }

        @SuppressLint("MissingPermission")
        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                val service = gatt.getService(ELD_SERVICE_UUID)
                val characteristic = service?.getCharacteristic(ELD_CHARACTERISTIC_UUID)

                if (characteristic != null) {
                    gatt.setCharacteristicNotification(characteristic, true)
                    val descriptor = characteristic.getDescriptor(
                        UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
                    )
                    descriptor?.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                    gatt.writeDescriptor(descriptor)
                }
            }
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic
        ) {
            val value = characteristic.value
            Handler(Looper.getMainLooper()).post {
                eventSink?.success(mapOf(
                    "type" to "data",
                    "data" to (value?.joinToString(",") ?: "")
                ))
            }
        }
    }

    private fun checkBluetoothPermission(): Boolean {
        val ctx = context ?: return true
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ctx.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) ==
                    PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }
}
