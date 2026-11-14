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
import android.os.Looper
import android.os.SystemClock
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.ArrayDeque
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArraySet
import com.goldenfeather.golden_feather_eld.logging.NativeLogStore
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
 * Supports the two families found in the field:
 *  - "transparent UART" adapters (FFE0/FFE1)
 *  - Nordic UART Service (NUS) devices, used by several ELD dongles
 *  - Pacific Track PT30/PT40 modules (advertise PT30/PT40 or E0:B4:88 MACs)
 *
 * Discovery is intentionally **unfiltered**: the old code filtered on FFE0, so
 * devices such as the PT30-U were never seen even though they were advertising.
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

    private var connectedDeviceName: String? = null
    private var negotiatedMtu: Int = 23
    private var scanStartedAt: Long = 0L
    private var servicesDiscovered = false
    private var batteryLevel: Int? = null

    private val notifyCharacteristics = CopyOnWriteArraySet<UUID>()
    private val descriptorsToWrite = ArrayDeque<BluetoothGattDescriptor>()
    private var writeCharacteristic: BluetoothGattCharacteristic? = null

    /** Throttle duplicate advertisements so the Flutter list is not flooded. */
    private val lastScanEmit = ConcurrentHashMap<String, Long>()

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

    private val mainHandler = Handler(Looper.getMainLooper())

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

        // Nordic UART Service (used by several BLE ELD bridges)
        val NUS_SERVICE_UUID: UUID = UUID.fromString("6e400001-b5a3-f393-e0a9-e50e24dcca9e")
        val NUS_RX_UUID: UUID = UUID.fromString("6e400003-b5a3-f393-e0a9-e50e24dcca9e")
        val NUS_TX_UUID: UUID = UUID.fromString("6e400002-b5a3-f393-e0a9-e50e24dcca9e")

        val BATTERY_SERVICE_UUID: UUID = UUID.fromString("0000180f-0000-1000-8000-00805f9b34fb")
        val BATTERY_LEVEL_UUID: UUID = UUID.fromString("00002a19-0000-1000-8000-00805f9b34fb")

        private val CCCD_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

        private const val SCAN_EMIT_INTERVAL_MS = 700L

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
        emit(mapOf(
            "type" to "ble_reconnect_retry_event",
            "attemptNumber" to attemptNumber
        ))
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    /** EventChannel sinks must only be touched on the main thread. */
    private fun emit(event: Map<String, Any?>) {
        val payload = event
        if (Looper.myLooper() == Looper.getMainLooper()) {
            eventSink?.success(payload)
        } else {
            mainHandler.post { eventSink?.success(payload) }
        }
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
                "readDeviceInfo" -> result.success(readDeviceInfo())
                "sendCommand" -> sendCommand(call, result)
                "getLastDevice" -> result.success(lastDeviceMap())
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            NativeLogStore.error("Bluetooth method ${call.method} failed: ${e.message}", "BLE")
            result.error("BLUETOOTH_ERROR", e.message, null)
        }
    }

    // ========== Discovery ==========

    @SuppressLint("MissingPermission")
    private fun startScan(result: Result) {
        if (!checkBluetoothPermissions(requireScan = true)) {
            result.error("PERMISSION_DENIED", "Bluetooth scan permission not granted", null)
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
        if (scanner == null) {
            result.error("BT_UNAVAILABLE", "BLE scanner unavailable", null)
            return
        }

        val scanSettings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .setReportDelay(0L)
            .build()

        lastScanEmit.clear()
        scanStartedAt = SystemClock.elapsedRealtime()
        // No service filter: PT30/PT40 and many ELD bridges do not advertise
        // FFE0, and the previous filter hid them completely.
        scanner?.startScan(null, scanSettings, scanCallback)
        NativeLogStore.info("BLE scan started (unfiltered)", "BLE")
        emit(mapOf("type" to "scanStarted"))
        result.success(true)
    }

    @SuppressLint("MissingPermission")
    private fun stopScan(result: Result) {
        try {
            scanner?.stopScan(scanCallback)
        } catch (_: Exception) {
        }
        scanner = null
        emit(mapOf("type" to "scanStopped"))
        result.success(true)
    }

    private val scanCallback = object : ScanCallback() {
        @SuppressLint("MissingPermission")
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device ?: return
            val address = device.address ?: return

            val now = SystemClock.elapsedRealtime()
            val last = lastScanEmit[address] ?: 0L
            if (now - last < SCAN_EMIT_INTERVAL_MS) return
            lastScanEmit[address] = now

            val name = try {
                result.scanRecord?.deviceName ?: device.name
            } catch (_: SecurityException) {
                null
            } ?: "Unknown"

            val serviceUuids = result.scanRecord?.serviceUuids
                ?.mapNotNull { it?.uuid?.toString() }
                ?: emptyList()

            val data = mutableMapOf<String, Any?>(
                "name" to name,
                "macAddress" to address,
                "rssi" to result.rssi,
                "serviceUuids" to serviceUuids,
                "isConnectable" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    result.isConnectable
                } else {
                    true
                },
                "kind" to classifyDevice(name, address, serviceUuids),
                "bonded" to try {
                    device.bondState == BluetoothDevice.BOND_BONDED
                } catch (_: SecurityException) {
                    false
                }
            )
            data["manufacturerData"] = result.scanRecord?.manufacturerSpecificData
                ?.let { sparse ->
                    (0 until sparse.size()).associate { index ->
                        sparse.keyAt(index) to sparse.valueAt(index)?.joinToString(",") { it.toString() }
                    }
                }

            emit(mapOf("type" to "deviceFound", "data" to data))
        }

        override fun onScanFailed(errorCode: Int) {
            NativeLogStore.error("BLE scan failed: $errorCode", "BLE")
            emit(mapOf("type" to "scanFailed", "error" to errorCode))
        }
    }

    private fun classifyDevice(name: String, address: String, serviceUuids: List<String>): String {
        val upperName = name.uppercase()
        val upperMac = address.uppercase()
        return when {
            upperName.startsWith("PT30") ||
                upperName.startsWith("PT40") ||
                upperName.contains("PACIFIC") ||
                upperMac.startsWith("E0:B4:88") -> "pacificTrack"
            serviceUuids.any { it.equals(NUS_SERVICE_UUID.toString(), ignoreCase = true) } -> "nus"
            serviceUuids.any { it.equals(ELD_SERVICE_UUID.toString(), ignoreCase = true) } -> "ffe0"
            upperName.contains("ELD") || upperName.contains("OBD") -> "eld"
            else -> "unknown"
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

    private fun normalizeMac(input: String?): String? {
        if (input.isNullOrBlank()) return null
        val trimmed = input.trim()
        val stripped = trimmed.replace(":", "").replace("-", "")
        if (stripped.length == 12 && stripped.all { it in '0'..'9' || it in 'a'..'f' || it in 'A'..'F' }) {
            return stripped.chunked(2).joinToString(":").uppercase()
        }
        if (BluetoothAdapter.checkBluetoothAddress(trimmed.uppercase())) {
            return trimmed.uppercase()
        }
        return null
    }

    @SuppressLint("MissingPermission")
    private fun connectDevice(call: MethodCall, result: Result) {
        val rawMac = call.argument<String>("macAddress")?.trim() ?: run {
            result.error("NO_MAC", "MAC address required", null)
            return
        }

        if (!checkBluetoothPermissions(requireScan = false)) {
            result.error("PERMISSION_DENIED", "Bluetooth connect permission not granted", null)
            return
        }

        val ctx = context ?: run {
            result.error("NO_CONTEXT", "Application context is null", null)
            return
        }
        val bluetoothManager = ctx.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val bluetoothAdapter = bluetoothManager?.adapter

        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
            result.error("BT_DISABLED", "Bluetooth is disabled on this device", null)
            return
        }

        val macAddress = normalizeMac(rawMac) ?: run {
            result.error("INVALID_MAC", "Invalid Bluetooth MAC address format: $rawMac", null)
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
        val rawMac = call.argument<String>("macAddress") ?: run {
            result.error("NO_MAC", "MAC address required", null)
            return
        }
        val macAddress = normalizeMac(rawMac) ?: rawMac
        val ok = executeConnect(macAddress)
        result.success(ok)
    }

    /**
     * Decision 2 (P1): Reconnect Loop.
     * Pure connection executor. Devoid of any retry loop or timer logic.
     * Initiates GATT connection and returns true if initiated successfully.
     */
    @SuppressLint("MissingPermission")
    fun executeConnect(rawMac: String): Boolean {
        val macAddress = normalizeMac(rawMac) ?: rawMac
        if (!checkBluetoothPermissions(requireScan = false)) {
            return false
        }

        val ctx = context ?: return false
        bluetoothManager = ctx.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter

        if (bluetoothAdapter == null || !bluetoothAdapter!!.isEnabled) {
            return false
        }

        try {
            if (connectedGatt?.device?.address == macAddress) {
                // Already linked: report success, do not tear down a healthy GATT.
                return true
            }
        } catch (_: Exception) {}

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

        servicesDiscovered = false
        negotiatedMtu = 23
        connectedDeviceName = try { device.name } catch (_: SecurityException) { null }

        connectedGatt = device.connectGatt(ctx, false, gattCallback)
        val initiated = connectedGatt != null
        NativeLogStore.info(
            "BLE connect initiated to $macAddress (${connectedDeviceName ?: "unknown"})",
            "BLE"
        )
        if (initiated) {
            try {
                connectedGatt?.requestConnectionPriority(BluetoothGatt.CONNECTION_PRIORITY_HIGH)
            } catch (_: Exception) {}
        }
        return initiated
    }

    @SuppressLint("MissingPermission")
    private fun disconnectDevice(result: Result) {
        try {
            connectedGatt?.disconnect()
            connectedGatt?.close()
        } catch (_: Exception) {
        }
        connectedGatt = null
        servicesDiscovered = false
        writeCharacteristic = null
        notifyCharacteristics.clear()
        result.success(true)
    }

    // ========== GATT ==========

    private val gattCallback = object : BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            val address = try { gatt.device?.address } catch (_: SecurityException) { null }

            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    if (status == BluetoothGatt.GATT_SUCCESS) {
                        emit(mapOf(
                            "type" to "connected",
                            "macAddress" to (address ?: ""),
                            "name" to (connectedDeviceName ?: "")
                        ))
                        for (listener in connectionListeners) {
                            listener.onConnectionStateChange(true, address)
                        }
                        // Ask for a larger MTU (ELD frames), then discover. Some
                        // stacks never answer onMtuChanged, so a fallback timer
                        // guarantees service discovery still runs.
                        val requested = try { gatt.requestMtu(512) } catch (_: Exception) { false }
                        if (!requested) {
                            gatt.discoverServices()
                        } else {
                            mainHandler.postDelayed({
                                if (!servicesDiscovered && connectedGatt == gatt) {
                                    try { gatt.discoverServices() } catch (_: Exception) {}
                                }
                            }, 700)
                        }
                    } else {
                        NativeLogStore.warn("GATT connected with error status=$status", "BLE")
                        try { gatt.close() } catch (_: Exception) {}
                        connectedGatt = null
                    }
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    emit(mapOf(
                        "type" to "disconnected",
                        "macAddress" to (address ?: ""),
                        "status" to status
                    ))
                    for (listener in connectionListeners) {
                        listener.onConnectionStateChange(false, address)
                    }
                    try { gatt.close() } catch (_: Exception) {}
                    if (connectedGatt == gatt) connectedGatt = null
                    servicesDiscovered = false
                    writeCharacteristic = null
                    notifyCharacteristics.clear()
                    descriptorsToWrite.clear()
                }
            }
        }

        override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) negotiatedMtu = mtu
            if (!servicesDiscovered) {
                try { gatt.discoverServices() } catch (_: Exception) {}
            }
        }

        @SuppressLint("MissingPermission")
        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                NativeLogStore.error("Service discovery failed: status=$status", "BLE")
                emit(mapOf("type" to "discoveryFailed", "status" to status))
                return
            }
            servicesDiscovered = true

            val servicesInfo = mutableListOf<Map<String, Any?>>()

            for (service in gatt.services ?: emptyList()) {
                val charsInfo = mutableListOf<Map<String, Any?>>()
                for (characteristic in service.characteristics ?: emptyList()) {
                    charsInfo.add(mapOf(
                        "uuid" to characteristic.uuid.toString(),
                        "properties" to describeProperties(characteristic.properties)
                    ))

                    if (characteristic.properties and
                        (BluetoothGattCharacteristic.PROPERTY_NOTIFY or
                            BluetoothGattCharacteristic.PROPERTY_INDICATE) != 0
                    ) {
                        enableNotifications(gatt, characteristic)
                    }

                    if (characteristic.properties and
                        (BluetoothGattCharacteristic.PROPERTY_WRITE or
                            BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0
                    ) {
                        // Prefer the known ELD write characteristic when present.
                        if (writeCharacteristic == null ||
                            characteristic.uuid == ELD_CHARACTERISTIC_UUID ||
                            characteristic.uuid == NUS_TX_UUID
                        ) {
                            writeCharacteristic = characteristic
                        }
                    }
                }
                servicesInfo.add(mapOf(
                    "uuid" to service.uuid.toString(),
                    "characteristics" to charsInfo
                ))
            }

            emit(mapOf(
                "type" to "services",
                "mtu" to negotiatedMtu,
                "services" to servicesInfo
            ))
            NativeLogStore.info(
                "GATT ready: ${servicesInfo.size} services, " +
                    "notify=${notifyCharacteristics.size}, mtu=$negotiatedMtu",
                "BLE"
            )

            // Battery is useful diagnostics when an ELD dies mid-shift.
            try {
                val battery = gatt.getService(BATTERY_SERVICE_UUID)
                    ?.getCharacteristic(BATTERY_LEVEL_UUID)
                if (battery != null) gatt.readCharacteristic(battery)
            } catch (_: Exception) {
            }
        }

        override fun onDescriptorWrite(
            gatt: BluetoothGatt,
            descriptor: BluetoothGattDescriptor,
            status: Int
        ) {
            val next = synchronized(descriptorsToWrite) {
                if (descriptorsToWrite.isEmpty()) null else descriptorsToWrite.removeFirst()
            }
            next?.let {
                try {
                    gatt.writeDescriptor(it)
                } catch (_: Exception) {}
            }
        }

        override fun onCharacteristicRead(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int
        ) {
            handleCharacteristicRead(characteristic, characteristic.value)
        }

        override fun onCharacteristicRead(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
            status: Int
        ) {
            handleCharacteristicRead(characteristic, value)
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic
        ) {
            handleData(gatt, characteristic, characteristic.value)
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray
        ) {
            handleData(gatt, characteristic, value)
        }
    }

    @SuppressLint("MissingPermission")
    private fun enableNotifications(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
        try {
            if (!gatt.setCharacteristicNotification(characteristic, true)) {
                return
            }
            notifyCharacteristics.add(characteristic.uuid)
            val descriptor = characteristic.getDescriptor(CCCD_UUID) ?: return
            descriptor.value = if (characteristic.properties and
                BluetoothGattCharacteristic.PROPERTY_INDICATE != 0
            ) {
                BluetoothGattDescriptor.ENABLE_INDICATION_VALUE
            } else {
                BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
            }
            synchronized(descriptorsToWrite) {
                if (descriptorsToWrite.isEmpty()) {
                    gatt.writeDescriptor(descriptor)
                } else {
                    descriptorsToWrite.addLast(descriptor)
                }
            }
        } catch (e: Exception) {
            NativeLogStore.warn("Failed to enable notifications: ${e.message}", "BLE")
        }
    }

    private fun handleCharacteristicRead(
        characteristic: BluetoothGattCharacteristic,
        value: ByteArray?
    ) {
        if (characteristic.uuid == BATTERY_LEVEL_UUID && value != null && value.isNotEmpty()) {
            batteryLevel = value[0].toInt() and 0xFF
            emit(mapOf("type" to "battery", "level" to batteryLevel))
        }
    }

    private fun handleData(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic,
        value: ByteArray?
    ) {
        if (value == null || value.isEmpty()) return
        val hex = value.joinToString("") { byte -> "%02X".format(byte) }
        val ascii = value.map { byte ->
            val c = byte.toInt() and 0xFF
            if (c in 32..126) c.toChar() else '.'
        }.joinToString("")

        emit(mapOf(
            "type" to "data",
            "data" to value.joinToString(","),
            "values" to value.map { it.toInt() and 0xFF },
            "hex" to hex,
            "ascii" to ascii,
            "characteristic" to characteristic.uuid.toString(),
            "service" to try { characteristic.service?.uuid?.toString() } catch (_: Exception) { null },
            "timestamp" to System.currentTimeMillis()
        ))
    }

    // ========== Commands & diagnostics ==========

    @SuppressLint("MissingPermission")
    private fun sendCommand(call: MethodCall, result: Result) {
        val gatt = connectedGatt ?: run {
            result.error("NOT_CONNECTED", "No BLE device connected", null)
            return
        }
        if (!checkBluetoothPermissions(requireScan = false)) {
            result.error("PERMISSION_DENIED", "Bluetooth connect permission not granted", null)
            return
        }

        val payload: ByteArray = parsePayload(call)
        if (payload.isEmpty()) {
            result.error("INVALID_COMMAND", "hex or text argument required", null)
            return
        }

        val requestedUuid = call.argument<String>("characteristic")?.let {
            runCatching { UUID.fromString(it) }.getOrNull()
        }
        val characteristic = requestedUuid?.let { uuid ->
            writeCharacteristic?.takeIf { it.uuid == uuid }
                ?: gatt.services
                    ?.flatMap { it.characteristics ?: emptyList() }
                    ?.firstOrNull { it.uuid == uuid }
        } ?: writeCharacteristic ?: gatt.services
            ?.flatMap { it.characteristics ?: emptyList() }
            ?.firstOrNull {
                it.properties and (BluetoothGattCharacteristic.PROPERTY_WRITE or
                    BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0
            }

        if (characteristic == null) {
            result.error("NO_WRITE_CHARACTERISTIC", "Device has no writable characteristic", null)
            return
        }

        val writeType = call.argument<String>("writeType")?.lowercase()
        val useNoResponse = writeType == "noresponse" ||
            characteristic.properties and BluetoothGattCharacteristic.PROPERTY_WRITE == 0

        val ok = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val type = if (useNoResponse) {
                    BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                } else {
                    BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                }
                gatt.writeCharacteristic(characteristic, payload, type) == BluetoothGatt.GATT_SUCCESS
            } else {
                @Suppress("DEPRECATION")
                characteristic.writeType = if (useNoResponse) {
                    BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                } else {
                    BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                }
                @Suppress("DEPRECATION")
                characteristic.value = payload
                @Suppress("DEPRECATION")
                gatt.writeCharacteristic(characteristic)
            }
        } catch (e: Exception) {
            NativeLogStore.error("BLE write failed: ${e.message}", "BLE")
            false
        }

        if (ok) {
            result.success(true)
        } else {
            result.error("WRITE_FAILED", "Could not write to ${characteristic.uuid}", null)
        }
    }

    private fun parsePayload(call: MethodCall): ByteArray {
        val hex = call.argument<String>("hex")
        if (!hex.isNullOrBlank()) {
            val clean = hex.replace(" ", "").replace(":", "").replace("-", "")
            if (clean.length % 2 != 0) return ByteArray(0)
            return ByteArray(clean.length / 2) { index ->
                clean.substring(index * 2, index * 2 + 2).toInt(16).toByte()
            }
        }
        val text = call.argument<String>("text")
        return text?.toByteArray(Charsets.UTF_8) ?: ByteArray(0)
    }

    @SuppressLint("MissingPermission")
    private fun readDeviceInfo(): Map<String, Any?> {
        val gatt = connectedGatt
        val services = try {
            gatt?.services?.map { service ->
                mapOf(
                    "uuid" to service.uuid.toString(),
                    "characteristics" to (service.characteristics ?: emptyList()).map { characteristic ->
                        mapOf(
                            "uuid" to characteristic.uuid.toString(),
                            "properties" to describeProperties(characteristic.properties)
                        )
                    }
                )
            } ?: emptyList()
        } catch (_: Exception) {
            emptyList()
        }

        return mapOf(
            "connected" to (gatt != null),
            "macAddress" to (try { gatt?.device?.address } catch (_: Exception) { null } ?: lastMacAddress),
            "name" to connectedDeviceName,
            "mtu" to negotiatedMtu,
            "batteryLevel" to batteryLevel,
            "notifyCharacteristics" to notifyCharacteristics.map { it.toString() },
            "writeCharacteristic" to writeCharacteristic?.uuid?.toString(),
            "services" to services,
            "scanning" to (scanner != null),
            "scanElapsedMs" to if (scanStartedAt > 0) {
                SystemClock.elapsedRealtime() - scanStartedAt
            } else {
                0L
            }
        )
    }

    private fun lastDeviceMap(): Map<String, Any?> = mapOf(
        "macAddress" to lastMacAddress,
        "name" to connectedDeviceName
    )

    private fun describeProperties(properties: Int): List<String> {
        val result = mutableListOf<String>()
        if (properties and BluetoothGattCharacteristic.PROPERTY_READ != 0) result.add("read")
        if (properties and BluetoothGattCharacteristic.PROPERTY_WRITE != 0) result.add("write")
        if (properties and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE != 0) {
            result.add("writeNoResponse")
        }
        if (properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY != 0) result.add("notify")
        if (properties and BluetoothGattCharacteristic.PROPERTY_INDICATE != 0) result.add("indicate")
        return result
    }

    // ========== Permissions ==========

    private fun checkBluetoothPermissions(requireScan: Boolean): Boolean {
        val ctx = context ?: return true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val connect = ctx.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) ==
                PackageManager.PERMISSION_GRANTED
            if (!requireScan) return connect
            val scan = ctx.checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) ==
                PackageManager.PERMISSION_GRANTED
            return connect && scan
        }
        return true
    }
}
