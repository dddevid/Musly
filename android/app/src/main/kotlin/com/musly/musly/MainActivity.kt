package com.devid.musly

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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
