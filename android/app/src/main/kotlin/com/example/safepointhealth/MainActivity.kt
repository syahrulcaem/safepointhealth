package com.example.safepointhealth

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "safepoint/gps"
    private val LOCATION_PERMISSION_REQUEST_CODE = 1001
    private lateinit var locationManager: LocationManager
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentLocation" -> getCurrentLocation(result)
                "hasLocationPermission" -> result.success(hasLocationPermission())
                "requestLocationPermission" -> requestLocationPermission(result)
                "isGpsEnabled" -> result.success(isGpsEnabled())
                "openLocationSettings" -> {
                    openLocationSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
               ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestLocationPermission(result: MethodChannel.Result) {
        if (hasLocationPermission()) {
            result.success(true)
            return
        }

        pendingResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
            LOCATION_PERMISSION_REQUEST_CODE
        )
    }

    private fun isGpsEnabled(): Boolean {
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
               locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    private fun getCurrentLocation(result: MethodChannel.Result) {
        if (!hasLocationPermission()) {
            result.error("PERMISSION_DENIED", "Location permission not granted", null)
            return
        }

        if (!isGpsEnabled()) {
            result.error("GPS_DISABLED", "GPS is not enabled", null)
            return
        }

        try {
            // Coba ambil lokasi terakhir yang diketahui
            val lastKnownLocation = getLastKnownLocation()
            if (lastKnownLocation != null) {
                val locationMap = mapOf(
                    "latitude" to lastKnownLocation.latitude,
                    "longitude" to lastKnownLocation.longitude
                )
                result.success(locationMap)
                return
            }

            // Jika tidak ada lokasi terakhir, request lokasi baru
            requestNewLocation(result)
        } catch (e: SecurityException) {
            result.error("SECURITY_EXCEPTION", "Security exception: ${e.message}", null)
        } catch (e: Exception) {
            result.error("UNKNOWN_ERROR", "Unknown error: ${e.message}", null)
        }
    }

    private fun getLastKnownLocation(): Location? {
        if (!hasLocationPermission()) return null

        var bestLocation: Location? = null

        try {
            // Coba GPS provider dulu
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                val gpsLocation = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                if (gpsLocation != null) {
                    bestLocation = gpsLocation
                }
            }

            // Jika GPS tidak ada, coba network provider
            if (bestLocation == null && locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                val networkLocation = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
                if (networkLocation != null) {
                    bestLocation = networkLocation
                }
            }
        } catch (e: SecurityException) {
            // Handle security exception
        }

        return bestLocation
    }

    private fun requestNewLocation(result: MethodChannel.Result) {
        if (!hasLocationPermission()) {
            result.error("PERMISSION_DENIED", "Location permission not granted", null)
            return
        }

        val locationListener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                locationManager.removeUpdates(this)
                val locationMap = mapOf(
                    "latitude" to location.latitude,
                    "longitude" to location.longitude
                )
                result.success(locationMap)
            }

            override fun onProviderEnabled(provider: String) {}
            override fun onProviderDisabled(provider: String) {}
            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
        }

        try {
            // Coba GPS provider dulu
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    0L,
                    0f,
                    locationListener
                )
            }
            // Fallback ke network provider
            else if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    0L,
                    0f,
                    locationListener
                )
            } else {
                result.error("NO_PROVIDER", "No location provider available", null)
            }

            // Timeout setelah 10 detik
            android.os.Handler().postDelayed({
                locationManager.removeUpdates(locationListener)
                result.error("TIMEOUT", "Location request timed out", null)
            }, 10000)

        } catch (e: SecurityException) {
            result.error("SECURITY_EXCEPTION", "Security exception: ${e.message}", null)
        }
    }

    private fun openLocationSettings() {
        val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
        startActivity(intent)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == LOCATION_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingResult?.success(granted)
            pendingResult = null
        }
    }
}
