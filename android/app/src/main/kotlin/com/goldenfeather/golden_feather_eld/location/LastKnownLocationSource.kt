package com.goldenfeather.golden_feather_eld.location

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Build

/**
 * قراءة فقط لآخر موقع معروف من نظام التشغيل.
 *
 * لا تُدخل الموقع في قاعدة البيانات ولا ترفعه إلى الخادم؛ تُستخدم فقط لبذر
 * واجهة Flutter بقراءة حديثة عند بدء الخدمة أو فتح الشاشة. نُرجع أحدث قفل
 * ضمن نافذة عمر قصيرة حتى لا نعرض إحداثيات قديمة كأنها الموقع الحالي.
 */
object LastKnownLocationSource {

    /** أقصى عمر مقبول للقفل: 5 دقائق. */
    const val DEFAULT_MAX_AGE_MILLIS = 5 * 60 * 1000L

    private val PROVIDERS = listOf(
        LocationManager.GPS_PROVIDER,
        LocationManager.NETWORK_PROVIDER,
        LocationManager.PASSIVE_PROVIDER
    )

    @SuppressLint("MissingPermission")
    fun latest(
        context: Context,
        maxAgeMillis: Long = DEFAULT_MAX_AGE_MILLIS
    ): Location? {
        if (!hasLocationPermission(context)) return null

        val manager = context.getSystemService(Context.LOCATION_SERVICE)
            as? LocationManager ?: return null

        val newest = PROVIDERS.mapNotNull { provider ->
            try {
                manager.getLastKnownLocation(provider)
            } catch (e: SecurityException) {
                null
            } catch (e: Exception) {
                null
            }
        }.maxByOrNull { it.time } ?: return null

        val age = System.currentTimeMillis() - newest.time
        return if (age in 0..maxAgeMillis) newest else null
    }

    private fun hasLocationPermission(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }
}
