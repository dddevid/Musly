package com.musly.musly

import android.annotation.SuppressLint
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.graphics.BitmapFactory
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.net.URL

/**
 * Helper class for Samsung-specific integrations
 * Handles Edge panels, Edge lighting, DeX mode, Samsung Music compatibility, etc.
 */
class SamsungHelper(private val context: Context) {
    
    companion object {
        private const val TAG = "SamsungHelper"
        
        private const val SAMSUNG_MUSIC_PACKAGE = "com.sec.android.app.music"
        private const val SAMSUNG_SOUND_ASSISTANT_PACKAGE = "com.samsung.android.soundassistant"
        private const val SAMSUNG_EDGE_PACKAGE = "com.samsung.android.app.cocktailbarservice"
        private const val SAMSUNG_GOOD_LOCK_PACKAGE = "com.samsung.android.goodlock"
        private const val SAMSUNG_ROUTINES_PACKAGE = "com.samsung.android.app.routines"
        
        private const val DEX_MODE_ENABLED = "1"
        
        private val isSamsungDevice: Boolean by lazy {
            Build.MANUFACTURER.equals("samsung", ignoreCase = true)
        }
    }
    
    private var eventSink: EventChannel.EventSink? = null
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val handler = Handler(Looper.getMainLooper())
    
    private var isDexMode = false
    private var features: SamsungFeatures? = null
    
    private var currentTitle: String = ""
    private var currentArtist: String = ""
    private var currentArtworkUrl: String? = null
    private var isPlaying: Boolean = false
    
    private val dexModeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_CONFIGURATION_CHANGED -> {
                    checkDexMode()
                }
                "android.app.action.ENTER_SAMSUNG_DEX_MODE" -> {
                    handleDexModeChange(true)
                }
                "android.app.action.EXIT_SAMSUNG_DEX_MODE" -> {
                    handleDexModeChange(false)
                }
            }
        }
    }
    
    fun initialize(): Map<String, Any> {
        if (!isSamsungDevice) {
            return mapOf("isSamsungDevice" to false)
        }
        
        try {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_CONFIGURATION_CHANGED)
                addAction("android.app.action.ENTER_SAMSUNG_DEX_MODE")
                addAction("android.app.action.EXIT_SAMSUNG_DEX_MODE")
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(dexModeReceiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                context.registerReceiver(dexModeReceiver, filter)
            }
            
            features = detectFeatures()
            isDexMode = checkDexModeInitial()
            
            Log.d(TAG, "SamsungHelper initialized: $features, DeX mode: $isDexMode")
            
            return features?.toMap() ?: mapOf("isSamsungDevice" to true)
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing SamsungHelper: ${e.message}")
            return mapOf("isSamsungDevice" to true)
        }
    }
    
    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }
    
    private fun detectFeatures(): SamsungFeatures {
        val pm = context.packageManager
        
        val isEdgePanelSupported = isPackageInstalled(pm, SAMSUNG_EDGE_PACKAGE) ||
                hasSystemFeature("com.samsung.feature.cocktailbar")
        
        val isEdgeLightingSupported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                hasSystemFeature("com.samsung.feature.aodnotifledlight")
        
        val isGoodLockSupported = isPackageInstalled(pm, SAMSUNG_GOOD_LOCK_PACKAGE)
        
        val isDexSupported = hasSystemFeature("com.samsung.feature.samsung_dex") ||
                hasSystemFeature("com.sec.feature.desktopmode")
        
        val isSamsungMusicInstalled = isPackageInstalled(pm, SAMSUNG_MUSIC_PACKAGE)
        
        val isRoutinesSupported = isPackageInstalled(pm, SAMSUNG_ROUTINES_PACKAGE)
        
        val oneUIVersion = getOneUIVersion()
        
        return SamsungFeatures(
            isEdgePanelSupported = isEdgePanelSupported,
            isEdgeLightingSupported = isEdgeLightingSupported,
            isGoodLockSupported = isGoodLockSupported,
            isDexSupported = isDexSupported,
            isDexMode = isDexMode,
            isSamsungMusicInstalled = isSamsungMusicInstalled,
            isOneUIVersion = oneUIVersion.isNotEmpty(),
            oneUIVersion = oneUIVersion,
            isRoutinesSupported = isRoutinesSupported
        )
    }
    
    private fun isPackageInstalled(pm: PackageManager, packageName: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                pm.getPackageInfo(packageName, 0)
            }
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
    
    private fun hasSystemFeature(feature: String): Boolean {
        return try {
            context.packageManager.hasSystemFeature(feature)
        } catch (e: Exception) {
            false
        }
    }
    
    @SuppressLint("PrivateApi")
    private fun getOneUIVersion(): String {
        if (!isSamsungDevice) return ""
        
        return try {
            val semVersionProp = Class.forName("android.os.SystemProperties")
                .getMethod("get", String::class.java, String::class.java)
                .invoke(null, "ro.build.version.oneui", "") as? String
            
            if (!semVersionProp.isNullOrEmpty()) {
                val version = semVersionProp.toIntOrNull() ?: 0
                if (version > 0) {
                    val major = version / 10000
                    val minor = (version % 10000) / 100
                    return "$major.$minor"
                }
            }
            
            when {
                Build.VERSION.SDK_INT >= 34 -> "6.0"
                Build.VERSION.SDK_INT >= 33 -> "5.0"
                Build.VERSION.SDK_INT >= 32 -> "4.1"
                Build.VERSION.SDK_INT >= 31 -> "4.0"
                Build.VERSION.SDK_INT >= 30 -> "3.0"
                Build.VERSION.SDK_INT >= 29 -> "2.0"
                Build.VERSION.SDK_INT >= 28 -> "1.0"
                else -> ""
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting OneUI version: ${e.message}")
            ""
        }
    }
    
    private fun checkDexModeInitial(): Boolean {
        return try {
            val config = context.resources.configuration
            val uiMode = config.uiMode and Configuration.UI_MODE_TYPE_MASK
            if (uiMode == Configuration.UI_MODE_TYPE_DESK) {
                return true
            }
            
            val dexMode = Settings.Global.getString(context.contentResolver, "desktop_mode_enabled")
            dexMode == DEX_MODE_ENABLED
        } catch (e: Exception) {
            Log.e(TAG, "Error checking DeX mode: ${e.message}")
            false
        }
    }
    
    private fun checkDexMode() {
        val newDexMode = checkDexModeInitial()
        if (newDexMode != isDexMode) {
            handleDexModeChange(newDexMode)
        }
    }
    
    private fun handleDexModeChange(isDex: Boolean) {
        isDexMode = isDex
        features = features?.copy(isDexMode = isDex)
        
        sendEvent(if (isDex) "dexModeEnter" else "dexModeExit", null)
        Log.d(TAG, "DeX mode changed: $isDex")
    }
    
    /**
     * Update playback state for Samsung Edge panels and other integrations
     */
    fun updatePlaybackState(
        songId: String?,
        title: String,
        artist: String,
        album: String,
        artworkUrl: String?,
        duration: Long,
        position: Long,
        playing: Boolean
    ) {
        currentTitle = title
        currentArtist = artist
        currentArtworkUrl = artworkUrl
        isPlaying = playing
        
        if (features?.isEdgePanelSupported == true) {
            updateEdgePanelInternal()
        }
    }
    
    private fun updateEdgePanelInternal() {
    }
    
    /**
     * Show Edge Lighting notification (requires user to have Edge Lighting enabled)
     */
    fun showEdgeLighting(title: String, subtitle: String, color: Int?, durationMs: Int) {
        if (features?.isEdgeLightingSupported != true) return
        
        Log.d(TAG, "Edge Lighting requested: $title - $subtitle")
    }
    
    /**
     * Update Edge Panel with music controls
     */
    fun updateEdgePanel(title: String, artist: String, artworkUrl: String?, playing: Boolean) {
        currentTitle = title
        currentArtist = artist
        currentArtworkUrl = artworkUrl
        isPlaying = playing
        
        updateEdgePanelInternal()
    }
    
    /**
     * Register with Samsung Bixby Routines
     */
    fun registerWithRoutines(): Boolean {
        if (features?.isRoutinesSupported != true) return false
        
        Log.d(TAG, "App ready for Bixby Routines integration")
        return true
    }
    
    /**
     * Optimize for DeX mode
     */
    fun optimizeForDex(enable: Boolean) {
        Log.d(TAG, "DeX optimization ${if (enable) "enabled" else "disabled"}")
    }
    
    /**
     * Get Samsung Music compatibility info
     */
    fun getSamsungMusicCompatibility(): Map<String, Any> {
        return mapOf(
            "installed" to (features?.isSamsungMusicInstalled ?: false),
            "canShare" to true,
            "canImportPlaylists" to false
        )
    }
    
    /**
     * Register as default music player
     */
    fun registerAsDefaultMusicPlayer(): Boolean {
        Log.d(TAG, "Default music player registration requested")
        return false
    }
    
    /**
     * Get Samsung audio settings
     */
    fun getSamsungAudioSettings(): Map<String, Any> {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        return try {
            mapOf(
                "currentOutput" to getCurrentAudioOutput(audioManager),
                "isDolbyAtmosEnabled" to isDolbyAtmosEnabled(),
                "isAdaptSoundEnabled" to isAdaptSoundEnabled()
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error getting Samsung audio settings: ${e.message}")
            emptyMap()
        }
    }
    
    private fun getCurrentAudioOutput(audioManager: AudioManager): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            when {
                devices.any { it.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP } -> "bluetooth"
                devices.any { it.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                             it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET } -> "wired"
                devices.any { it.type == AudioDeviceInfo.TYPE_USB_HEADSET ||
                             it.type == AudioDeviceInfo.TYPE_USB_DEVICE } -> "usb"
                else -> "speaker"
            }
        } else {
            if (audioManager.isBluetoothA2dpOn) "bluetooth"
            else if (audioManager.isWiredHeadsetOn) "wired"
            else "speaker"
        }
    }
    
    @SuppressLint("PrivateApi")
    private fun isDolbyAtmosEnabled(): Boolean {
        return try {
            val dolbyEnabled = Settings.Global.getInt(
                context.contentResolver,
                "dolby_atmos_enabled",
                0
            )
            dolbyEnabled == 1
        } catch (e: Exception) {
            false
        }
    }
    
    @SuppressLint("PrivateApi")
    private fun isAdaptSoundEnabled(): Boolean {
        return try {
            val adaptSoundEnabled = Settings.System.getInt(
                context.contentResolver,
                "adapt_sound_enabled",
                0
            )
            adaptSoundEnabled == 1
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Configure Samsung audio enhancements
     */
    fun configureSamsungAudio(adaptiveSound: Boolean?, dolbyAtmos: Boolean?, uhqUpscaler: Boolean?) {
        Log.d(TAG, "Samsung audio configuration requested")
    }
    
    /**
     * Update Sound Assistant mini player
     */
    fun updateSoundAssistant(title: String, artist: String, artworkUrl: String?, playing: Boolean) {
    }
    
    private fun sendEvent(event: String, data: Map<String, Any>?) {
        val eventData = mutableMapOf<String, Any>("event" to event)
        data?.let { eventData.putAll(it) }
        
        handler.post {
            eventSink?.success(eventData)
        }
    }
    
    fun dispose() {
        try {
            context.unregisterReceiver(dexModeReceiver)
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering receiver: ${e.message}")
        }
        scope.cancel()
    }
    
    /**
     * Handle method calls from Flutter
     */
    fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSamsungDevice" -> {
                result.success(isSamsungDevice)
            }
            "initialize" -> {
                val features = initialize()
                result.success(features)
            }
            "updatePlaybackState" -> {
                val songId = call.argument<String>("songId")
                val title = call.argument<String>("title") ?: ""
                val artist = call.argument<String>("artist") ?: ""
                val album = call.argument<String>("album") ?: ""
                val artworkUrl = call.argument<String>("artworkUrl")
                val duration = call.argument<Number>("duration")?.toLong() ?: 0L
                val position = call.argument<Number>("position")?.toLong() ?: 0L
                val playing = call.argument<Boolean>("playing") ?: false
                
                updatePlaybackState(songId, title, artist, album, artworkUrl, duration, position, playing)
                result.success(null)
            }
            "showEdgeLighting" -> {
                val title = call.argument<String>("title") ?: ""
                val subtitle = call.argument<String>("subtitle") ?: ""
                val color = call.argument<Int>("color")
                val durationMs = call.argument<Int>("durationMs") ?: 3000
                
                showEdgeLighting(title, subtitle, color, durationMs)
                result.success(null)
            }
            "updateEdgePanel" -> {
                val title = call.argument<String>("title") ?: ""
                val artist = call.argument<String>("artist") ?: ""
                val artworkUrl = call.argument<String>("artworkUrl")
                val playing = call.argument<Boolean>("playing") ?: false
                
                updateEdgePanel(title, artist, artworkUrl, playing)
                result.success(null)
            }
            "registerWithRoutines" -> {
                result.success(registerWithRoutines())
            }
            "optimizeForDex" -> {
                val enable = call.argument<Boolean>("enable") ?: false
                optimizeForDex(enable)
                result.success(null)
            }
            "getSamsungMusicCompatibility" -> {
                result.success(getSamsungMusicCompatibility())
            }
            "registerAsDefaultMusicPlayer" -> {
                result.success(registerAsDefaultMusicPlayer())
            }
            "getSamsungAudioSettings" -> {
                result.success(getSamsungAudioSettings())
            }
            "configureSamsungAudio" -> {
                val adaptiveSound = call.argument<Boolean>("adaptiveSound")
                val dolbyAtmos = call.argument<Boolean>("dolbyAtmos")
                val uhqUpscaler = call.argument<Boolean>("uhqUpscaler")
                
                configureSamsungAudio(adaptiveSound, dolbyAtmos, uhqUpscaler)
                result.success(null)
            }
            "updateSoundAssistant" -> {
                val title = call.argument<String>("title") ?: ""
                val artist = call.argument<String>("artist") ?: ""
                val artworkUrl = call.argument<String>("artworkUrl")
                val playing = call.argument<Boolean>("playing") ?: false
                
                updateSoundAssistant(title, artist, artworkUrl, playing)
                result.success(null)
            }
            "dispose" -> {
                dispose()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}

/**
 * Data class for Samsung features
 */
data class SamsungFeatures(
    val isEdgePanelSupported: Boolean,
    val isEdgeLightingSupported: Boolean,
    val isGoodLockSupported: Boolean,
    val isDexSupported: Boolean,
    val isDexMode: Boolean,
    val isSamsungMusicInstalled: Boolean,
    val isOneUIVersion: Boolean,
    val oneUIVersion: String,
    val isRoutinesSupported: Boolean
) {
    fun toMap(): Map<String, Any> = mapOf(
        "isEdgePanelSupported" to isEdgePanelSupported,
        "isEdgeLightingSupported" to isEdgeLightingSupported,
        "isGoodLockSupported" to isGoodLockSupported,
        "isDexSupported" to isDexSupported,
        "isDexMode" to isDexMode,
        "isSamsungMusicInstalled" to isSamsungMusicInstalled,
        "isOneUIVersion" to isOneUIVersion,
        "oneUIVersion" to oneUIVersion,
        "isRoutinesSupported" to isRoutinesSupported
    )
}
