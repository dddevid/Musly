package com.devid.musly

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Bundle
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.MediaDescriptionCompat
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.media.MediaBrowserServiceCompat
import androidx.media.session.MediaButtonReceiver
import kotlinx.coroutines.*
import java.net.URL

class MusicService : MediaBrowserServiceCompat() {

    companion object {
        private const val CHANNEL_ID = "musly_music_channel"
        private const val NOTIFICATION_ID = 1
        private const val MY_MEDIA_ROOT_ID = "media_root_id"
        private const val MY_EMPTY_MEDIA_ROOT_ID = "empty_root_id"
        
        const val MEDIA_ID_ROOT = "ROOT"
        const val MEDIA_ID_RECENT = "RECENT"
        const val MEDIA_ID_ALBUMS = "ALBUMS"
        const val MEDIA_ID_ARTISTS = "ARTISTS"
        const val MEDIA_ID_PLAYLISTS = "PLAYLISTS"
        
        @Volatile
        private var instance: MusicService? = null
        
        fun getInstance(): MusicService? = instance
    }

    private lateinit var mediaSession: MediaSessionCompat
    private lateinit var stateBuilder: PlaybackStateCompat.Builder
    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    private var currentSongId: String? = null
    private var currentTitle: String = ""
    private var currentArtist: String = ""
    private var currentAlbum: String = ""
    private var currentArtworkUrl: String? = null
    private var currentDuration: Long = 0
    private var currentPosition: Long = 0
    private var isPlaying: Boolean = false
    
    private val mediaItems = mutableListOf<MediaBrowserCompat.MediaItem>()
    private val recentSongs = mutableListOf<MediaBrowserCompat.MediaItem>()
    private val albums = mutableListOf<MediaBrowserCompat.MediaItem>()
    private val artists = mutableListOf<MediaBrowserCompat.MediaItem>()
    private val playlists = mutableListOf<MediaBrowserCompat.MediaItem>()
    
    private val albumSongsCache = mutableMapOf<String, MutableList<MediaBrowserCompat.MediaItem>>()
    private val artistAlbumsCache = mutableMapOf<String, MutableList<MediaBrowserCompat.MediaItem>>()
    private val playlistSongsCache = mutableMapOf<String, MutableList<MediaBrowserCompat.MediaItem>>()
    
    private val pendingAlbumResults = mutableMapOf<String, Result<MutableList<MediaBrowserCompat.MediaItem>>>()
    private val pendingArtistResults = mutableMapOf<String, Result<MutableList<MediaBrowserCompat.MediaItem>>>()
    private val pendingPlaylistResults = mutableMapOf<String, Result<MutableList<MediaBrowserCompat.MediaItem>>>()

    override fun onCreate() {
        super.onCreate()
        instance = this
        
        createNotificationChannel()
        initializeMediaSession()
        
        showIdleNotification()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        MediaButtonReceiver.handleIntent(mediaSession, intent)
        return START_STICKY
    }

    private fun showIdleNotification() {
        val builder = NotificationCompat.Builder(this, CHANNEL_ID).apply {
            setContentTitle("Musly")
            setContentText("Ready for Android Auto")
            setSmallIcon(R.mipmap.ic_launcher)
            setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            priority = NotificationCompat.PRIORITY_LOW
            
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            val pendingIntent = PendingIntent.getActivity(
                this@MusicService, 0, intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            setContentIntent(pendingIntent)
            
            setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setMediaSession(mediaSession.sessionToken)
                    .setShowActionsInCompactView()
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, builder.build(), android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIFICATION_ID, builder.build())
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Musly Music",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Music playback controls"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun initializeMediaSession() {
        val mediaButtonIntent = Intent(Intent.ACTION_MEDIA_BUTTON)
        mediaButtonIntent.setClass(this, MediaButtonReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this, 0, mediaButtonIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        mediaSession = MediaSessionCompat(this, "MuslyMusicService").apply {
            setFlags(
                MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS or
                MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS
            )
            
            stateBuilder = PlaybackStateCompat.Builder()
                .setActions(
                    PlaybackStateCompat.ACTION_PLAY or
                    PlaybackStateCompat.ACTION_PAUSE or
                    PlaybackStateCompat.ACTION_PLAY_PAUSE or
                    PlaybackStateCompat.ACTION_STOP or
                    PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                    PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                    PlaybackStateCompat.ACTION_SEEK_TO or
                    PlaybackStateCompat.ACTION_PLAY_FROM_MEDIA_ID
                )
            
            setPlaybackState(stateBuilder.build())
            setCallback(MediaSessionCallback())
            setMediaButtonReceiver(pendingIntent)
            isActive = true
        }
        
        sessionToken = mediaSession.sessionToken
    }

    override fun onGetRoot(
        clientPackageName: String,
        clientUid: Int,
        rootHints: Bundle?
    ): BrowserRoot {
        return BrowserRoot(MEDIA_ID_ROOT, null)
    }

    override fun onLoadChildren(
        parentId: String,
        result: Result<MutableList<MediaBrowserCompat.MediaItem>>
    ) {
        result.detach()
        
        serviceScope.launch {
            val items = when (parentId) {
                MEDIA_ID_ROOT -> getRootItems()
                MEDIA_ID_RECENT -> recentSongs
                MEDIA_ID_ALBUMS -> albums
                MEDIA_ID_ARTISTS -> artists
                MEDIA_ID_PLAYLISTS -> playlists
                else -> {
                    if (parentId.startsWith("album_")) {
                        val albumId = parentId.removePrefix("album_")
                        getAlbumSongsDynamic(albumId, result)
                        return@launch
                    } else if (parentId.startsWith("artist_")) {
                        val artistId = parentId.removePrefix("artist_")
                        getArtistAlbumsDynamic(artistId, result)
                        return@launch
                    } else if (parentId.startsWith("playlist_")) {
                        val playlistId = parentId.removePrefix("playlist_")
                        getPlaylistSongsDynamic(playlistId, result)
                        return@launch
                    } else {
                        mutableListOf()
                    }
                }
            }
            result.sendResult(items.toMutableList())
        }
    }

    private fun getRootItems(): List<MediaBrowserCompat.MediaItem> {
        return listOf(
            createBrowsableMediaItem(MEDIA_ID_RECENT, "Recent", "Recently played songs"),
            createBrowsableMediaItem(MEDIA_ID_ALBUMS, "Albums", "Browse by album"),
            createBrowsableMediaItem(MEDIA_ID_ARTISTS, "Artists", "Browse by artist"),
            createBrowsableMediaItem(MEDIA_ID_PLAYLISTS, "Playlists", "Your playlists")
        )
    }

    private fun createBrowsableMediaItem(
        mediaId: String,
        title: String,
        subtitle: String
    ): MediaBrowserCompat.MediaItem {
        val description = MediaDescriptionCompat.Builder()
            .setMediaId(mediaId)
            .setTitle(title)
            .setSubtitle(subtitle)
            .build()
        
        return MediaBrowserCompat.MediaItem(
            description,
            MediaBrowserCompat.MediaItem.FLAG_BROWSABLE
        )
    }
    
    private fun createBrowsableMediaItemWithArt(
        mediaId: String,
        title: String,
        subtitle: String,
        artworkUrl: String?
    ): MediaBrowserCompat.MediaItem {
        val descriptionBuilder = MediaDescriptionCompat.Builder()
            .setMediaId(mediaId)
            .setTitle(title)
            .setSubtitle(subtitle)
        
        artworkUrl?.takeIf { it.isNotEmpty() }?.let { url ->
            descriptionBuilder.setIconUri(android.net.Uri.parse(url))
        }
        
        return MediaBrowserCompat.MediaItem(
            descriptionBuilder.build(),
            MediaBrowserCompat.MediaItem.FLAG_BROWSABLE
        )
    }

    private fun createPlayableMediaItem(
        mediaId: String,
        title: String,
        artist: String,
        album: String,
        artworkUrl: String?
    ): MediaBrowserCompat.MediaItem {
        val descriptionBuilder = MediaDescriptionCompat.Builder()
            .setMediaId(mediaId)
            .setTitle(title)
            .setSubtitle(artist)
            .setDescription(album)
        
        artworkUrl?.takeIf { it.isNotEmpty() }?.let { url ->
            descriptionBuilder.setIconUri(android.net.Uri.parse(url))
        }
        
        return MediaBrowserCompat.MediaItem(
            descriptionBuilder.build(),
            MediaBrowserCompat.MediaItem.FLAG_PLAYABLE
        )
    }

    private suspend fun getAlbumSongs(albumId: String): List<MediaBrowserCompat.MediaItem> {
        return albumSongsCache[albumId] ?: emptyList()
    }

    private fun getAlbumSongsDynamic(albumId: String, result: Result<MutableList<MediaBrowserCompat.MediaItem>>) {
        albumSongsCache[albumId]?.let {
            result.sendResult(it)
            return
        }
        
        pendingAlbumResults[albumId] = result
        AndroidAutoPlugin.sendCommand("getAlbumSongs", mapOf("albumId" to albumId))
        
        serviceScope.launch {
            delay(10000)
            pendingAlbumResults.remove(albumId)?.sendResult(mutableListOf())
        }
    }

    private suspend fun getArtistAlbums(artistId: String): List<MediaBrowserCompat.MediaItem> {
        return artistAlbumsCache[artistId] ?: emptyList()
    }

    private fun getArtistAlbumsDynamic(artistId: String, result: Result<MutableList<MediaBrowserCompat.MediaItem>>) {
        artistAlbumsCache[artistId]?.let {
            result.sendResult(it)
            return
        }
        
        pendingArtistResults[artistId] = result
        AndroidAutoPlugin.sendCommand("getArtistAlbums", mapOf("artistId" to artistId))
        
        serviceScope.launch {
            delay(10000)
            pendingArtistResults.remove(artistId)?.sendResult(mutableListOf())
        }
    }

    private suspend fun getPlaylistSongs(playlistId: String): List<MediaBrowserCompat.MediaItem> {
        return playlistSongsCache[playlistId] ?: emptyList()
    }

    private fun getPlaylistSongsDynamic(playlistId: String, result: Result<MutableList<MediaBrowserCompat.MediaItem>>) {
        playlistSongsCache[playlistId]?.let {
            result.sendResult(it)
            return
        }
        
        pendingPlaylistResults[playlistId] = result
        AndroidAutoPlugin.sendCommand("getPlaylistSongs", mapOf("playlistId" to playlistId))
        
        serviceScope.launch {
            delay(10000)
            pendingPlaylistResults.remove(playlistId)?.sendResult(mutableListOf())
        }
    }
    
    fun updateAlbumSongs(albumId: String, songs: List<Map<String, Any>>) {
        val items = songs.map { song ->
            createPlayableMediaItem(
                song["id"] as? String ?: "",
                song["title"] as? String ?: "",
                song["artist"] as? String ?: "",
                song["album"] as? String ?: "",
                song["artworkUrl"] as? String
            )
        }.toMutableList()
        
        albumSongsCache[albumId] = items
        pendingAlbumResults.remove(albumId)?.sendResult(items)
    }
    
    fun updateArtistAlbums(artistId: String, albumList: List<Map<String, Any>>) {
        val items = albumList.map { album ->
            createBrowsableMediaItemWithArt(
                "album_${album["id"]}",
                album["name"] as? String ?: "",
                album["artist"] as? String ?: "",
                album["artworkUrl"] as? String
            )
        }.toMutableList()
        
        artistAlbumsCache[artistId] = items
        pendingArtistResults.remove(artistId)?.sendResult(items)
    }
    
    fun updatePlaylistSongs(playlistId: String, songs: List<Map<String, Any>>) {
        val items = songs.map { song ->
            createPlayableMediaItem(
                song["id"] as? String ?: "",
                song["title"] as? String ?: "",
                song["artist"] as? String ?: "",
                song["album"] as? String ?: "",
                song["artworkUrl"] as? String
            )
        }.toMutableList()
        
        playlistSongsCache[playlistId] = items
        pendingPlaylistResults.remove(playlistId)?.sendResult(items)
    }

    fun updateRecentSongs(songs: List<Map<String, Any>>) {
        recentSongs.clear()
        songs.forEach { song ->
            recentSongs.add(createPlayableMediaItem(
                song["id"] as? String ?: "",
                song["title"] as? String ?: "",
                song["artist"] as? String ?: "",
                song["album"] as? String ?: "",
                song["artworkUrl"] as? String
            ))
        }
        notifyChildrenChanged(MEDIA_ID_RECENT)
    }

    fun updateAlbums(albumList: List<Map<String, Any>>) {
        albums.clear()
        albumList.forEach { album ->
            albums.add(createBrowsableMediaItemWithArt(
                "album_${album["id"]}",
                album["name"] as? String ?: "",
                album["artist"] as? String ?: "",
                album["artworkUrl"] as? String
            ))
        }
        notifyChildrenChanged(MEDIA_ID_ALBUMS)
    }

    fun updateArtists(artistList: List<Map<String, Any>>) {
        artists.clear()
        artistList.forEach { artist ->
            artists.add(createBrowsableMediaItem(
                "artist_${artist["id"]}",
                artist["name"] as? String ?: "",
                "${artist["albumCount"] ?: 0} albums"
            ))
        }
        notifyChildrenChanged(MEDIA_ID_ARTISTS)
    }

    fun updatePlaylists(playlistList: List<Map<String, Any>>) {
        playlists.clear()
        playlistList.forEach { playlist ->
            playlists.add(createBrowsableMediaItemWithArt(
                "playlist_${playlist["id"]}",
                playlist["name"] as? String ?: "",
                "${playlist["songCount"] ?: 0} songs",
                playlist["artworkUrl"] as? String
            ))
        }
        notifyChildrenChanged(MEDIA_ID_PLAYLISTS)
    }

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
        currentSongId = songId
        currentTitle = title
        currentArtist = artist
        currentAlbum = album
        currentArtworkUrl = artworkUrl
        currentDuration = duration
        currentPosition = position
        isPlaying = playing

        updateMediaSessionMetadata()
        updateMediaSessionPlaybackState()
        showNotification()
    }

    private fun updateMediaSessionMetadata() {
        val metadataBuilder = MediaMetadataCompat.Builder()
            .putString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID, currentSongId)
            .putString(MediaMetadataCompat.METADATA_KEY_TITLE, currentTitle)
            .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, currentArtist)
            .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, currentAlbum)
            .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, currentDuration)

        mediaSession.setMetadata(metadataBuilder.build())

        currentArtworkUrl?.let { url ->
            serviceScope.launch(Dispatchers.IO) {
                try {
                    val bitmap = BitmapFactory.decodeStream(URL(url).openStream())
                    withContext(Dispatchers.Main) {
                        val updatedMetadata = MediaMetadataCompat.Builder()
                            .putString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID, currentSongId)
                            .putString(MediaMetadataCompat.METADATA_KEY_TITLE, currentTitle)
                            .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, currentArtist)
                            .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, currentAlbum)
                            .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, currentDuration)
                            .putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, bitmap)
                            .build()
                        mediaSession.setMetadata(updatedMetadata)
                        showNotification()
                    }
                } catch (e: Exception) {
                }
            }
        }
    }

    private fun updateMediaSessionPlaybackState() {
        val state = if (isPlaying) {
            PlaybackStateCompat.STATE_PLAYING
        } else {
            PlaybackStateCompat.STATE_PAUSED
        }

        stateBuilder.setState(state, currentPosition, 1.0f)
        mediaSession.setPlaybackState(stateBuilder.build())
    }

    private fun showNotification() {
        val controller = mediaSession.controller
        val mediaMetadata = controller.metadata
        val description = mediaMetadata?.description

        val builder = NotificationCompat.Builder(this, CHANNEL_ID).apply {
            setContentTitle(description?.title ?: currentTitle)
            setContentText(description?.subtitle ?: currentArtist)
            setSubText(description?.description ?: currentAlbum)
            setSmallIcon(R.mipmap.ic_launcher)
            setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

            val intent = packageManager.getLaunchIntentForPackage(packageName)
            val pendingIntent = PendingIntent.getActivity(
                this@MusicService, 0, intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            setContentIntent(pendingIntent)

            addAction(
                NotificationCompat.Action(
                    android.R.drawable.ic_media_previous,
                    "Previous",
                    MediaButtonReceiver.buildMediaButtonPendingIntent(
                        this@MusicService,
                        PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS
                    )
                )
            )
            
            if (isPlaying) {
                addAction(
                    NotificationCompat.Action(
                        android.R.drawable.ic_media_pause,
                        "Pause",
                        MediaButtonReceiver.buildMediaButtonPendingIntent(
                            this@MusicService,
                            PlaybackStateCompat.ACTION_PAUSE
                        )
                    )
                )
            } else {
                addAction(
                    NotificationCompat.Action(
                        android.R.drawable.ic_media_play,
                        "Play",
                        MediaButtonReceiver.buildMediaButtonPendingIntent(
                            this@MusicService,
                            PlaybackStateCompat.ACTION_PLAY
                        )
                    )
                )
            }
            
            addAction(
                NotificationCompat.Action(
                    android.R.drawable.ic_media_next,
                    "Next",
                    MediaButtonReceiver.buildMediaButtonPendingIntent(
                        this@MusicService,
                        PlaybackStateCompat.ACTION_SKIP_TO_NEXT
                    )
                )
            )

            setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setMediaSession(mediaSession.sessionToken)
                    .setShowActionsInCompactView(0, 1, 2)
                    .setShowCancelButton(true)
                    .setCancelButtonIntent(
                        MediaButtonReceiver.buildMediaButtonPendingIntent(
                            this@MusicService,
                            PlaybackStateCompat.ACTION_STOP
                        )
                    )
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, builder.build(), android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIFICATION_ID, builder.build())
        }
    }

    private inner class MediaSessionCallback : MediaSessionCompat.Callback() {
        override fun onPlay() {
            AndroidAutoPlugin.sendCommand("play", null)
        }

        override fun onPause() {
            AndroidAutoPlugin.sendCommand("pause", null)
        }

        override fun onStop() {
            AndroidAutoPlugin.sendCommand("stop", null)
        }

        override fun onSkipToNext() {
            AndroidAutoPlugin.sendCommand("skipNext", null)
        }

        override fun onSkipToPrevious() {
            AndroidAutoPlugin.sendCommand("skipPrevious", null)
        }

        override fun onSeekTo(pos: Long) {
            AndroidAutoPlugin.sendCommand("seekTo", mapOf("position" to pos))
        }

        override fun onPlayFromMediaId(mediaId: String?, extras: Bundle?) {
            mediaId?.let {
                AndroidAutoPlugin.sendCommand("playFromMediaId", mapOf("mediaId" to it))
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        mediaSession.isActive = false
        mediaSession.release()
    }
    
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
    }
}
