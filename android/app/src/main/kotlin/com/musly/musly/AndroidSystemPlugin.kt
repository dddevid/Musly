package com.devid.musly

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Plugin for Android system integration
 * Handles system-wide media controls, audio focus, and media button handling
 */
object AndroidSystemPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    
    private const val TAG = "AndroidSystemPlugin"
    private const val METHOD_CHANNEL = "com.devid.musly/android_system"
    private const val EVENT_CHANNEL = "com.devid.musly/android_system_events"
    
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var hasAudioFocus = false
    
    private val handler = Handler(Looper.getMainLooper())
    
    private var showOnLockScreen = true
    private var handleAudioFocus = true
    private var handleMediaButtons = true
    private var showInQuickSettings = true
    private var colorizeNotification = true
    
    private val noisyReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == AudioManager.ACTION_AUDIO_BECOMING_NOISY) {
                sendEvent("becomingNoisy", null)
            }
        }
    }
    
    private val audioFocusListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                hasAudioFocus = true
                sendEvent("audioFocusGain", null)
            }
            AudioManager.AUDIOFOCUS_LOSS -> {
                hasAudioFocus = false
                sendEvent("audioFocusLoss", null)
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                sendEvent("audioFocusLossTransient", null)
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                sendEvent("audioFocusLossTransientCanDuck", null)
            }
        }
    }
    
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        audioManager = context?.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel?.setMethodCallHandler(this)
        
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
        
        Log.d(TAG, "AndroidSystemPlugin attached")
    }
    
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        dispose()
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        context = null
        audioManager = null
    }
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                showOnLockScreen = call.argument<Boolean>("showOnLockScreen") ?: true
                handleAudioFocus = call.argument<Boolean>("handleAudioFocus") ?: true
                handleMediaButtons = call.argument<Boolean>("handleMediaButtons") ?: true
                showInQuickSettings = call.argument<Boolean>("showInQuickSettings") ?: true
                colorizeNotification = call.argument<Boolean>("colorizeNotification") ?: true
                
                initialize()
                result.success(null)
            }
            "updatePlaybackState" -> {
                // Media session metadata/state is now handled by audio_service
                // (MuslyAudioHandler); nothing to do on this channel anymore.
                result.success(null)
            }
            "setNotificationColor" -> {
                val color = call.argument<Int>("color")
                result.success(null)
            }
            "requestAudioFocus" -> {
                result.success(requestAudioFocus())
            }
            "abandonAudioFocus" -> {
                abandonAudioFocus()
                result.success(null)
            }
            "updateSettings" -> {
                showOnLockScreen = call.argument<Boolean>("showOnLockScreen") ?: showOnLockScreen
                handleAudioFocus = call.argument<Boolean>("handleAudioFocus") ?: handleAudioFocus
                handleMediaButtons = call.argument<Boolean>("handleMediaButtons") ?: handleMediaButtons
                showInQuickSettings = call.argument<Boolean>("showInQuickSettings") ?: showInQuickSettings
                colorizeNotification = call.argument<Boolean>("colorizeNotification") ?: colorizeNotification
                result.success(null)
            }
            "getSystemInfo" -> {
                result.success(getSystemInfo())
            }
            "isSamsungDevice" -> {
                result.success(Build.MANUFACTURER.equals("samsung", ignoreCase = true))
            }
            "getAndroidSdkVersion" -> {
                result.success(Build.VERSION.SDK_INT)
            }
            "dispose" -> {
                dispose()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
    
    private fun initialize() {
        context?.let { ctx ->
            val filter = IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                ctx.registerReceiver(noisyReceiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                ctx.registerReceiver(noisyReceiver, filter)
            }
        }
        
        Log.d(TAG, "AndroidSystemPlugin initialized")
    }
    
    /**
     * Returns "granted", "delayed", or "failed". "delayed" means the OS will
     * asynchronously deliver AUDIOFOCUS_GAIN via [audioFocusListener] once the
     * current focus holder yields (common on Android Auto / automotive audio
     * routing, which is why [setAcceptsDelayedFocusGain] is set below).
     */
    private fun requestAudioFocus(): String {
        if (!handleAudioFocus) {
            hasAudioFocus = true
            return "granted"
        }

        val am = audioManager ?: return "failed"

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()

            audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(audioAttributes)
                .setAcceptsDelayedFocusGain(true)
                .setOnAudioFocusChangeListener(audioFocusListener, handler)
                .build()

            val result = am.requestAudioFocus(audioFocusRequest!!)
            when (result) {
                AudioManager.AUDIOFOCUS_REQUEST_GRANTED -> {
                    hasAudioFocus = true
                    "granted"
                }
                AudioManager.AUDIOFOCUS_REQUEST_DELAYED -> {
                    // Keep audioFocusRequest/listener registered — the deferred
                    // AUDIOFOCUS_GAIN will arrive later through audioFocusListener.
                    hasAudioFocus = false
                    "delayed"
                }
                else -> {
                    hasAudioFocus = false
                    "failed"
                }
            }
        } else {
            @Suppress("DEPRECATION")
            val result = am.requestAudioFocus(
                audioFocusListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN
            )
            hasAudioFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            if (hasAudioFocus) "granted" else "failed"
        }
    }
    
    private fun abandonAudioFocus() {
        val am = audioManager ?: return
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            am.abandonAudioFocus(audioFocusListener)
        }
        
        hasAudioFocus = false
    }
    
    private fun getSystemInfo(): Map<String, Any> {
        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "brand" to Build.BRAND,
            "sdkVersion" to Build.VERSION.SDK_INT,
            "release" to Build.VERSION.RELEASE,
            "isSamsung" to Build.MANUFACTURER.equals("samsung", ignoreCase = true),
            "hasAudioFocus" to hasAudioFocus
        )
    }
    
    private fun sendEvent(event: String, data: Map<String, Any>?) {
        val eventData = mutableMapOf<String, Any>("command" to event)
        data?.let { eventData.putAll(it) }
        
        handler.post {
            eventSink?.success(eventData)
        }
    }
    
    private fun dispose() {
        try {
            context?.unregisterReceiver(noisyReceiver)
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering receiver: ${e.message}")
        }
        
        abandonAudioFocus()
    }
}
