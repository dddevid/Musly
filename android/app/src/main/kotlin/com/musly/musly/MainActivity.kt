package com.devid.musly

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        flutterEngine.plugins.add(AndroidAutoPlugin)
        
        flutterEngine.plugins.add(AndroidSystemPlugin)
        
        flutterEngine.plugins.add(BluetoothAvrcpPlugin)
        
        flutterEngine.plugins.add(SamsungIntegrationPlugin)
    }
}
