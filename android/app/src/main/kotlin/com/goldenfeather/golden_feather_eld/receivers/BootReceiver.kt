package com.goldenfeather.golden_feather_eld.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.goldenfeather.golden_feather_eld.services.TrackingServiceManager

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // إعادة تشغيل خدمة التتبع بعد إعادة تشغيل الجهاز
            TrackingServiceManager.start(context)
        }
    }
}
