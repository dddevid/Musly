package com.devid.musly

import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// Extends AudioServiceFragmentActivity so the activity shares its Flutter
// engine with the audio_service MediaBrowserService (Android Auto). Custom
// platform-channel plugins (AndroidSystemPlugin, Bluetooth AVRCP, Samsung
// integration, lyrics, pitch, Dolby Atmos) are registered once here so
// they're also available on a headless Android Auto cold start.
class MainActivity : AudioServiceFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // FlutterPlugin-based plugins (use the plugin registry).
        flutterEngine.plugins.add(AndroidSystemPlugin)
        flutterEngine.plugins.add(BluetoothAvrcpPlugin)
        flutterEngine.plugins.add(SamsungIntegrationPlugin)

        // Legacy companion-object registerWith() plugins.
        DolbyAtmosPlugin.registerWith(flutterEngine, applicationContext)
        LyricsPlugin.registerWith(flutterEngine)
        PitchPlugin.registerWith(flutterEngine)
    }
}
