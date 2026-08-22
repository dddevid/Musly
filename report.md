# Report analisi Flutter — /DATA/AppData/big-bear-code-server/config/Musly

## 1. File potenzialmente morti (mai importati)

- `lib/models/artist_info.dart`
- `lib/screens/albums_screen.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/main_screen.dart`
- `lib/screens/songs_screen.dart`
- `lib/widgets/album_card.dart`
- `lib/widgets/artist_card.dart`
- `lib/widgets/desktop_navigation_sidebar.dart`
- `lib/widgets/desktop_player_bar.dart`
- `lib/widgets/favorite_playlists_section.dart`
- `lib/widgets/gradient_header.dart`
- `lib/widgets/lazy_indexed_stack.dart`
- `lib/widgets/mini_player.dart`
- `lib/widgets/right_sidebar.dart`
- `lib/widgets/section_header.dart`
- `lib/widgets/shimmer_loading.dart`
- `lib/widgets/spotify_like_card.dart`
- `packages/flutter_chrome_cast/lib/_discovery_manager/_discovery_manager.dart`
- `packages/flutter_chrome_cast/lib/_discovery_manager/android_discovery_manager.dart`
- `packages/flutter_chrome_cast/lib/_discovery_manager/discovery_manager.dart`
- `packages/flutter_chrome_cast/lib/_discovery_manager/ios_discovery_manager.dart`
- `packages/flutter_chrome_cast/lib/_google_cast_context/_google_cast_context.dart`
- `packages/flutter_chrome_cast/lib/_google_cast_context/android_google_cast_context_method_channel.dart`
- `packages/flutter_chrome_cast/lib/_google_cast_context/google_cast_context.dart`
- `packages/flutter_chrome_cast/lib/_remote_media_client/_remote_media_client.dart`
- `packages/flutter_chrome_cast/lib/_remote_media_client/remote_media_client.dart`
- `packages/flutter_chrome_cast/lib/_remote_media_client/remote_media_client_platform.dart`
- `packages/flutter_chrome_cast/lib/_session_manager/_session_manager.dart`
- `packages/flutter_chrome_cast/lib/_session_manager/android_cast_session_manager.dart`
- `packages/flutter_chrome_cast/lib/_session_manager/cast_session_manager.dart`
- `packages/flutter_chrome_cast/lib/_session_manager/ios_cast_session_manager.dart`
- `packages/flutter_chrome_cast/lib/common/break.dart`
- `packages/flutter_chrome_cast/lib/common/break_clips.dart`
- `packages/flutter_chrome_cast/lib/common/cast_status_event.dart`
- `packages/flutter_chrome_cast/lib/common/common.dart`
- `packages/flutter_chrome_cast/lib/common/hls_segment_format.dart`
- `packages/flutter_chrome_cast/lib/common/hls_video_segment_format.dart`
- `packages/flutter_chrome_cast/lib/common/image.dart`
- `packages/flutter_chrome_cast/lib/common/live_seekable_range.dart`
- `packages/flutter_chrome_cast/lib/common/queue_data.dart`
- `packages/flutter_chrome_cast/lib/common/rfc5646_language.dart`
- `packages/flutter_chrome_cast/lib/common/text_track_edge_type.dart`
- `packages/flutter_chrome_cast/lib/common/text_track_font_style.dart`
- `packages/flutter_chrome_cast/lib/common/text_track_style.dart`
- `packages/flutter_chrome_cast/lib/common/text_track_window_type.dart`
- `packages/flutter_chrome_cast/lib/common/user_action.dart`
- `packages/flutter_chrome_cast/lib/common/user_action_state.dart`
- `packages/flutter_chrome_cast/lib/common/vast_ads_request.dart`
- `packages/flutter_chrome_cast/lib/common/volume.dart`
- `packages/flutter_chrome_cast/lib/entities/cast_device.dart`
- `packages/flutter_chrome_cast/lib/entities/cast_media_status.dart`
- `packages/flutter_chrome_cast/lib/entities/cast_options.dart`
- `packages/flutter_chrome_cast/lib/entities/cast_session.dart`
- `packages/flutter_chrome_cast/lib/entities/discovery_criteria.dart`
- `packages/flutter_chrome_cast/lib/entities/load_options.dart`
- `packages/flutter_chrome_cast/lib/entities/media_metadata/generic_media_metadata.dart`
- `packages/flutter_chrome_cast/lib/entities/media_metadata/media_metadata.dart`
- `packages/flutter_chrome_cast/lib/entities/media_metadata/movie_media_metadata.dart`
- `packages/flutter_chrome_cast/lib/entities/media_metadata/music_track_media_metadata.dart`
- `packages/flutter_chrome_cast/lib/entities/media_metadata/photo_media_metadata.dart`
- `packages/flutter_chrome_cast/lib/entities/media_metadata/tv_show_media_metadata.dart`
- `packages/flutter_chrome_cast/lib/entities/media_seek_option.dart`
- `packages/flutter_chrome_cast/lib/entities/queue_item.dart`
- `packages/flutter_chrome_cast/lib/entities/request.dart`
- `packages/flutter_chrome_cast/lib/entities/track.dart`
- `packages/flutter_chrome_cast/lib/enums/connection_satate.dart`
- `packages/flutter_chrome_cast/lib/enums/enums.dart`
- `packages/flutter_chrome_cast/lib/enums/idle_reason.dart`
- `packages/flutter_chrome_cast/lib/enums/media_metadata_type.dart`
- `packages/flutter_chrome_cast/lib/enums/media_resume_state.dart`
- `packages/flutter_chrome_cast/lib/enums/player_state.dart`
- `packages/flutter_chrome_cast/lib/enums/repeat_mode.dart`
- `packages/flutter_chrome_cast/lib/enums/stream_type.dart`
- `packages/flutter_chrome_cast/lib/enums/text_track_type.dart`
- `packages/flutter_chrome_cast/lib/enums/track_type.dart`
- `packages/flutter_chrome_cast/lib/lib.dart`
- `packages/flutter_chrome_cast/lib/models/models.dart`
- `packages/flutter_chrome_cast/lib/utils/extensions.dart`
- `packages/flutter_chrome_cast/lib/utils/functions.dart`
- `packages/flutter_chrome_cast/lib/widgets/cast_volume.dart`
- `packages/flutter_chrome_cast/lib/widgets/expanded_player.dart`
- `packages/flutter_chrome_cast/lib/widgets/mini_controller.dart`

## 2. Classi potenzialmente inutilizzate

- `GoogleCastDiscoveryCriteria` in `packages/flutter_chrome_cast/lib/entities/discovery_criteria.dart`
- `AnalyticsConfigDev` in `lib/config/analytics_config.dart`
- `ImagePreloader` in `lib/utils/image_cache.dart`

## 3. Funzioni top-level potenzialmente inutilizzate

- `createTestSongJsonList()` in `test/test_helpers.dart`
- `createTestAlbumJsonList()` in `test/test_helpers.dart`
- `createTestArtistJsonList()` in `test/test_helpers.dart`

## 4. Rischi di memory leak (controller/risorse non disposti)

- `ctrl` (TextEditingController) in `lib/widgets/desktop_navigation_sidebar.dart` — NON ha nemmeno un metodo dispose()
- `with` (ChangeNotifier) in `lib/providers/player_provider.dart` — ha dispose() ma non chiude questo campo
- `get` (AudioPlayer) in `lib/providers/player_provider.dart` — ha dispose() ma non chiude questo campo
- `with` (ChangeNotifier) in `lib/services/usage_time_service.dart` — NON ha nemmeno un metodo dispose()
- `_player` (AudioPlayer) in `lib/services/audio_handler.dart` — NON ha nemmeno un metodo dispose()
- `get` (AudioPlayer) in `lib/services/audio_handler.dart` — NON ha nemmeno un metodo dispose()
- `Section` (Timer) in `lib/widgets/now_playing/now_playing_more_menu.dart` — NON ha nemmeno un metodo dispose()

## 5. Dipendenze in pubspec.yaml mai importate nel codice

- `battery_plus` (dependencies) — nessun `import 'package:...'` trovato nel codice
- `collection` (dependencies) — nessun `import 'package:...'` trovato nel codice
- `cupertino_icons` (dependencies) — nessun `import 'package:...'` trovato nel codice
- `flutter_launcher_icons` (dev_dependencies) — codegen/tool: normale se non è mai importato direttamente
- `flutter_lints` (dev_dependencies) — codegen/tool: normale se non è mai importato direttamente
- `integration_test` (dev_dependencies) — nessun `import 'package:...'` trovato nel codice
- `just_audio_windows` (dependencies) — nessun `import 'package:...'` trovato nel codice
- `media_kit_libs_linux` (dependencies) — nessun `import 'package:...'` trovato nel codice
- `mockito` (dev_dependencies) — nessun `import 'package:...'` trovato nel codice

> Nota: prima di rimuoverle, controlla che non siano usate solo in `pubspec.yaml` stesso (es. font, asset generator) o via codegen/build_runner.

## 6. Errori/warning di compilazione (`dart analyze`)

`dart` non è stato trovato nel PATH: esegui manualmente `dart analyze` o `flutter analyze` nel progetto per questa parte.