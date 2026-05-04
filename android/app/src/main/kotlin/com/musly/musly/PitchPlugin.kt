package com.devid.musly

import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Bridges pitch changes to the underlying ExoPlayer instance used by just_audio.
 *
 * just_audio does not expose setPitch, but ExoPlayer's PlaybackParameters accepts
 * both speed and pitch. This plugin uses reflection to find the internal ExoPlayer
 * and call setPlaybackParameters with the requested pitch.
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

    private var cachedSpeed: Float = 1.0f
    private var cachedPitch: Float = 1.0f

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setPitch" -> {
                val pitch = (call.argument<Double>("pitch") ?: 1.0).toFloat()
                val speed = (call.argument<Double>("speed") ?: cachedSpeed).toFloat()
                cachedPitch = pitch
                cachedSpeed = speed
                val success = applyPlaybackParameters(speed, pitch)
                result.success(mapOf("success" to success))
            }
            "setSpeed" -> {
                val speed = (call.argument<Double>("speed") ?: 1.0).toFloat()
                val pitch = (call.argument<Double>("pitch") ?: cachedPitch).toFloat()
                cachedSpeed = speed
                cachedPitch = pitch
                val success = applyPlaybackParameters(speed, pitch)
                result.success(mapOf("success" to success))
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Uses reflection to find the ExoPlayer instance inside just_audio and
     * apply PlaybackParameters(speed, pitch).
     */
    private fun applyPlaybackParameters(speed: Float, pitch: Float): Boolean {
        return try {
            // 1. Locate just_audio's MethodCallHandlerImpl which holds the player map
            val handlerClass = Class.forName("com.ryanheise.just_audio.MethodCallHandlerImpl")
            val instanceField = handlerClass.getDeclaredField("instance")
            instanceField.isAccessible = true
            val handlerInstance = instanceField.get(null) ?: return false

            // 2. Get the players map (Long -> AudioPlayer)
            val playersField = handlerClass.getDeclaredField("players")
            playersField.isAccessible = true
            @Suppress("UNCHECKED_CAST")
            val players = playersField.get(handlerInstance) as? Map<Long, Any> ?: return false

            if (players.isEmpty()) {
                Log.w(TAG, "No just_audio players found yet")
                return false
            }

            // 3. Take the first (and usually only) player
            val audioPlayer = players.values.first()
            val playerField = audioPlayer.javaClass.getDeclaredField("player")
            playerField.isAccessible = true
            val exoPlayer = playerField.get(audioPlayer)

            // 4. Build PlaybackParameters(speed, pitch) via reflection
            val ppClass = Class.forName("com.google.android.exoplayer2.PlaybackParameters")
            val constructor = ppClass.getConstructor(Float::class.java, Float::class.java)
            val params = constructor.newInstance(speed, pitch)

            // 5. Call ExoPlayer.setPlaybackParameters(params)
            val setPPMethod = exoPlayer.javaClass.getMethod("setPlaybackParameters", ppClass)
            setPPMethod.invoke(exoPlayer, params)

            Log.d(TAG, "Applied PlaybackParameters(speed=$speed, pitch=$pitch)")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to apply pitch: ${e.message}", e)
            false
        }
    }
}
