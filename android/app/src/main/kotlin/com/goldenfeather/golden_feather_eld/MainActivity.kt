package com.goldenfeather.golden_feather_eld

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.goldenfeather.golden_feather_eld.plugins.TraccarPlugin
import com.goldenfeather.golden_feather_eld.plugins.BluetoothPlugin
import com.goldenfeather.golden_feather_eld.plugins.BatteryPlugin

class MainActivity : FlutterActivity() {

    private lateinit var traccarPlugin: TraccarPlugin
    private lateinit var bluetoothPlugin: BluetoothPlugin

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ========== Traccar ==========
        traccarPlugin = TraccarPlugin(applicationContext)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TraccarPlugin.METHOD_CHANNEL
        ).setMethodCallHandler(traccarPlugin)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TraccarPlugin.EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                traccarPlugin.setEventSink(events)
            }
            override fun onCancel(arguments: Any?) {
                traccarPlugin.setEventSink(null)
            }
        })

        // ========== Bluetooth ==========
        bluetoothPlugin = BluetoothPlugin(applicationContext)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BluetoothPlugin.METHOD_CHANNEL
        ).setMethodCallHandler(bluetoothPlugin)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BluetoothPlugin.EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                bluetoothPlugin.setEventSink(events)
            }
            override fun onCancel(arguments: Any?) {
                bluetoothPlugin.setEventSink(null)
            }
        })

        // ========== Battery ==========
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BatteryPlugin.METHOD_CHANNEL
        ).setMethodCallHandler(BatteryPlugin(applicationContext))
    }
}
