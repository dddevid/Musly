package com.devid.musly

import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Bridges speed+pitch changes to the underlying ExoPlayer used by just_audio.
 *
 * just_audio does not expose setPitch, but ExoPlayer's PlaybackParameters accepts
 * both speed and pitch. This plugin uses reflection to find the internal ExoPlayer
 * and call setPlaybackParameters with both values at once, avoiding race
 * conditions where just_audio's setSpeed resets pitch to 1.0.
 */
class PitchPlugin : MethodCallHandler {

    companion object {
        private const val TAG = "PitchPlugin"
        private const val METHOD_CHANNEL = "com.devid.musly/pitch"

        @JvmStatic
        fun registerWith(flutterEngine: FlutterEngine) {
            val plugin = PitchPlugin()
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            channel.setMethodCallHandler(plugin)
            Log.d(TAG, "PitchPlugin registered")
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setPlaybackParameters" -> {
                val speed = (call.argument<Double>("speed") ?: 1.0).toFloat()
                val pitch = (call.argument<Double>("pitch") ?: 1.0).toFloat()
                val success = applyPlaybackParameters(speed, pitch)
                result.success(mapOf("success" to success))
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Uses reflection to find the ExoPlayer instance inside just_audio and
     * apply PlaybackParameters(speed, pitch) atomically.
     */
    private fun applyPlaybackParameters(speed: Float, pitch: Float): Boolean {
        return try {
            val handlerClass = Class.forName("com.ryanheise.just_audio.MethodCallHandlerImpl")
            val instanceField = handlerClass.getDeclaredField("instance")
            instanceField.isAccessible = true
            val handlerInstance = instanceField.get(null) ?: return false

            val playersField = handlerClass.getDeclaredField("players")
            playersField.isAccessible = true
            @Suppress("UNCHECKED_CAST")
            val players = playersField.get(handlerInstance) as? Map<Long, Any> ?: return false

            if (players.isEmpty()) {
                Log.w(TAG, "No just_audio players found yet")
                return false
            }

            val audioPlayer = players.values.first()

            // Find the ExoPlayer field by type (more robust than by name)
            val exoPlayer = findExoPlayer(audioPlayer) ?: return false

            val ppClass = Class.forName("com.google.android.exoplayer2.PlaybackParameters")
            val constructor = ppClass.getConstructor(Float::class.java, Float::class.java)
            val params = constructor.newInstance(speed, pitch)

            val setPPMethod = exoPlayer.javaClass.getMethod("setPlaybackParameters", ppClass)
            setPPMethod.invoke(exoPlayer, params)

            Log.d(TAG, "Applied PlaybackParameters(speed=$speed, pitch=$pitch)")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to apply playback parameters: ${e.message}", e)
            false
        }
    }

    private fun findExoPlayer(audioPlayer: Any): Any? {
        try {
            // Try known field name first
            val playerField = audioPlayer.javaClass.getDeclaredField("player")
            playerField.isAccessible = true
            val candidate = playerField.get(audioPlayer)
            if (isExoPlayer(candidate)) return candidate
        } catch (_: NoSuchFieldException) {
            // fallback: scan all fields by type
        }

        // Scan all declared fields for an ExoPlayer instance
        for (field in audioPlayer.javaClass.declaredFields) {
            field.isAccessible = true
            val candidate = field.get(audioPlayer)
            if (isExoPlayer(candidate)) {
                return candidate
            }
        }
        return null
    }

    private fun isExoPlayer(candidate: Any?): Boolean {
        if (candidate == null) return false
        val clazz = candidate.javaClass
        return clazz.name.contains("ExoPlayer") ||
               clazz.interfaces.any { it.name.contains("ExoPlayer") }
    }
}
