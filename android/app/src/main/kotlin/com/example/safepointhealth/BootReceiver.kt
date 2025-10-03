package com.example.safepointhealth

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Broadcast Receiver untuk restart SOS monitoring service
 * setelah device reboot
 */
class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
    }
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON" -> {
                Log.d(TAG, "Boot completed - Starting SOS monitoring service")
                
                // Check if user has enabled SOS monitoring (you can store this in SharedPreferences)
                val prefs = context.getSharedPreferences("safepoint_prefs", Context.MODE_PRIVATE)
                val sosEnabled = prefs.getBoolean("sos_monitoring_enabled", false)
                
                if (sosEnabled) {
                    SosBackgroundService.startService(context)
                    Log.d(TAG, "SOS monitoring service started after boot")
                } else {
                    Log.d(TAG, "SOS monitoring disabled - service not started")
                }
            }
        }
    }
}
