import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

/// SQLite-based persistent storage for the music library.
///
/// Replaces the previous SharedPreferences + single-blob JSON approach
/// which caused OutOfMemoryError with libraries containing 100k+ songs.
///
/// Batch inserts use transactions and 1k-record chunks so that even
/// millions of rows can be written without spikes in memory usage.
class LibraryDatabaseService {
  static const String _dbName = 'musly_library.db';
  static const int _dbVersion = 2; // bumped from 1 after schema changes
  static const int _batchSize = 1000;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, _dbName);

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createSchema(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 -> v2: add starred / userRating columns if missing
      try {
        await db.execute(
            'ALTER TABLE songs ADD COLUMN starred INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE songs ADD COLUMN userRating INTEGER');
      } catch (_) {}
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS songs (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        album TEXT,
        albumId TEXT,
        artist TEXT,
        artistId TEXT,
        track INTEGER,
        year INTEGER,
        genre TEXT,
        coverArt TEXT,
        duration INTEGER,
        bitRate INTEGER,
        suffix TEXT,
        contentType TEXT,
        size INTEGER,
        path TEXT,
        isLocal INTEGER DEFAULT 0,
        replayGainTrackGain REAL,
        replayGainAlbumGain REAL,
        replayGainTrackPeak REAL,
        replayGainAlbumPeak REAL,
        artistParticipants TEXT,
        created TEXT,
        starred INTEGER DEFAULT 0,
        userRating INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS albums (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        artist TEXT,
        artistId TEXT,
        coverArt TEXT,
        songCount INTEGER,
        duration INTEGER,
        year INTEGER,
        genre TEXT,
        created TEXT,
        isLocal INTEGER DEFAULT 0,
        artistParticipants TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS artists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        coverArt TEXT,
        albumCount INTEGER,
        artistImageUrl TEXT,
        isLocal INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        comment TEXT,
        owner TEXT,
        public INTEGER,
        songCount INTEGER,
        duration INTEGER,
        created TEXT,
        changed TEXT,
        coverArt TEXT,
        songIds TEXT
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_song_albumId ON songs(albumId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_song_artistId ON songs(artistId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_album_artistId ON albums(artistId)');
  }

  // ── Batch inserts ───────────────────────────────────────────────────────

  Future<void> insertSongsBatch(List<Song> songs) async {
    if (songs.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      for (var i = 0; i < songs.length; i += _batchSize) {
        final batch = txn.batch();
        final end =
            (i + _batchSize < songs.length) ? i + _batchSize : songs.length;
        for (var j = i; j < end; j++) {
          batch.insert(
            'songs',
            _songToMap(songs[j]),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }
    });
  }

  Future<void> insertAlbumsBatch(List<Album> albums) async {
    if (albums.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      for (var i = 0; i < albums.length; i += _batchSize) {
        final batch = txn.batch();
        final end =
            (i + _batchSize < albums.length) ? i + _batchSize : albums.length;
        for (var j = i; j < end; j++) {
          batch.insert(
            'albums',
            _albumToMap(albums[j]),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }
    });
  }

  Future<void> insertArtistsBatch(List<Artist> artists) async {
    if (artists.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      for (var i = 0; i < artists.length; i += _batchSize) {
        final batch = txn.batch();
        final end = (i + _batchSize < artists.length)
            ? i + _batchSize
            : artists.length;
        for (var j = i; j < end; j++) {
          batch.insert(
            'artists',
            _artistToMap(artists[j]),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }
    });
  }

  Future<void> insertPlaylistsBatch(List<Playlist> playlists) async {
    if (playlists.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      for (var i = 0; i < playlists.length; i += _batchSize) {
        final batch = txn.batch();
        final end = (i + _batchSize < playlists.length)
            ? i + _batchSize
            : playlists.length;
        for (var j = i; j < end; j++) {
          batch.insert(
            'playlists',
            _playlistToMap(playlists[j]),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }
    });
  }

  // ── Full-table queries (kept for backward-compat) ───────────────────────

  Future<List<Song>> getAllSongs() async {
    final db = await database;
    final maps = await db.query('songs');
    return maps.map((m) => _songFromMap(m)).toList();
  }

  Future<List<Album>> getAllAlbums() async {
    final db = await database;
    final maps = await db.query('albums');
    return maps.map((m) => _albumFromMap(m)).toList();
  }

  Future<List<Artist>> getAllArtists() async {
    final db = await database;
    final maps = await db.query('artists');
    return maps.map((m) => _artistFromMap(m)).toList();
  }

  Future<List<Playlist>> getAllPlaylists() async {
    final db = await database;
    final maps = await db.query('playlists');
    return maps.map((m) => _playlistFromMap(m)).toList();
  }

  // ── Paginated / low-memory queries ──────────────────────────────────────

  Future<List<Song>> getSongsPaginated({int limit = 500, int offset = 0}) async {
    final db = await database;
    final maps = await db.query('songs', limit: limit, offset: offset);
    return maps.map((m) => _songFromMap(m)).toList();
  }

  Future<List<Album>> getAlbumsPaginated({int limit = 500, int offset = 0}) async {
    final db = await database;
    final maps = await db.query('albums', limit: limit, offset: offset);
    return maps.map((m) => _albumFromMap(m)).toList();
  }

  Future<List<Artist>> getArtistsPaginated({int limit = 500, int offset = 0}) async {
    final db = await database;
    final maps = await db.query('artists', limit: limit, offset: offset);
    return maps.map((m) => _artistFromMap(m)).toList();
  }

  Future<int> getSongCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM songs');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getAlbumCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM albums');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getArtistCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM artists');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── Destructive operations ────────────────────────────────────────────

  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('songs');
      await txn.delete('albums');
      await txn.delete('artists');
      await txn.delete('playlists');
    });
  }

  /// Clear only server-side data, preserving local library entries.
  Future<void> clearServerData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('songs', where: 'isLocal = ?', whereArgs: [0]);
      await txn.delete('albums', where: 'isLocal = ?', whereArgs: [0]);
      await txn.delete('artists', where: 'isLocal = ?', whereArgs: [0]);
      await txn.delete('playlists');
    });
  }

  Future<List<Song>> getLocalSongs() async {
    final db = await database;
    final maps = await db.query('songs', where: 'isLocal = ?', whereArgs: [1]);
    return maps.map((m) => _songFromMap(m)).toList();
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  // ── Helpers: Song ───────────────────────────────────────────────────────

  Map<String, dynamic> _songToMap(Song song) {
    return {
      'id': song.id,
      'title': song.title,
      'album': song.album,
      'albumId': song.albumId,
      'artist': song.artist,
      'artistId': song.artistId,
      'track': song.track,
      'year': song.year,
      'genre': song.genre,
      'coverArt': song.coverArt,
      'duration': song.duration,
      'bitRate': song.bitRate,
      'suffix': song.suffix,
      'contentType': song.contentType,
      'size': song.size,
      'path': song.path,
      'isLocal': song.isLocal ? 1 : 0,
      'replayGainTrackGain': song.replayGainTrackGain,
      'replayGainAlbumGain': song.replayGainAlbumGain,
      'replayGainTrackPeak': song.replayGainTrackPeak,
      'replayGainAlbumPeak': song.replayGainAlbumPeak,
      'artistParticipants': song.artistParticipants != null
          ? jsonEncode(
              song.artistParticipants!.map((a) => a.toJson()).toList(),
            )
          : null,
      'created': song.created?.toIso8601String(),
      'starred': song.starred == true ? 1 : 0,
      'userRating': song.userRating,
    };
  }

  Song _songFromMap(Map<String, dynamic> m) {
    final participantsJson = m['artistParticipants'] as String?;
    return Song(
      id: m['id'] as String,
      title: m['title'] as String,
      album: m['album'] as String?,
      albumId: m['albumId'] as String?,
      artist: m['artist'] as String?,
      artistId: m['artistId'] as String?,
      track: m['track'] as int?,
      year: m['year'] as int?,
      genre: m['genre'] as String?,
      coverArt: m['coverArt'] as String?,
      duration: m['duration'] as int?,
      bitRate: m['bitRate'] as int?,
      suffix: m['suffix'] as String?,
      contentType: m['contentType'] as String?,
      size: m['size'] as int?,
      path: m['path'] as String?,
      isLocal: (m['isLocal'] as int?) == 1,
      replayGainTrackGain: m['replayGainTrackGain'] as double?,
      replayGainAlbumGain: m['replayGainAlbumGain'] as double?,
      replayGainTrackPeak: m['replayGainTrackPeak'] as double?,
      replayGainAlbumPeak: m['replayGainAlbumPeak'] as double?,
      artistParticipants: participantsJson != null
          ? ArtistRef.parseList(jsonDecode(participantsJson))
          : null,
      created: m['created'] != null
          ? DateTime.tryParse(m['created'] as String)
          : null,
      starred: (m['starred'] as int?) == 1,
      userRating: m['userRating'] as int?,
    );
  }

  // ── Helpers: Album ──────────────────────────────────────────────────────

  Map<String, dynamic> _albumToMap(Album album) {
    return {
      'id': album.id,
      'name': album.name,
      'artist': album.artist,
      'artistId': album.artistId,
      'coverArt': album.coverArt,
      'songCount': album.songCount,
      'duration': album.duration,
      'year': album.year,
      'genre': album.genre,
      'created': album.created?.toIso8601String(),
      'isLocal': album.isLocal ? 1 : 0,
      'artistParticipants': album.artistParticipants != null
          ? jsonEncode(
              album.artistParticipants!.map((a) => a.toJson()).toList(),
            )
          : null,
    };
  }

  Album _albumFromMap(Map<String, dynamic> m) {
    final participantsJson = m['artistParticipants'] as String?;
    return Album(
      id: m['id'] as String,
      name: m['name'] as String,
      artist: m['artist'] as String?,
      artistId: m['artistId'] as String?,
      coverArt: m['coverArt'] as String?,
      songCount: m['songCount'] as int?,
      duration: m['duration'] as int?,
      year: m['year'] as int?,
      genre: m['genre'] as String?,
      created: m['created'] != null
          ? DateTime.tryParse(m['created'] as String)
          : null,
      isLocal: (m['isLocal'] as int?) == 1,
      artistParticipants: participantsJson != null
          ? ArtistRef.parseList(jsonDecode(participantsJson))
          : null,
    );
  }

  // ── Helpers: Artist ─────────────────────────────────────────────────────

  Map<String, dynamic> _artistToMap(Artist artist) {
    return {
      'id': artist.id,
      'name': artist.name,
      'coverArt': artist.coverArt,
      'albumCount': artist.albumCount,
      'artistImageUrl': artist.artistImageUrl,
      'isLocal': artist.isLocal ? 1 : 0,
    };
  }

  Artist _artistFromMap(Map<String, dynamic> m) {
    return Artist(
      id: m['id'] as String,
      name: m['name'] as String,
      coverArt: m['coverArt'] as String?,
      albumCount: m['albumCount'] as int?,
      artistImageUrl: m['artistImageUrl'] as String?,
      isLocal: (m['isLocal'] as int?) == 1,
    );
  }

  // ── Helpers: Playlist ─────────────────────────────────────────────────

  Map<String, dynamic> _playlistToMap(Playlist playlist) {
    return {
      'id': playlist.id,
      'name': playlist.name,
      'comment': playlist.comment,
      'owner': playlist.owner,
      'public': playlist.public == true ? 1 : 0,
      'songCount': playlist.songCount,
      'duration': playlist.duration,
      'created': playlist.created?.toIso8601String(),
      'changed': playlist.changed?.toIso8601String(),
      'coverArt': playlist.coverArt,
      'songIds': playlist.songs?.map((s) => s.id).toList().join(','),
    };
  }

  Playlist _playlistFromMap(Map<String, dynamic> m) {
    final songIdsStr = m['songIds'] as String?;
    List<Song>? songList;
    if (songIdsStr != null && songIdsStr.isNotEmpty) {
      songList = songIdsStr
          .split(',')
          .map((id) => Song(id: id, title: 'Unknown'))
          .toList();
    }
    return Playlist(
      id: m['id'] as String,
      name: m['name'] as String,
      comment: m['comment'] as String?,
      owner: m['owner'] as String?,
      public: (m['public'] as int?) == 1,
      songCount: m['songCount'] as int?,
      duration: m['duration'] as int?,
      created: m['created'] != null
          ? DateTime.tryParse(m['created'] as String)
          : null,
      changed: m['changed'] != null
          ? DateTime.tryParse(m['changed'] as String)
          : null,
      coverArt: m['coverArt'] as String?,
      songs: songList,
    );
  }
}
