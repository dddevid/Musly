package com.musly.musly

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

class AutoStartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.media.action.OPEN_AUDIO_EFFECT_CONTROL_SESSION" -> {
                val serviceIntent = Intent(context, MusicService::class.java)
                ContextCompat.startForegroundService(context, serviceIntent)
            }
        }
    }
}
