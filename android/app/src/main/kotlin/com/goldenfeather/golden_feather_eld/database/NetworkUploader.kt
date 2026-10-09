package com.goldenfeather.golden_feather_eld.database

import android.content.Context
import android.util.Log
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class NetworkUploader(private val context: Context) {

    private val dbHelper = LocationDatabaseHelper(context)
    private val executor = Executors.newSingleThreadExecutor()
    private var isUploading = false

    fun triggerUpload(serverUrl: String, deviceId: String) {
        if (serverUrl.isEmpty() || deviceId.isEmpty()) return
        
        executor.execute {
            if (isUploading) return@execute
            isUploading = true

            try {
                var pending = dbHelper.getPendingLocations()
                while (pending.isNotEmpty()) {
                    for (loc in pending) {
                        val success = uploadSingleLocation(serverUrl, deviceId, loc)
                        if (success) {
                            dbHelper.deleteLocation(loc.id)
                        } else {
                            // If one fails, assume network issue and stop the loop
                            isUploading = false
                            return@execute
                        }
                    }
                    // Fetch next batch
                    pending = dbHelper.getPendingLocations()
                }
            } catch (e: Exception) {
                Log.e("TRACCAR_PLUGIN", "Error during upload loop", e)
            } finally {
                isUploading = false
            }
        }
    }

    private fun uploadSingleLocation(serverUrl: String, deviceId: String, loc: LocationModel): Boolean {
        return try {
            // OsmAnd protocol formatting
            // Traccar default OsmAnd port is 5055. serverUrl should be e.g. "http://demo.traccar.org:5055"
            var baseUrl = if (serverUrl.endsWith("/")) serverUrl.dropLast(1) else serverUrl
            if (baseUrl.startsWith("http://")) {
                baseUrl = baseUrl.replaceFirst("http://", "https://")
            }
            val urlString = "$baseUrl/?id=$deviceId&lat=${loc.latitude}&lon=${loc.longitude}&timestamp=${loc.timestamp}&speed=${loc.speed}&bearing=${loc.bearing}&altitude=${loc.altitude}&accuracy=${loc.accuracy}"
            val url = URL(urlString)
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = 5000
            connection.readTimeout = 5000

            val responseCode = connection.responseCode
            connection.disconnect()
            
            Log.i("TRACCAR_PLUGIN", "Uploaded location ${loc.id}, response code: $responseCode")
            
            // Assume 200 OK means success. Sometimes Traccar returns 200 with empty body.
            responseCode == HttpURLConnection.HTTP_OK
        } catch (e: Exception) {
            Log.e("TRACCAR_PLUGIN", "Failed to upload location ${loc.id}: ${e.message}")
            false
        }
    }
}
