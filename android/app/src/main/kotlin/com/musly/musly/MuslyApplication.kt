package com.devid.musly

import android.app.Application
import android.util.Log

/**
 * Custom Application class declared in AndroidManifest.xml via
 * `android:name=".MuslyApplication"`.
 *
 * Android requires this class to exist at process startup.
 * The class itself is intentionally minimal: all custom platform-channel
 * plugin registration (DolbyAtmos, Bluetooth AVRCP, Samsung integration,
 * Lyrics, Pitch, AndroidSystem) happens in [MainActivity.configureFlutterEngine]
 * where the FlutterEngine instance is available.
 */
class MuslyApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        Log.d("MuslyApplication", "Application started")
    }
}

