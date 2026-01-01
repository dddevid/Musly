package com.devid.musly

import android.annotation.SuppressLint
import android.bluetooth.BluetoothA2dp
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.net.URL

/**
 * Helper class for Bluetooth A2DP and AVRCP integration
 * Handles metadata transmission to Bluetooth audio devices
 */
class BluetoothMediaHelper(private val context: Context) {
    
    companion object {
        private const val TAG = "BluetoothMediaHelper"
        
        const val AVRCP_VERSION_1_0 = 10
        const val AVRCP_VERSION_1_3 = 13
        const val AVRCP_VERSION_1_4 = 14
        const val AVRCP_VERSION_1_5 = 15
        const val AVRCP_VERSION_1_6 = 16
    }
    
    private var eventSink: EventChannel.EventSink? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var a2dpProxy: BluetoothA2dp? = null
    private var isA2dpConnected = false
    
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val handler = Handler(Looper.getMainLooper())
    
    private var currentTitle: String = ""
    private var currentArtist: String = ""
    private var currentAlbum: String = ""
    private var currentDuration: Long = 0
    private var currentPosition: Long = 0
    private var currentArtwork: Bitmap? = null
    private var isPlaying: Boolean = false
    
    private val connectedDevices = mutableListOf<BluetoothDeviceInfo>()
    
    private val bluetoothReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                BluetoothDevice.ACTION_ACL_CONNECTED -> {
                    val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    }
                    device?.let { handleDeviceConnected(it) }
                }
                BluetoothDevice.ACTION_ACL_DISCONNECTED -> {
                    val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    }
                    device?.let { handleDeviceDisconnected(it) }
                }
                BluetoothA2dp.ACTION_CONNECTION_STATE_CHANGED -> {
                    val state = intent.getIntExtra(BluetoothProfile.EXTRA_STATE, BluetoothProfile.STATE_DISCONNECTED)
                    isA2dpConnected = state == BluetoothProfile.STATE_CONNECTED
                    Log.d(TAG, "A2DP connection state changed: $isA2dpConnected")
                    refreshConnectedDevices()
                }
                AudioManager.ACTION_AUDIO_BECOMING_NOISY -> {
                    sendEvent("becomingNoisy", null)
                }
            }
        }
    }
    
    private val a2dpListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile?) {
            if (profile == BluetoothProfile.A2DP) {
                a2dpProxy = proxy as? BluetoothA2dp
                Log.d(TAG, "A2DP proxy connected")
                refreshConnectedDevices()
            }
        }
        
        override fun onServiceDisconnected(profile: Int) {
            if (profile == BluetoothProfile.A2DP) {
                a2dpProxy = null
                Log.d(TAG, "A2DP proxy disconnected")
            }
        }
    }
    
    fun initialize() {
        try {
            val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            bluetoothAdapter = bluetoothManager?.adapter ?: BluetoothAdapter.getDefaultAdapter()
            
            val filter = IntentFilter().apply {
                addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
                addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
                addAction(BluetoothA2dp.ACTION_CONNECTION_STATE_CHANGED)
                addAction(AudioManager.ACTION_AUDIO_BECOMING_NOISY)
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(bluetoothReceiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                context.registerReceiver(bluetoothReceiver, filter)
            }
            
            bluetoothAdapter?.getProfileProxy(context, a2dpListener, BluetoothProfile.A2DP)
            
            Log.d(TAG, "BluetoothMediaHelper initialized")
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing BluetoothMediaHelper: ${e.message}")
        }
    }
    
    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }
    
    @SuppressLint("MissingPermission")
    fun refreshConnectedDevices() {
        connectedDevices.clear()
        
        try {
            a2dpProxy?.connectedDevices?.forEach { device ->
                val info = getDeviceInfo(device)
                connectedDevices.add(info)
                Log.d(TAG, "Found connected A2DP device: ${info.name}")
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Missing Bluetooth permission: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Error getting connected devices: ${e.message}")
        }
    }
    
    @SuppressLint("MissingPermission")
    private fun getDeviceInfo(device: BluetoothDevice): BluetoothDeviceInfo {
        val name = try {
            device.name ?: "Unknown Device"
        } catch (e: SecurityException) {
            "Unknown Device"
        }
        
        val avrcpVersion = getAvrcpVersion(device)
        val supportsAlbumArt = avrcpVersion >= AVRCP_VERSION_1_4
        val supportsBrowsing = avrcpVersion >= AVRCP_VERSION_1_4
        
        return BluetoothDeviceInfo(
            address = device.address,
            name = name,
            isConnected = true,
            supportsAvrcp = true,
            avrcpVersion = avrcpVersion,
            supportsAlbumArt = supportsAlbumArt,
            supportsBrowsing = supportsBrowsing
        )
    }
    
    @SuppressLint("MissingPermission")
    private fun getAvrcpVersion(device: BluetoothDevice): Int {
        return try {
            val deviceClass = device.bluetoothClass
            when {
                deviceClass == null -> AVRCP_VERSION_1_3
                deviceClass.majorDeviceClass == android.bluetooth.BluetoothClass.Device.Major.AUDIO_VIDEO -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        AVRCP_VERSION_1_6
                    } else {
                        AVRCP_VERSION_1_4
                    }
                }
                else -> AVRCP_VERSION_1_3
            }
        } catch (e: Exception) {
            AVRCP_VERSION_1_3
        }
    }
    
    @SuppressLint("MissingPermission")
    private fun handleDeviceConnected(device: BluetoothDevice) {
        Log.d(TAG, "Bluetooth device connected: ${device.address}")
        
        handler.postDelayed({
            refreshConnectedDevices()
            
            val info = connectedDevices.find { it.address == device.address }
            if (info != null) {
                sendEvent("deviceConnected", mapOf(
                    "device" to info.toMap()
                ))
            }
        }, 1000)
    }
    
    @SuppressLint("MissingPermission")
    private fun handleDeviceDisconnected(device: BluetoothDevice) {
        Log.d(TAG, "Bluetooth device disconnected: ${device.address}")
        
        val info = connectedDevices.find { it.address == device.address }
        if (info != null) {
            connectedDevices.removeIf { it.address == device.address }
            sendEvent("deviceDisconnected", mapOf(
                "device" to info.toMap()
            ))
        }
    }
    
    /**
     * Update the playback metadata
     * This will be transmitted to connected Bluetooth devices via AVRCP
     */
    fun updatePlaybackState(
        songId: String?,
        title: String,
        artist: String,
        album: String,
        artworkUrl: String?,
        duration: Long,
        position: Long,
        playing: Boolean,
        trackNumber: Int?,
        totalTracks: Int?,
        genre: String?,
        year: Int?
    ) {
        currentTitle = title
        currentArtist = artist
        currentAlbum = album
        currentDuration = duration
        currentPosition = position
        isPlaying = playing
        
        MusicService.getInstance()?.apply {
            updatePlaybackState(songId, title, artist, album, artworkUrl, duration, position, playing)
        }
        
        artworkUrl?.let { url ->
            loadArtworkAsync(url)
        }
    }
    
    private fun loadArtworkAsync(url: String) {
        scope.launch(Dispatchers.IO) {
            try {
                val bitmap = BitmapFactory.decodeStream(URL(url).openStream())
                withContext(Dispatchers.Main) {
                    currentArtwork = bitmap
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error loading artwork for Bluetooth: ${e.message}")
            }
        }
    }
    
    /**
     * Update just the position (for progress updates)
     */
    fun updatePosition(position: Long) {
        currentPosition = position
    }
    
    /**
     * Get list of connected devices
     */
    fun getConnectedDevices(): List<Map<String, Any>> {
        return connectedDevices.map { it.toMap() }
    }
    
    /**
     * Check if A2DP is connected
     */
    fun isA2dpConnected(): Boolean {
        return isA2dpConnected && connectedDevices.isNotEmpty()
    }
    
    /**
     * Set volume on connected Bluetooth device (if absolute volume is supported)
     */
    fun setVolume(volume: Float) {
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            val targetVolume = (volume * maxVolume).toInt().coerceIn(0, maxVolume)
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, targetVolume, 0)
        } catch (e: Exception) {
            Log.e(TAG, "Error setting Bluetooth volume: ${e.message}")
        }
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
            context.unregisterReceiver(bluetoothReceiver)
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering receiver: ${e.message}")
        }
        
        bluetoothAdapter?.closeProfileProxy(BluetoothProfile.A2DP, a2dpProxy)
        a2dpProxy = null
        scope.cancel()
        connectedDevices.clear()
    }
    
    /**
     * Handle method calls from Flutter
     */
    fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                initialize()
                result.success(null)
            }
            "getConnectedDevices" -> {
                refreshConnectedDevices()
                result.success(getConnectedDevices())
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
                val trackNumber = call.argument<Int>("trackNumber")
                val totalTracks = call.argument<Int>("totalTracks")
                val genre = call.argument<String>("genre")
                val year = call.argument<Int>("year")
                
                updatePlaybackState(songId, title, artist, album, artworkUrl, 
                    duration, position, playing, trackNumber, totalTracks, genre, year)
                result.success(null)
            }
            "updatePosition" -> {
                val position = call.argument<Number>("position")?.toLong() ?: 0L
                updatePosition(position)
                result.success(null)
            }
            "updateAlbumArt" -> {
                val artworkUrl = call.argument<String>("artworkUrl")
                artworkUrl?.let { loadArtworkAsync(it) }
                result.success(null)
            }
            "isA2dpConnected" -> {
                result.success(isA2dpConnected())
            }
            "setVolume" -> {
                val volume = call.argument<Double>("volume")?.toFloat() ?: 1.0f
                setVolume(volume)
                result.success(null)
            }
            "registerAbsoluteVolumeControl" -> {
                result.success(true)
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
 * Data class for Bluetooth device info
 */
data class BluetoothDeviceInfo(
    val address: String,
    val name: String,
    val isConnected: Boolean,
    val supportsAvrcp: Boolean,
    val avrcpVersion: Int,
    val supportsAlbumArt: Boolean,
    val supportsBrowsing: Boolean
) {
    fun toMap(): Map<String, Any> = mapOf(
        "address" to address,
        "name" to name,
        "isConnected" to isConnected,
        "supportsAvrcp" to supportsAvrcp,
        "avrcpVersion" to avrcpVersion,
        "supportsAlbumArt" to supportsAlbumArt,
        "supportsBrowsing" to supportsBrowsing
    )
}
