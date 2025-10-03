package com.example.safepointhealth

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.MethodChannel

class BluetoothHelper(private val context: Context) {
    
    private val bluetoothManager: BluetoothManager? = 
        context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager?.adapter
    
    /**
     * Check if Bluetooth is enabled
     */
    fun isBluetoothEnabled(): Boolean {
        return bluetoothAdapter?.isEnabled == true
    }
    
    /**
     * Check if Bluetooth permission is granted (Android 12+)
     */
    fun hasBluetoothPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            // Below Android 12, no special permission needed
            true
        }
    }
    
    /**
     * Check if Xiaomi Watch is connected
     * Returns true if any connected device name contains "Xiaomi Watch"
     */
    fun isXiaomiWatchConnected(): Boolean {
        if (!isBluetoothEnabled()) {
            return false
        }
        
        if (!hasBluetoothPermission()) {
            return false
        }
        
        return try {
            val pairedDevices: Set<BluetoothDevice>? = bluetoothAdapter?.bondedDevices
            
            pairedDevices?.any { device ->
                val deviceName = device.name ?: ""
                deviceName.contains("Xiaomi Watch", ignoreCase = true) ||
                deviceName.contains("Mi Watch", ignoreCase = true) ||
                deviceName.contains("Redmi Watch", ignoreCase = true)
            } ?: false
            
        } catch (e: SecurityException) {
            // Permission denied
            false
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
    
    /**
     * Get connected Xiaomi Watch name (if any)
     */
    fun getXiaomiWatchName(): String? {
        if (!isBluetoothEnabled() || !hasBluetoothPermission()) {
            return null
        }
        
        return try {
            val pairedDevices: Set<BluetoothDevice>? = bluetoothAdapter?.bondedDevices
            
            pairedDevices?.firstOrNull { device ->
                val deviceName = device.name ?: ""
                deviceName.contains("Xiaomi Watch", ignoreCase = true) ||
                deviceName.contains("Mi Watch", ignoreCase = true) ||
                deviceName.contains("Redmi Watch", ignoreCase = true)
            }?.name
            
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
    
    /**
     * Get Bluetooth status as Map for Flutter MethodChannel
     */
    fun getBluetoothStatus(): Map<String, Any> {
        val hasPermission = hasBluetoothPermission()
        val isEnabled = isBluetoothEnabled()
        val watchConnected = isXiaomiWatchConnected()
        val watchName = getXiaomiWatchName()
        
        return mapOf(
            "hasPermission" to hasPermission,
            "isEnabled" to isEnabled,
            "watchConnected" to watchConnected,
            "watchName" to (watchName ?: ""),
            "timestamp" to System.currentTimeMillis()
        )
    }
    
    /**
     * Send Bluetooth status to Flutter via MethodChannel
     */
    fun sendStatusToFlutter(channel: MethodChannel) {
        val status = getBluetoothStatus()
        channel.invokeMethod("onBluetoothStatus", status)
    }
}
