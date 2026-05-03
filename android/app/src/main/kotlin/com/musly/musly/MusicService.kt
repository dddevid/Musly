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
import android.media.AudioManager
import android.util.Log
import androidx.media.VolumeProviderCompat
import kotlinx.coroutines.*
import java.net.URL
import kotlin.math.roundToInt

class MusicService : MediaBrowserServiceCompat() {

    companion object {
        private const val TAG = "MusicService"
        private const val CHANNEL_ID = "musly_music_channel"
        private const val NOTIFICATION_ID = 1
        private const val MY_MEDIA_ROOT_ID = "media_root_id"
        private const val MY_EMPTY_MEDIA_ROOT_ID = "empty_root_id"
        
        const val MEDIA_ID_ROOT = "ROOT"
        const val MEDIA_ID_RECENT = "RECENT"
        const val MEDIA_ID_ALBUMS = "ALBUMS"
        const val MEDIA_ID_ARTISTS = "ARTISTS"
        const val MEDIA_ID_PLAYLISTS = "PLAYLISTS"
        const val MEDIA_ID_SEARCH = "SEARCH"
        const val MEDIA_ID_SONGS = "SONGS"
        
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
    private var currentArtworkBitmap: Bitmap? = null
    private var currentDuration: Long = 0
    private var currentPosition: Long = 0
    private var isPlaying: Boolean = false
    private var volumeProvider: VolumeProviderCompat? = null
    private var upnpExpectedVolume = 0
    
    // Lyrics support
    private var currentLyricsLine: String? = null
    private var hasLyrics: Boolean = false

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
    private val pendingSearchResults = mutableMapOf<String, Result<MutableList<MediaBrowserCompat.MediaItem>>>()

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "MusicService onCreate")

        createNotificationChannel()
        initializeMediaSession()

        showIdleNotification()

        // Deliver any library data that was sent to AndroidAutoPlugin before this
        // service finished starting (race condition at app launch).
        AndroidAutoPlugin.flushPendingLibraryData()
        
        // Request library data from Flutter in case it wasn't sent yet
        // This handles the case where Android Auto starts the service before Flutter is ready
        AndroidAutoPlugin.requestLibraryData()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "MusicService onStartCommand action=${intent?.action}")
        MediaButtonReceiver.handleIntent(mediaSession, intent)
        return START_NOT_STICKY
    }

    private fun showIdleNotification() {
        val builder = NotificationCompat.Builder(this, CHANNEL_ID).apply {
            setContentTitle("Musly")
            setContentText("Ready to play your music")
            setSmallIcon(R.mipmap.ic_launcher)
            setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            setColor(0xFF1DB954.toInt())
            setColorized(true)
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
                    PlaybackStateCompat.ACTION_PLAY_FROM_MEDIA_ID or
                    PlaybackStateCompat.ACTION_PLAY_FROM_SEARCH
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
        // Advertise search capability via BrowserRoot extras.
        // Android Auto reads these extras (in addition to the manifest metadata)
        // to decide whether to show the search lens on the browse screen.
        val extras = Bundle().apply {
            putBoolean("android.media.browse.SEARCH_SUPPORTED", true)
        }
        return BrowserRoot(MEDIA_ID_ROOT, extras)
    }

    override fun onSearch(
        query: String,
        extras: Bundle?,
        result: Result<MutableList<MediaBrowserCompat.MediaItem>>
    ) {
        result.detach()
        pendingSearchResults[query] = result
        AndroidAutoPlugin.sendCommand("search", mapOf("query" to query))
        // Timeout after 10 seconds to avoid hanging the UI
        serviceScope.launch {
            delay(10000)
            pendingSearchResults.remove(query)?.sendResult(mutableListOf())
        }
    }

    fun updateSearchResults(query: String, songs: List<Map<String, Any>>) {
        val items = songs.map { song ->
            createPlayableMediaItem(
                song["id"] as? String ?: "",
                song["title"] as? String ?: "",
                song["artist"] as? String ?: "",
                song["album"] as? String ?: "",
                song["artworkUrl"] as? String
            )
        }.toMutableList()
        pendingSearchResults.remove(query)?.sendResult(items)
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
            createBrowsableMediaItem(
                MEDIA_ID_RECENT, 
                "Recent", 
                "Recently played songs",
                R.drawable.ic_recent
            ),
            createBrowsableMediaItem(
                MEDIA_ID_ALBUMS, 
                "Albums", 
                "Browse your music collection",
                R.drawable.ic_albums
            ),
            createBrowsableMediaItem(
                MEDIA_ID_ARTISTS, 
                "Artists", 
                "Find music by artist",
                R.drawable.ic_artists
            ),
            createBrowsableMediaItem(
                MEDIA_ID_PLAYLISTS, 
                "Playlists", 
                "Your curated playlists",
                R.drawable.ic_playlists
            )
        )
    }

    private fun createBrowsableMediaItem(
        mediaId: String,
        title: String,
        subtitle: String,
        iconResId: Int = 0
    ): MediaBrowserCompat.MediaItem {
        val descriptionBuilder = MediaDescriptionCompat.Builder()
            .setMediaId(mediaId)
            .setTitle(title)
            .setSubtitle(subtitle)
        
        if (iconResId != 0) {
            descriptionBuilder.setIconUri(
                android.net.Uri.parse("android.resource://${packageName}/$iconResId")
            )
        }
        
        return MediaBrowserCompat.MediaItem(
            descriptionBuilder.build(),
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
        
        if (artworkUrl?.isNotEmpty() == true) {
            descriptionBuilder.setIconUri(android.net.Uri.parse(artworkUrl))
        } else {
            // Use placeholder for albums without artwork
            descriptionBuilder.setIconUri(
                android.net.Uri.parse("android.resource://${packageName}/${R.drawable.ic_album_placeholder}")
            )
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
        
        if (artworkUrl?.isNotEmpty() == true) {
            descriptionBuilder.setIconUri(android.net.Uri.parse(artworkUrl))
        } else {
            // Use placeholder icon for songs without artwork
            descriptionBuilder.setIconUri(
                android.net.Uri.parse("android.resource://${packageName}/${R.drawable.ic_album_placeholder}")
            )
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

        // Add lyrics line as display subtitle for Bluetooth AVRCP 1.6+ support
        if (hasLyrics && !currentLyricsLine.isNullOrEmpty()) {
            metadataBuilder.putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, currentLyricsLine)
        }

        val url = currentArtworkUrl

        // Avoid clearing existing album art while loading a new one to prevent flicker in Android Auto.
        if (url.isNullOrEmpty()) {
            if (currentArtworkBitmap != null) {
                val updatedMetadata = MediaMetadataCompat.Builder()
                    .putString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID, currentSongId)
                    .putString(MediaMetadataCompat.METADATA_KEY_TITLE, currentTitle)
                    .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, currentArtist)
                    .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, currentAlbum)
                    .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, currentDuration)
                    .putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, currentArtworkBitmap)
                    // Include lyrics in metadata for Bluetooth
                    .apply {
                        if (hasLyrics && !currentLyricsLine.isNullOrEmpty()) {
                            putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, currentLyricsLine)
                        }
                    }
                    .build()
                mediaSession.setMetadata(updatedMetadata)
            } else {
                mediaSession.setMetadata(metadataBuilder.build())
            }
            return
        }

        // Load new artwork asynchronously; do not clear current artwork until new bitmap is ready.
        serviceScope.launch(Dispatchers.IO) {
            try {
                val bitmap = BitmapFactory.decodeStream(URL(url).openStream())
                currentArtworkBitmap = bitmap
                withContext(Dispatchers.Main) {
                    val updatedMetadata = MediaMetadataCompat.Builder()
                        .putString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID, currentSongId)
                        .putString(MediaMetadataCompat.METADATA_KEY_TITLE, currentTitle)
                        .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, currentArtist)
                        .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, currentAlbum)
                        .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, currentDuration)
                        .putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, bitmap)
                        // Include lyrics in metadata for Bluetooth
                        .apply {
                            if (hasLyrics && !currentLyricsLine.isNullOrEmpty()) {
                                putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, currentLyricsLine)
                            }
                        }
                        .build()
                    mediaSession.setMetadata(updatedMetadata)
                    showNotification()
                }
            } catch (e: Exception) {
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

        // Use lyrics line as subtitle if available, otherwise use artist
        val subtitleText = if (hasLyrics && !currentLyricsLine.isNullOrEmpty()) {
            currentLyricsLine
        } else {
            description?.subtitle ?: currentArtist
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID).apply {
            setContentTitle(description?.title ?: currentTitle)
            setContentText(subtitleText)
            setSubText(description?.description ?: currentAlbum)
            setSmallIcon(R.mipmap.ic_launcher)
            setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            setColor(0xFF1DB954.toInt()) // Musly green accent color
            setColorized(true)

            // Use album art for large icon if available
            description?.iconBitmap?.let { bitmap ->
                setLargeIcon(bitmap)
            } ?: currentArtworkBitmap?.let { bitmap ->
                setLargeIcon(bitmap)
            }

            val intent = packageManager.getLaunchIntentForPackage(packageName)
            val pendingIntent = PendingIntent.getActivity(
                this@MusicService, 0, intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            setContentIntent(pendingIntent)

            // Previous button with custom icon
            addAction(
                NotificationCompat.Action(
                    R.drawable.ic_recent,
                    "Previous",
                    MediaButtonReceiver.buildMediaButtonPendingIntent(
                        this@MusicService,
                        PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS
                    )
                )
            )
            
            // Play/Pause button with custom styling
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
                        R.drawable.ic_play,
                        "Play",
                        MediaButtonReceiver.buildMediaButtonPendingIntent(
                            this@MusicService,
                            PlaybackStateCompat.ACTION_PLAY
                        )
                    )
                )
            }
            
            // Next button
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

        override fun onPlayFromSearch(query: String?, extras: Bundle?) {
            val q = query?.trim() ?: ""
            AndroidAutoPlugin.sendCommand("playFromSearch", mapOf("query" to q))
        }
    }

    fun setRemoteVolume(isRemote: Boolean, currentVolume: Int) {
        if (isRemote) {
            // Provider scale 0-20 (1 unit = 5% UPnP). Android's mOptimisticVolume always
            // steps by ±1, so this aligns the optimistic value with our actual target and
            // eliminates the 1-second visual jump on hardware volume button presses.
            val initialProviderVolume = (currentVolume / 5.0).roundToInt().coerceIn(0, 20)
            upnpExpectedVolume = initialProviderVolume
            volumeProvider = object : VolumeProviderCompat(
                VOLUME_CONTROL_ABSOLUTE, 20, initialProviderVolume
            ) {
                override fun onSetVolumeTo(volume: Int) {
                    upnpExpectedVolume = volume
                    setCurrentVolume(volume)
                    AndroidAutoPlugin.sendCommand("setVolume", mapOf("volume" to volume * 5))
                }

                override fun onAdjustVolume(direction: Int) {
                    if (direction == 0) return  // ADJUST_SAME on key-up; no change needed
                    upnpExpectedVolume = (upnpExpectedVolume + direction).coerceIn(0, 20)
                    setCurrentVolume(upnpExpectedVolume)
                    AndroidAutoPlugin.sendCommand("setVolume", mapOf("volume" to upnpExpectedVolume * 5))
                }
            }
            mediaSession.setPlaybackToRemote(volumeProvider!!)
            Log.d(TAG, "MediaSession set to remote volume (current=$currentVolume)")
        } else {
            volumeProvider = null
            mediaSession.setPlaybackToLocal(AudioManager.STREAM_MUSIC)
            Log.d(TAG, "MediaSession set to local volume")
        }
    }

    fun updateRemoteVolume(volume: Int) {
        // volume is SOAP scale 0-100; convert to provider scale 0-20
        val providerVolume = (volume / 5.0).roundToInt().coerceIn(0, 20)
        upnpExpectedVolume = providerVolume
        volumeProvider?.currentVolume = providerVolume
    }

    // Lyrics support methods
    fun updateLyrics(lyricsLine: String?) {
        if (lyricsLine == null || lyricsLine == currentLyricsLine) return
        
        currentLyricsLine = lyricsLine
        hasLyrics = true
        
        // Refresh notification and MediaSession metadata for Bluetooth lyrics support
        updateMediaSessionMetadata()
        showNotification()
        
        Log.d(TAG, "Updated lyrics: $lyricsLine")
    }
    
    fun clearLyrics() {
        currentLyricsLine = null
        hasLyrics = false
        updateMediaSessionMetadata()
        showNotification()
        Log.d(TAG, "Cleared lyrics")
    }

    override fun onDestroy() {
        Log.d(TAG, "MusicService onDestroy")
        instance = null
        super.onDestroy()
        serviceScope.cancel()
        mediaSession.isActive = false
        mediaSession.release()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.d(TAG, "MusicService onTaskRemoved")
        super.onTaskRemoved(rootIntent)
        mediaSession.isActive = false
        stopForeground(true)
        stopSelf()
    }
}
