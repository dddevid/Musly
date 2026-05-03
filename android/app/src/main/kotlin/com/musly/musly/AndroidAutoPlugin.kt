package com.devid.musly

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object AndroidAutoPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private const val TAG = "AndroidAutoPlugin"
    private const val METHOD_CHANNEL = "com.devid.musly/android_auto"
    private const val EVENT_CHANNEL = "com.devid.musly/android_auto_events"

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // Buffers for library data sent before MusicService finishes starting.
    private var pendingRecentSongs: List<Map<String, Any>>? = null
    private var pendingAlbums: List<Map<String, Any>>? = null
    private var pendingArtists: List<Map<String, Any>>? = null
    private var pendingPlaylists: List<Map<String, Any>>? = null
    
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        
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

        Log.d(TAG, "AndroidAutoPlugin attached (service will start on first playback)")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startService" -> {
                startMusicService()
                result.success(null)
            }
            "stopService" -> {
                stopMusicService()
                result.success(null)
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

                // Ensure the service is running before updating state
                val pushState = {
                    MusicService.getInstance()?.updatePlaybackState(
                        songId, title, artist, album, artworkUrl, duration, position, playing
                    )
                }
                if (MusicService.getInstance() == null) {
                    Log.d(TAG, "MusicService not running, starting it now")
                    startMusicService()
                    // Service start is async; retry after a short delay
                    mainHandler.postDelayed({ pushState() }, 200)
                } else {
                    pushState()
                }
                result.success(null)
            }
            "updateRecentSongs" -> {
                val songs = call.argument<List<Map<String, Any>>>("songs") ?: emptyList()
                val svc = MusicService.getInstance()
                if (svc == null) {
                    Log.d(TAG, "MusicService not ready, buffering ${songs.size} recent songs")
                    pendingRecentSongs = songs
                    startMusicService()
                    mainHandler.postDelayed({ flushPendingLibraryData() }, 800)
                } else {
                    svc.updateRecentSongs(songs)
                }
                result.success(null)
            }
            "updateAlbums" -> {
                val albums = call.argument<List<Map<String, Any>>>("albums") ?: emptyList()
                val svc = MusicService.getInstance()
                if (svc == null) {
                    Log.d(TAG, "MusicService not ready, buffering ${albums.size} albums")
                    pendingAlbums = albums
                    startMusicService()
                    mainHandler.postDelayed({ flushPendingLibraryData() }, 800)
                } else {
                    svc.updateAlbums(albums)
                }
                result.success(null)
            }
            "updateArtists" -> {
                val artists = call.argument<List<Map<String, Any>>>("artists") ?: emptyList()
                val svc = MusicService.getInstance()
                if (svc == null) {
                    Log.d(TAG, "MusicService not ready, buffering ${artists.size} artists")
                    pendingArtists = artists
                    startMusicService()
                    mainHandler.postDelayed({ flushPendingLibraryData() }, 800)
                } else {
                    svc.updateArtists(artists)
                }
                result.success(null)
            }
            "updatePlaylists" -> {
                val playlists = call.argument<List<Map<String, Any>>>("playlists") ?: emptyList()
                val svc = MusicService.getInstance()
                if (svc == null) {
                    Log.d(TAG, "MusicService not ready, buffering ${playlists.size} playlists")
                    pendingPlaylists = playlists
                    startMusicService()
                    mainHandler.postDelayed({ flushPendingLibraryData() }, 800)
                } else {
                    svc.updatePlaylists(playlists)
                }
                result.success(null)
            }
            "updateAlbumSongs" -> {
                val albumId = call.argument<String>("albumId") ?: ""
                val songs = call.argument<List<Map<String, Any>>>("songs") ?: emptyList()
                MusicService.getInstance()?.updateAlbumSongs(albumId, songs)
                result.success(null)
            }
            "updateArtistAlbums" -> {
                val artistId = call.argument<String>("artistId") ?: ""
                val albums = call.argument<List<Map<String, Any>>>("albums") ?: emptyList()
                MusicService.getInstance()?.updateArtistAlbums(artistId, albums)
                result.success(null)
            }
            "updatePlaylistSongs" -> {
                val playlistId = call.argument<String>("playlistId") ?: ""
                val songs = call.argument<List<Map<String, Any>>>("songs") ?: emptyList()
                MusicService.getInstance()?.updatePlaylistSongs(playlistId, songs)
                result.success(null)
            }
            "updateSearchResults" -> {
                val query = call.argument<String>("query") ?: ""
                val songs = call.argument<List<Map<String, Any>>>("songs") ?: emptyList()
                MusicService.getInstance()?.updateSearchResults(query, songs)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
    
    /** Called by MusicService once it is fully ready, or from postDelayed retries. */
    fun flushPendingLibraryData() {
        val svc = MusicService.getInstance() ?: return
        pendingRecentSongs?.let {
            Log.d(TAG, "Flushing ${it.size} buffered recent songs to MusicService")
            svc.updateRecentSongs(it)
            pendingRecentSongs = null
        }
        pendingAlbums?.let {
            Log.d(TAG, "Flushing ${it.size} buffered albums to MusicService")
            svc.updateAlbums(it)
            pendingAlbums = null
        }
        pendingArtists?.let {
            Log.d(TAG, "Flushing ${it.size} buffered artists to MusicService")
            svc.updateArtists(it)
            pendingArtists = null
        }
        pendingPlaylists?.let {
            Log.d(TAG, "Flushing ${it.size} buffered playlists to MusicService")
            svc.updatePlaylists(it)
            pendingPlaylists = null
        }
    }

    fun startMusicService() {
        context?.let { ctx ->
            try {
                val intent = Intent(ctx, MusicService::class.java)
                ContextCompat.startForegroundService(ctx, intent)
                Log.d(TAG, "startForegroundService called successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start MusicService: ${e.message}", e)
            }
        } ?: Log.w(TAG, "Cannot start MusicService: context is null")
    }
    
    private fun stopMusicService() {
        context?.let { ctx ->
            val intent = Intent(ctx, MusicService::class.java)
            ctx.stopService(intent)
        }
    }
    
    fun sendCommand(command: String, arguments: Map<String, Any>?) {
        val data = mutableMapOf<String, Any>("command" to command)
        arguments?.let { data.putAll(it) }
        
        eventSink?.success(data)
    }
    
    /** Request library data from Flutter. Called when MusicService is ready but has no data yet. */
    fun requestLibraryData() {
        Log.d(TAG, "Requesting library data from Flutter")
        sendCommand("requestLibraryData", null)
    }
}
