package com.goldenfeather.golden_feather_eld.services

import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

object TrackingServiceManager {

    fun start(context: Context) {
        val intent = Intent(context, TrackingForegroundService::class.java)
        intent.action = TrackingForegroundService.ACTION_START
        ContextCompat.startForegroundService(context, intent)
    }

    fun stop(context: Context) {
        val intent = Intent(context, TrackingForegroundService::class.java)
        intent.action = TrackingForegroundService.ACTION_STOP
        context.startService(intent)
    }
}
