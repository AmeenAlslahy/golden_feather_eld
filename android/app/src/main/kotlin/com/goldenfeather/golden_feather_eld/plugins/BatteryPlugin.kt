package com.goldenfeather.golden_feather_eld.plugins

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * BatteryPlugin - فحص تحسين البطارية لضمان عمل التتبع في الخلفية
 */
class BatteryPlugin(
    private val context: Context
) : MethodCallHandler {

    companion object {
        const val METHOD_CHANNEL = "com.goldenfeather.eld/battery"
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isIgnoringBatteryOptimizations" -> checkBatteryOptimization(result)
            "requestIgnoreBatteryOptimizations" -> requestIgnoreBattery(result)
            else -> result.notImplemented()
        }
    }

    private fun checkBatteryOptimization(result: Result) {
        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val isIgnoring = powerManager.isIgnoringBatteryOptimizations(context.packageName)
            result.success(!isIgnoring) // true = يحتاج طلب
        } catch (e: Exception) {
            result.error("BATTERY_CHECK_ERROR", e.message, null)
        }
    }

    private fun requestIgnoreBattery(result: Result) {
        try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            intent.data = Uri.parse("package:${context.packageName}")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("BATTERY_REQUEST_ERROR", e.message, null)
        }
    }
}
