package com.example.sdg.services

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.*
import kotlinx.coroutines.*
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

/**
 * Central manager for emergency alert workflow:
 * 1. Detects emergency keywords from speech text
 * 2. Obtains GPS location via FusedLocationProviderClient
 * 3. Sends alert to SmartAid backend
 */
object EmergencyAlertManager {

    private const val TAG = "EmergencyAlertManager"
    private const val BACKEND_URL = "http://10.31.181.206:8000"

    // Emergency keywords - multilingual (English, Tamil, Hindi, Kannada, Malayalam, Telugu)
    private val emergencyKeywords = listOf(
        // English
        "help", "help me", "accident", "ambulance", "emergency",
        "medical", "injured", "hurt", "bleeding",
        "unconscious", "crash", "fire", "sos",
        "save me", "need doctor", "call ambulance",
        "send help", "heart attack", "stroke", "choking",
        "danger", "please help", "somebody help",
        "call police", "send ambulance", "i need help",
        "medical emergency", "i fell down",
        // Tamil (native script)
        "உதவி", "உதவி செய்யுங்கள்", "விபத்து", "ஆம்புலன்ஸ்", "அவசரம்",
        "காயம்", "ரத்தம்", "நெருப்பு", "வலி", "மருத்துவர்",
        "காப்பாத்துங்க", "காப்பாற்றுங்க", "காப்பாற்றுங்கள்",
        "என்னை காப்பாத்துங்க", "என்னை காப்பாற்றுங்கள்",
        "காப்பாத்துங்க ஐயா", "எனக்கு உதவி வேண்டும்", "ஆபத்து",
        "ஆம்புலன்ஸ் அழைக்கவும்", "போலீஸ் அழைக்கவும்",
        "நான் காயம் அடைந்தேன்", "நான் விழுந்துவிட்டேன்",
        "தயவு செய்து உதவி செய்யுங்கள்",
        // Tamil (phonetic - speech may output English letters)
        "udhavi", "udavi", "udhavi pannunga",
        "kaapathunga", "kapathunga", "kaapatrunga",
        "ennaai kaapathunga", "ambulance azhaikkavum", "vibathu",
        // Hindi
        "मदद", "मेरी मदद करो", "दुर्घटना", "एम्बुलेंस", "आपातकाल",
        "घायल", "खून", "आग", "दर्द", "बचाओ", "डॉक्टर",
        "एम्बुलेंस बुलाओ", "पुलिस बुलाओ", "मुझे चोट लगी है",
        "कृपया मदद करें", "खतरा", "मेरी जान बचाओ", "जल्दी मदद करो",
        // Kannada
        "ಸಹಾಯ", "ಸಹಾಯ ಮಾಡಿ", "ಅಪಘಾತ", "ಆಂಬುಲೆನ್ಸ್", "ತುರ್ತು",
        "ಗಾಯ", "ರಕ್ತಸ್ರಾವ", "ಬೆಂಕಿ", "ನೋವು",
        "ರಕ್ಷಿಸಿ", "ಅಪಾಯ", "ತುರ್ತು ಪರಿಸ್ಥಿತಿ",
        "ಆಂಬುಲೆನ್ಸ್ ಕರೆ ಮಾಡಿ", "ಪೋಲೀಸ್ ಕರೆ ಮಾಡಿ",
        "ನನಗೆ ಗಾಯವಾಗಿದೆ", "ದಯವಿಟ್ಟು ಸಹಾಯ ಮಾಡಿ",
        // Malayalam
        "സഹായം", "സഹായിക്കൂ", "അപകടം", "ആംബുലൻസ്", "അടിയന്തരം",
        "പരിക്ക്", "രക്തസ്രാവം", "തീ", "വേദന",
        "രക്ഷിക്കൂ", "ആംബുലൻസ് വിളിക്കൂ", "പൊലീസ് വിളിക്കൂ",
        "എനിക്ക് പരിക്ക് പറ്റി", "ദയവായി സഹായിക്കൂ", "അടിയന്തിരം",
        // Telugu
        "సహాయం", "సహాయం చేయండి", "ప్రమాదం", "ఆంబులెన్స్", "అత్యవసరం",
        "గాయం", "రక్తస్రావం", "మంట", "నొప్పి",
        "రక్షించండి", "అంబులెన్స్ పిలవండి", "పోలీస్ పిలవండి",
        "నాకు గాయం అయ్యింది", "దయచేసి సహాయం చేయండి"
    )

    /**
     * Check if the transcribed text contains any emergency keyword.
     * Returns the matched keyword or null.
     */
    fun detectEmergencyKeyword(text: String): String? {
        val lower = text.lowercase().trim()
        return emergencyKeywords.firstOrNull { lower.contains(it) }
    }

    /**
     * Get current GPS location using FusedLocationProviderClient.
     * Returns Location or null if unavailable.
     */
    suspend fun getCurrentLocation(context: Context): Location? = withContext(Dispatchers.Main) {
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION)
            != PackageManager.PERMISSION_GRANTED
        ) {
            Log.w(TAG, "Location permission not granted")
            return@withContext null
        }

        val client = LocationServices.getFusedLocationProviderClient(context)

        return@withContext suspendCancellableCoroutine { cont ->
            // Try last known first
            client.lastLocation.addOnSuccessListener { location ->
                if (location != null) {
                    cont.resume(location) {}
                } else {
                    // Request a fresh location
                    val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 1000)
                        .setMaxUpdates(1)
                        .setWaitForAccurateLocation(false)
                        .setMaxUpdateDelayMillis(5000)
                        .build()

                    val callback = object : LocationCallback() {
                        override fun onLocationResult(result: LocationResult) {
                            client.removeLocationUpdates(this)
                            cont.resume(result.lastLocation) {}
                        }
                    }

                    try {
                        client.requestLocationUpdates(request, callback, Looper.getMainLooper())
                    } catch (e: SecurityException) {
                        Log.e(TAG, "SecurityException requesting location", e)
                        cont.resume(null) {}
                    }

                    cont.invokeOnCancellation {
                        client.removeLocationUpdates(callback)
                    }
                }
            }.addOnFailureListener {
                Log.e(TAG, "Failed to get last location", it)
                cont.resume(null) {}
            }
        }
    }

    /**
     * Send an emergency alert to the SmartAid backend.
     * Runs on IO dispatcher.
     */
    suspend fun sendEmergencyAlert(
        context: Context,
        latitude: Double,
        longitude: Double,
        spokenText: String,
        keyword: String
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            // Get auth token from shared prefs (stored by MainActivity when Flutter starts native services)
            val prefs = context.getSharedPreferences("smartaid_native", Context.MODE_PRIVATE)
            val token = prefs.getString("auth_token", null)

            val url = URL("$BACKEND_URL/api/client/sos")
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.connectTimeout = 15000
            conn.readTimeout = 15000
            conn.doOutput = true

            if (token != null) {
                conn.setRequestProperty("Authorization", "Bearer $token")
            }

            val body = JSONObject().apply {
                put("location", JSONObject().apply {
                    put("lat", latitude)
                    put("lng", longitude)
                })
                put("condition", "voice_emergency: $spokenText")
                put("preliminary_severity", "high")
                put("auto_triggered", true)
                put("sensor_data", JSONObject().apply {
                    put("trigger_type", "native_voice_activation")
                    put("spoken_text", spokenText)
                    put("matched_keyword", keyword)
                    put("source", "android_native")
                })
                put("contact", "")
            }

            val writer = OutputStreamWriter(conn.outputStream)
            writer.write(body.toString())
            writer.flush()
            writer.close()

            val responseCode = conn.responseCode
            Log.d(TAG, "SOS alert sent, response: $responseCode")
            conn.disconnect()

            return@withContext responseCode in 200..299
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send emergency alert", e)
            return@withContext false
        }
    }

    /**
     * Full emergency workflow: detect keyword → get location → send alert.
     * Returns a result map for the UI.
     */
    suspend fun handleEmergencySpeech(
        context: Context,
        spokenText: String
    ): Map<String, Any> {
        val keyword = detectEmergencyKeyword(spokenText)
            ?: return mapOf(
                "emergency" to false,
                "text" to spokenText,
                "action" to "NONE"
            )

        Log.d(TAG, "Emergency keyword '$keyword' detected in: $spokenText")

        val location = getCurrentLocation(context)
        val lat = location?.latitude ?: 0.0
        val lng = location?.longitude ?: 0.0

        val sent = if (location != null) {
            sendEmergencyAlert(context, lat, lng, spokenText, keyword)
        } else {
            Log.w(TAG, "No location available, sending alert with 0,0")
            sendEmergencyAlert(context, 0.0, 0.0, spokenText, keyword)
        }

        return mapOf(
            "emergency" to true,
            "text" to spokenText,
            "keyword" to keyword,
            "latitude" to lat,
            "longitude" to lng,
            "alert_sent" to sent,
            "action" to "SEND_EMERGENCY_ALERT"
        )
    }
}
