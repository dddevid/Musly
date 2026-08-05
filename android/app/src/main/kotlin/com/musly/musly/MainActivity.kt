package com.devid.musly

import com.ryanheise.audioservice.AudioServiceFragmentActivity

// Extends AudioServiceFragmentActivity so the activity shares its Flutter
// engine with the audio_service MediaBrowserService (Android Auto). Custom
// platform-channel plugins (AndroidSystemPlugin, Bluetooth AVRCP, Samsung
// integration, lyrics, pitch, Dolby Atmos) are registered once, on that same
// shared engine, by MuslyApplication — not here — so they're also available
// on a headless Android Auto cold start, when this Activity is never created.
class MainActivity : AudioServiceFragmentActivity()
