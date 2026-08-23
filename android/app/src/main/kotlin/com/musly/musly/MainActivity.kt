package com.devid.musly

import android.app.UiModeManager
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : AudioServiceFragmentActivity() {
    private val CHANNEL = "com.devid.musly/ytdlp"
    private val TV_CHANNEL = "com.devid.musly/tv_mode"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Native Android TV & TV Box detection
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TV_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isTvDevice") {
                var isTv = false
                try {
                    val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager
                    if (uiModeManager != null && uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION) {
                        isTv = true
                    }
                    if (!isTv && packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK)) {
                        isTv = true
                    }
                    if (!isTv && packageManager.hasSystemFeature("android.hardware.type.television")) {
                        isTv = true
                    }
                    if (!isTv && !packageManager.hasSystemFeature(PackageManager.FEATURE_TOUCHSCREEN)) {
                        isTv = true
                    }
                    if (!isTv) {
                        val model = (Build.MODEL ?: "").lowercase()
                        val hardware = (Build.HARDWARE ?: "").lowercase()
                        val brand = (Build.BRAND ?: "").lowercase()
                        val fingerprint = (Build.FINGERPRINT ?: "").lowercase()
                        val tvKeywords = listOf("tv", "box", "firetv", "shield", "bravia", "chromecast", "mibox", "amlogic", "allwinner", "rk3328", "rk3399", "stick")
                        for (kw in tvKeywords) {
                            if (model.contains(kw) || hardware.contains(kw) || brand.contains(kw) || fingerprint.contains(kw)) {
                                isTv = true
                                break
                            }
                        }
                    }
                } catch (e: Exception) {
                    isTv = false
                }
                result.success(isTv)
            } else {
                result.notImplemented()
            }
        }

        try {
            if (!Python.isStarted()) {
                Python.start(AndroidPlatform(this))
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val py = Python.getInstance()
                    val helper = py.getModule("ytdlp_helper")
                    when (call.method) {
                        "getStreamUrl" -> {
                            val videoId = call.argument<String>("videoId") ?: ""
                            val url = helper.callAttr("get_stream_url", videoId).toString()
                            withContext(Dispatchers.Main) { result.success(url) }
                        }
                        "search" -> {
                            val query = call.argument<String>("query") ?: ""
                            val limit = call.argument<Int>("limit") ?: 25
                            val json = helper.callAttr("search", query, limit).toString()
                            withContext(Dispatchers.Main) { result.success(json) }
                        }
                        "searchDual" -> {
                            val query = call.argument<String>("query") ?: ""
                            val limit = call.argument<Int>("limit") ?: 20
                            val json = helper.callAttr("search_dual", query, limit).toString()
                            withContext(Dispatchers.Main) { result.success(json) }
                        }
                        "getVideoInfo" -> {
                            val videoId = call.argument<String>("videoId") ?: ""
                            val json = helper.callAttr("get_video_info", videoId).toString()
                            withContext(Dispatchers.Main) { result.success(json) }
                        }
                        "getPlaylist" -> {
                            val playlistId = call.argument<String>("playlistId") ?: ""
                            val limit = call.argument<Int>("limit") ?: 100
                            val json = helper.callAttr("get_playlist", playlistId, limit).toString()
                            withContext(Dispatchers.Main) { result.success(json) }
                        }
                        "isAvailable" -> {
                            withContext(Dispatchers.Main) { result.success(true) }
                        }
                        else -> {
                            withContext(Dispatchers.Main) { result.notImplemented() }
                        }
                    }
                } catch (e: Exception) {
                    withContext(Dispatchers.Main) {
                        result.error("YTDLP_ERROR", e.message, e.stackTraceToString())
                    }
                }
            }
        }
    }
}
