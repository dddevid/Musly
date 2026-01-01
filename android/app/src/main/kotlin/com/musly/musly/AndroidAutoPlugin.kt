package com.musly.musly

import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object AndroidAutoPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    
    private const val METHOD_CHANNEL = "com.musly.musly/android_auto"
    private const val EVENT_CHANNEL = "com.musly.musly/android_auto_events"
    
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    
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
        
        startMusicService()
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
                
                MusicService.getInstance()?.updatePlaybackState(
                    songId, title, artist, album, artworkUrl, duration, position, playing
                )
                result.success(null)
            }
            "updateRecentSongs" -> {
                val songs = call.argument<List<Map<String, Any>>>("songs") ?: emptyList()
                MusicService.getInstance()?.updateRecentSongs(songs)
                result.success(null)
            }
            "updateAlbums" -> {
                val albums = call.argument<List<Map<String, Any>>>("albums") ?: emptyList()
                MusicService.getInstance()?.updateAlbums(albums)
                result.success(null)
            }
            "updateArtists" -> {
                val artists = call.argument<List<Map<String, Any>>>("artists") ?: emptyList()
                MusicService.getInstance()?.updateArtists(artists)
                result.success(null)
            }
            "updatePlaylists" -> {
                val playlists = call.argument<List<Map<String, Any>>>("playlists") ?: emptyList()
                MusicService.getInstance()?.updatePlaylists(playlists)
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
            else -> result.notImplemented()
        }
    }
    
    private fun startMusicService() {
        context?.let { ctx ->
            val intent = Intent(ctx, MusicService::class.java)
            ContextCompat.startForegroundService(ctx, intent)
        }
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
}
