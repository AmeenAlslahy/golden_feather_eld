package com.goldenfeather.golden_feather_eld.database

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.location.Location

data class LocationModel(
    val id: Long = 0,
    val latitude: Double,
    val longitude: Double,
    /** Speed in metres per second, exactly as reported by [Location.getSpeed]. */
    val speed: Double,
    val bearing: Double,
    val altitude: Double,
    val accuracy: Double,
    /** Unix epoch seconds (what the OsmAnd protocol expects). */
    val timestamp: Long,
    val alarm: String? = null,
    val source: String? = null
)

class LocationDatabaseHelper(context: Context) : SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val DATABASE_NAME = "locations.db"
        // v2: alarm + source columns. Upgrade is additive so queued offline
        // positions survive the update.
        private const val DATABASE_VERSION = 2
        private const val TABLE_LOCATIONS = "locations"

        private const val COLUMN_ID = "id"
        private const val COLUMN_LAT = "latitude"
        private const val COLUMN_LON = "longitude"
        private const val COLUMN_SPEED = "speed"
        private const val COLUMN_BEARING = "bearing"
        private const val COLUMN_ALTITUDE = "altitude"
        private const val COLUMN_ACCURACY = "accuracy"
        private const val COLUMN_TIMESTAMP = "timestamp"
        private const val COLUMN_ALARM = "alarm"
        private const val COLUMN_SOURCE = "source"
    }

    override fun onCreate(db: SQLiteDatabase) {
        val createTable = ("CREATE TABLE " + TABLE_LOCATIONS + "("
                + COLUMN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT,"
                + COLUMN_LAT + " REAL,"
                + COLUMN_LON + " REAL,"
                + COLUMN_SPEED + " REAL,"
                + COLUMN_BEARING + " REAL,"
                + COLUMN_ALTITUDE + " REAL,"
                + COLUMN_ACCURACY + " REAL,"
                + COLUMN_TIMESTAMP + " INTEGER,"
                + COLUMN_ALARM + " TEXT,"
                + COLUMN_SOURCE + " TEXT" + ")")
        db.execSQL(createTable)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 2) {
            db.execSQL("ALTER TABLE $TABLE_LOCATIONS ADD COLUMN $COLUMN_ALARM TEXT")
            db.execSQL("ALTER TABLE $TABLE_LOCATIONS ADD COLUMN $COLUMN_SOURCE TEXT")
        }
    }

    fun insertLocation(location: Location, alarm: String? = null, source: String = "phone") {
        insertRawLocation(
            latitude = location.latitude,
            longitude = location.longitude,
            speedMps = location.speed.toDouble(),
            bearing = location.bearing.toDouble(),
            altitude = location.altitude,
            accuracy = location.accuracy.toDouble(),
            timestampSeconds = System.currentTimeMillis() / 1000,
            alarm = alarm,
            source = source
        )
    }

    /**
     * Inserts a fix that did not come from Android's [Location] object (BLE ELD,
     * replay, immediate request). Speed must be metres per second.
     */
    fun insertRawLocation(
        latitude: Double,
        longitude: Double,
        speedMps: Double,
        bearing: Double,
        altitude: Double,
        accuracy: Double,
        timestampSeconds: Long,
        alarm: String? = null,
        source: String = "ble"
    ) {
        val values = ContentValues().apply {
            put(COLUMN_LAT, latitude)
            put(COLUMN_LON, longitude)
            put(COLUMN_SPEED, speedMps)
            put(COLUMN_BEARING, bearing)
            put(COLUMN_ALTITUDE, altitude)
            put(COLUMN_ACCURACY, accuracy)
            put(COLUMN_TIMESTAMP, timestampSeconds)
            put(COLUMN_ALARM, alarm)
            put(COLUMN_SOURCE, source)
        }
        writableDatabase.insert(TABLE_LOCATIONS, null, values)
    }

    fun getPendingLocations(): List<LocationModel> {
        val locationList = ArrayList<LocationModel>()
        val selectQuery = "SELECT * FROM $TABLE_LOCATIONS ORDER BY $COLUMN_ID ASC LIMIT 50"

        val db = this.readableDatabase
        val cursor = db.rawQuery(selectQuery, null)

        if (cursor.moveToFirst()) {
            do {
                val loc = LocationModel(
                    id = cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_ID)),
                    latitude = cursor.getDouble(cursor.getColumnIndexOrThrow(COLUMN_LAT)),
                    longitude = cursor.getDouble(cursor.getColumnIndexOrThrow(COLUMN_LON)),
                    speed = cursor.getDouble(cursor.getColumnIndexOrThrow(COLUMN_SPEED)),
                    bearing = cursor.getDouble(cursor.getColumnIndexOrThrow(COLUMN_BEARING)),
                    altitude = cursor.getDouble(cursor.getColumnIndexOrThrow(COLUMN_ALTITUDE)),
                    accuracy = cursor.getDouble(cursor.getColumnIndexOrThrow(COLUMN_ACCURACY)),
                    timestamp = cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_TIMESTAMP)),
                    alarm = cursor.getStringOrNull(COLUMN_ALARM),
                    source = cursor.getStringOrNull(COLUMN_SOURCE)
                )
                locationList.add(loc)
            } while (cursor.moveToNext())
        }
        cursor.close()
        db.close()
        return locationList
    }

    fun pendingCount(): Int {
        val db = this.readableDatabase
        val cursor = db.rawQuery("SELECT COUNT(*) FROM $TABLE_LOCATIONS", null)
        val count = if (cursor.moveToFirst()) cursor.getInt(0) else 0
        cursor.close()
        db.close()
        return count
    }

    fun deleteLocation(id: Long) {
        val db = this.writableDatabase
        db.delete(TABLE_LOCATIONS, "$COLUMN_ID = ?", arrayOf(id.toString()))
        db.close()
    }

    private fun android.database.Cursor.getStringOrNull(column: String): String? {
        val index = getColumnIndexOrThrow(column)
        return if (isNull(index)) null else getString(index)
    }
}
