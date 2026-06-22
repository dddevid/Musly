package com.devid.musly

import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.AudioDeviceInfo
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Bridges Dolby Atmos device-capability queries to Dart.
 *
 * Many OEMs (Samsung, Xiaomi, OnePlus, OPPO, Sony …) ship a Dolby DAX
 * service package or expose a system setting. This plugin checks a
 * combination of package presence, audio-device channel counts and
 * system settings to give the app a best-effort answer.
 */
class DolbyAtmosPlugin private constructor(
    private val context: Context
) : MethodCallHandler {

    companion object {
        private const val TAG = "DolbyAtmosPlugin"
        private const val METHOD_CHANNEL = "com.devid.musly/dolbyatmos"

        @JvmStatic
        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val plugin = DolbyAtmosPlugin(context.applicationContext)
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            channel.setMethodCallHandler(plugin)
            Log.d(TAG, "DolbyAtmosPlugin registered")
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isSupported" -> result.success(isDolbyAtmosSupported())
            "isEnabled"   -> result.success(isDolbyAtmosEnabled())
            else -> result.notImplemented()
        }
    }

    /**
     * Returns true if any Dolby-specific package is installed or if the
     * device exposes multi-channel (>= 6) audio output profiles.
     */
    private fun isDolbyAtmosSupported(): Boolean {
        val pm = context.packageManager
        val dolbyPackages = listOf(
            "com.dolby.daxservice",
            "com.dolby.dax.apiUiStub",
            "com.dolby.dolbyAtmos",
            "com.dolby.atmos",
            "com.dolby.daxappui",
            "com.dolby.ds1appUI",
            "com.dolby.dax2",
            "com.motorola.dolby.dolbyui"
        )

        for (pkg in dolbyPackages) {
            try {
                @Suppress("DEPRECATION")
                pm.getPackageInfo(pkg, 0)
                Log.d(TAG, "Dolby package found: $pkg")
                return true
            } catch (_: PackageManager.NameNotFoundException) {
                // continue scanning
            }
        }

        // Fallback: inspect audio output devices for surround-capable profiles.
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        if (audioManager != null) {
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            for (device in devices) {
                val channelCounts = device.channelCounts
                if (channelCounts != null && channelCounts.any { it >= 6 }) {
                    Log.d(TAG, "Surround-capable device found: ${device.productName}")
                    return true
                }
                // TYPE_HDMI_ARC / TYPE_HDMI_EARC are strong Dolby Atmos indicators.
                if (device.type == AudioDeviceInfo.TYPE_HDMI_ARC ||
                    device.type == AudioDeviceInfo.TYPE_HDMI_EARC) {
                    Log.d(TAG, "HDMI ARC/EARC device found")
                    return true
                }
            }
        }

        Log.d(TAG, "Dolby Atmos does not appear to be supported on this device")
        return false
    }

    /**
     * Returns true if a known Dolby Atmos system setting is enabled.
     * Different OEMs store this in different settings keys.
     */
    private fun isDolbyAtmosEnabled(): Boolean {
        val globalKeys = listOf(
            "dolby_atmos_state",
            "dolby_atmos_on",
            "dax_state",
            "ds_state"
        )
        val systemKeys = listOf(
            "dolby_atmos_state",
            "dolby_atmos_on",
            "dax_state",
            "ds_state"
        )

        for (key in globalKeys) {
            try {
                val value = Settings.Global.getString(context.contentResolver, key)
                if (value == "1" || value == "true" || value == "on") {
                    Log.d(TAG, "Dolby enabled via Global.$key = $value")
                    return true
                }
            } catch (_: Exception) { }
        }

        for (key in systemKeys) {
            try {
                val value = Settings.System.getString(context.contentResolver, key)
                if (value == "1" || value == "true" || value == "on") {
                    Log.d(TAG, "Dolby enabled via System.$key = $value")
                    return true
                }
            } catch (_: Exception) { }
        }

        Log.d(TAG, "Dolby Atmos does not appear to be enabled")
        return false
    }
}
