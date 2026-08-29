package com.goldenfeather.golden_feather_eld.plugins

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.ParcelUuid
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.UUID

/**
 * BluetoothPlugin - اتصال BLE مع جهاز ELD
 */
class BluetoothPlugin(
    private val context: Context
) : MethodCallHandler {

    private var bluetoothManager: BluetoothManager? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var scanner: BluetoothLeScanner? = null
    private var connectedGatt: BluetoothGatt? = null
    private var eventSink: EventChannel.EventSink? = null

    companion object {
        const val METHOD_CHANNEL = "com.goldenfeather.eld/bluetooth"
        const val EVENT_CHANNEL = "com.goldenfeather.eld/bluetooth/events"

        // UUIDs قياسية لـ ELD Adapters (OBD-II BLE)
        val ELD_SERVICE_UUID: UUID = UUID.fromString("0000ffe0-0000-1000-8000-00805f9b34fb")
        val ELD_CHARACTERISTIC_UUID: UUID = UUID.fromString("0000ffe1-0000-1000-8000-00805f9b34fb")
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
                "disconnect" -> disconnectDevice(result)
                "isConnected" -> result.success(connectedGatt != null)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("BLUETOOTH_ERROR", e.message, null)
        }
    }

    @SuppressLint("MissingPermission")
    private fun startScan(result: Result) {
        val hasPermission = checkBluetoothPermission()
        if (!hasPermission) {
            result.error("PERMISSION_DENIED", "Bluetooth permission not granted", null)
            return
        }

        bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
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

        val hasPermission = checkBluetoothPermission()
        if (!hasPermission) {
            result.error("PERMISSION_DENIED", "Bluetooth permission not granted", null)
            return
        }

        bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter

        val device = bluetoothAdapter?.getRemoteDevice(macAddress) ?: run {
            result.error("DEVICE_NOT_FOUND", "Device not found: $macAddress", null)
            return
        }

        connectedGatt = device.connectGatt(context, false, gattCallback)
        result.success(true)
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
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    eventSink?.success(mapOf("type" to "connected"))
                    gatt.discoverServices()
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    eventSink?.success(mapOf("type" to "disconnected"))
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
            eventSink?.success(mapOf(
                "type" to "data",
                "data" to (value?.joinToString(",") ?: "")
            ))
        }
    }

    private fun checkBluetoothPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) ==
                    PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }
}
