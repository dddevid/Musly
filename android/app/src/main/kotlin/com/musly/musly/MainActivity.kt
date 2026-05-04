package com.devid.musly

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        flutterEngine.plugins.add(AndroidAutoPlugin)
        
        flutterEngine.plugins.add(AndroidSystemPlugin)
        
        flutterEngine.plugins.add(BluetoothAvrcpPlugin)
        
        flutterEngine.plugins.add(SamsungIntegrationPlugin)
        
        // Register lyrics plugin for lock screen lyrics support
        LyricsPlugin.registerWith(flutterEngine)

        // Register pitch plugin for ExoPlayer pitch control
        PitchPlugin.registerWith(flutterEngine)
    }
}
