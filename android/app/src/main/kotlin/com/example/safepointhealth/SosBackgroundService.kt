package com.example.safepointhealth

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.view.KeyEvent
import androidx.core.app.NotificationCompat

/**
 * Foreground Service untuk monitoring SOS trigger dari smartwatch
 * bahkan ketika app ditutup atau di background
 */
class SosBackgroundService : Service() {
    
    companion object {
        private const val TAG = "SosBackgroundService"
        private const val CHANNEL_ID = "sos_monitoring_channel"
        private const val NOTIFICATION_ID = 1001
        
        fun startService(context: Context) {
            val intent = Intent(context, SosBackgroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, SosBackgroundService::class.java)
            context.stopService(intent)
        }
    }
    
    private lateinit var bluetoothHelper: BluetoothHelper
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        
        bluetoothHelper = BluetoothHelper(this)
        
        // Create notification channel
        createNotificationChannel()
        
        // Start foreground service with notification
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started")
        
        // Check Xiaomi Watch connection
        checkWatchConnection()
        
        return START_STICKY // Restart service if killed
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "SOS Monitoring",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitoring SOS trigger dari smartwatch"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 
            0, 
            intent, 
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        val watchConnected = bluetoothHelper.isXiaomiWatchConnected()
        val watchName = bluetoothHelper.getXiaomiWatchName()
        
        val contentText = if (watchConnected && watchName != null) {
            "Terhubung dengan $watchName"
        } else {
            "Menunggu koneksi smartwatch"
        }
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("SafePoint SOS Aktif")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
    
    private fun checkWatchConnection() {
        val watchConnected = bluetoothHelper.isXiaomiWatchConnected()
        val watchName = bluetoothHelper.getXiaomiWatchName()
        
        if (watchConnected) {
            Log.d(TAG, "Xiaomi Watch connected: $watchName")
        } else {
            Log.d(TAG, "No Xiaomi Watch connected")
        }
    }
    
    /**
     * Handle key event dari sistem (termasuk dari smartwatch)
     * Catatan: Service tidak bisa langsung menerima key event
     * Key event harus diterima di MainActivity dan diteruskan ke Flutter
     */
    fun handleKeyEvent(keyCode: Int): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            if (bluetoothHelper.isXiaomiWatchConnected()) {
                Log.d(TAG, "Volume Up from smartwatch detected in service")
                
                // Launch MainActivity untuk trigger SOS
                val intent = Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("trigger_sos", true)
                }
                startActivity(intent)
                
                return true
            }
        }
        return false
    }
}
