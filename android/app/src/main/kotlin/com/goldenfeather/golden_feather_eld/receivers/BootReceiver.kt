package com.goldenfeather.golden_feather_eld.receivers

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import com.goldenfeather.golden_feather_eld.logging.NativeLogStore
import com.goldenfeather.golden_feather_eld.services.TrackingServiceManager

/**
 * Restores tracking after a reboot **only** when the driver had tracking
 * enabled. The previous version always started the foreground service, so
 * reinstalling or rebooting forced tracking on users who had turned it off, and
 * could crash on Android 12+ with a missing foreground-service permission.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }

        val prefs = context.getSharedPreferences("traccar_config", Context.MODE_PRIVATE)
        val wasTracking = prefs.getBoolean("tracking_enabled", false)
        if (!wasTracking) {
            NativeLogStore.info(
                "Boot completed: tracking was disabled by the user. Not restarting.",
                "BOOT_RECEIVER"
            )
            return
        }

        val hasLocation = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
        if (!hasLocation) {
            NativeLogStore.warn(
                "Boot completed: tracking enabled but location permission is missing.",
                "BOOT_RECEIVER"
            )
            return
        }

        try {
            TrackingServiceManager.start(context)
            NativeLogStore.info("Boot completed: tracking service restarted.", "BOOT_RECEIVER")
        } catch (e: Exception) {
            NativeLogStore.error(
                "Boot completed: failed to restart tracking (${e.message})",
                "BOOT_RECEIVER"
            )
        }
    }
}
