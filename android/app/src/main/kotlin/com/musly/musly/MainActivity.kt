package com.devid.musly

import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// Extends AudioServiceFragmentActivity so the activity shares its Flutter
// engine with the audio_service MediaBrowserService (Android Auto).
class MainActivity : AudioServiceFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        flutterEngine.plugins.add(AndroidSystemPlugin)
        
        flutterEngine.plugins.add(BluetoothAvrcpPlugin)
        
        flutterEngine.plugins.add(SamsungIntegrationPlugin)
        
        // Register lyrics plugin for lock screen lyrics support
        LyricsPlugin.registerWith(flutterEngine)

        // Register pitch plugin for ExoPlayer pitch control
        PitchPlugin.registerWith(flutterEngine)

        // Register Dolby Atmos plugin for device-capability detection
        DolbyAtmosPlugin.registerWith(flutterEngine, this)
    }
}
