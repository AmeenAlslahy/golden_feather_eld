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
    val speed: Double,
    val bearing: Double,
    val altitude: Double,
    val accuracy: Double,
    val timestamp: Long
)

class LocationDatabaseHelper(context: Context) : SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val DATABASE_NAME = "locations.db"
        private const val DATABASE_VERSION = 1
        private const val TABLE_LOCATIONS = "locations"

        private const val COLUMN_ID = "id"
        private const val COLUMN_LAT = "latitude"
        private const val COLUMN_LON = "longitude"
        private const val COLUMN_SPEED = "speed"
        private const val COLUMN_BEARING = "bearing"
        private const val COLUMN_ALTITUDE = "altitude"
        private const val COLUMN_ACCURACY = "accuracy"
        private const val COLUMN_TIMESTAMP = "timestamp"
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
                + COLUMN_TIMESTAMP + " INTEGER" + ")")
        db.execSQL(createTable)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE_LOCATIONS")
        onCreate(db)
    }

    fun insertLocation(location: Location) {
        val db = this.writableDatabase
        val values = ContentValues()
        values.put(COLUMN_LAT, location.latitude)
        values.put(COLUMN_LON, location.longitude)
        values.put(COLUMN_SPEED, location.speed.toDouble())
        values.put(COLUMN_BEARING, location.bearing.toDouble())
        values.put(COLUMN_ALTITUDE, location.altitude)
        values.put(COLUMN_ACCURACY, location.accuracy.toDouble())
        values.put(COLUMN_TIMESTAMP, System.currentTimeMillis() / 1000) // Traccar expects seconds usually, but wait, OsmAnd expects seconds or milliseconds? OsmAnd expects seconds.

        db.insert(TABLE_LOCATIONS, null, values)
        db.close()
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
                    timestamp = cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_TIMESTAMP))
                )
                locationList.add(loc)
            } while (cursor.moveToNext())
        }
        cursor.close()
        db.close()
        return locationList
    }

    fun deleteLocation(id: Long) {
        val db = this.writableDatabase
        db.delete(TABLE_LOCATIONS, "$COLUMN_ID = ?", arrayOf(id.toString()))
        db.close()
    }
}
