package com.goldenfeather.golden_feather_eld.logging

import android.util.Log

/**
 * In-memory ring buffer shared by the native tracking engine, the uploader and
 * the BLE plugin.
 *
 * Before this existed, `getLogs` returned an empty list forever, which made the
 * diagnostics screen useless exactly when the driver needed it (no uploads,
 * repeated BLE disconnects, rejected server URL...).
 */
object NativeLogStore {

    private const val MAX_ENTRIES = 500
    private const val TAG = "TRACCAR_PLUGIN"

    private val entries = ArrayDeque<Map<String, Any>>()
    private val lock = Any()

    fun add(level: String, message: String, tag: String = TAG) {
        val entry = mapOf(
            "timestamp" to System.currentTimeMillis(),
            "level" to level,
            "tag" to tag,
            "message" to message
        )
        synchronized(lock) {
            entries.addLast(entry)
            while (entries.size > MAX_ENTRIES) {
                entries.removeFirst()
            }
        }
        when (level.uppercase()) {
            "E" -> Log.e(tag, message)
            "W" -> Log.w(tag, message)
            "D" -> Log.d(tag, message)
            else -> Log.i(tag, message)
        }
    }

    fun info(message: String, tag: String = TAG) = add("I", message, tag)

    fun warn(message: String, tag: String = TAG) = add("W", message, tag)

    fun error(message: String, tag: String = TAG) = add("E", message, tag)

    fun snapshot(): List<Map<String, Any>> = synchronized(lock) {
        entries.toList()
    }

    fun clear() {
        synchronized(lock) { entries.clear() }
    }
}
