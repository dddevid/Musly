package com.devid.musly

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import android.util.Log

/**
 * Plugin to handle synchronized lyrics updates for Android media notification
 * and communication with Flutter lyrics service
 */
class LyricsPlugin : MethodCallHandler, EventChannel.StreamHandler {
    
    companion object {
        private const val TAG = "LyricsPlugin"
        private const val METHOD_CHANNEL = "com.devid.musly/lyrics"
        private const val EVENT_CHANNEL = "com.devid.musly/lyrics_updates"
        
        @JvmStatic
        fun registerWith(flutterEngine: FlutterEngine) {
            val plugin = LyricsPlugin()
            
            val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            methodChannel.setMethodCallHandler(plugin)
            
            val eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            eventChannel.setStreamHandler(plugin)
        }
    }
    
    private var eventSink: EventChannel.EventSink? = null
    private var currentLyricsLine: String? = null
    private var hasLyrics: Boolean = false
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                initialize(result)
            }
            "lyricsAvailable" -> {
                hasLyrics = call.argument<Boolean>("hasLyrics") ?: false
                Log.d(TAG, "Lyrics available: $hasLyrics")
                result.success(mapOf("received" to true))
            }
            "updateLyrics" -> {
                val line = call.argument<String>("currentLine")
                updateLyrics(line)
                result.success(mapOf("updated" to true))
            }
            "clearLyrics" -> {
                clearLyrics()
                result.success(mapOf("cleared" to true))
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun initialize(result: Result) {
        Log.d(TAG, "LyricsPlugin initialized")
        result.success(mapOf("initialized" to true))
    }
    
    private fun updateLyrics(line: String?) {
        if (line == null || line == currentLyricsLine) return

        currentLyricsLine = line

        // Notify Flutter listeners if any
        eventSink?.success(mapOf(
            "event" to "lyricsUpdated",
            "currentLine" to line,
            "timestamp" to System.currentTimeMillis()
        ))

        Log.d(TAG, "Updated lyrics: $line")
    }

    private fun clearLyrics() {
        currentLyricsLine = null
        hasLyrics = false
        Log.d(TAG, "Cleared lyrics")
    }
    
    // Get current lyrics line for external use
    fun getCurrentLyricsLine(): String? = currentLyricsLine
    
    // EventChannel.StreamHandler
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }
    
    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
