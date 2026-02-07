package com.felnanuke.google_cast

import android.media.session.MediaSession
import android.util.Log
import com.felnanuke.google_cast.extensions.*
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import com.google.gson.Gson
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
private const val  TAG = "RemoteMediaClient"
class RemoteMediaClientMethodChannel : FlutterPlugin, MethodChannel.MethodCallHandler,
    RemoteMediaClient.Callback(), RemoteMediaClient.ProgressListener {
    private lateinit var channel: MethodChannel
    private val currentRemoteMediaClient: RemoteMediaClient?
        get() =
            CastContext.getSharedInstance()?.sessionManager?.currentCastSession?.remoteMediaClient


    // FlutterPlugin
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(binding.binaryMessenger, "com.felnanuke.google_cast.remote_media_client")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // MethodCallHandler
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadMedia" -> loadMedia(call.arguments as Map<String, Any?>)
            "queueLoadItems" -> queueLoadItems(call.arguments as Map<String, Any?>)
            "queueInsertItems" -> queueInsertItems(call.arguments as Map<String, Any?>)
            "queueInsertItemAndPlay" -> queueInsertItemAndPlay(call.arguments as Map<String, Any?>)
            "queueNextItem" -> queueNextItem()
            "queuePrevItem" -> queuePrevItem()
            "queueJumpToItemWithId" -> queueJumpToItemWithId(call.arguments)
            "queueRemoveItemsWithIds" -> queueRemoveItemsWithIds(call.arguments)
            "queueReorderItems" -> queueReorderItems(call.arguments)
            "seek" -> seek(call.arguments)
            "setActiveTrackIds" -> setActiveTrackIds(call.arguments)
            "setPlaybackRate" -> setPlaybackRate(call.arguments)
            "setTextTrackStyle" -> setTextTrackStyle(call.arguments)
            "play" -> play()
            "pause" -> pause()

        }
    }

    private fun setTextTrackStyle(arguments: Any?) {

    }

    private fun setPlaybackRate(arguments: Any?) {
        val playbackRate = arguments as Double
        currentRemoteMediaClient?.setPlaybackRate(playbackRate)
    }

    private fun setActiveTrackIds(arguments: Any?) {
        arguments as ArrayList<Long>
        val longArray = arguments.map {
            it.toLong()
        }
        currentRemoteMediaClient?.setActiveMediaTracks(longArray.toLongArray())?.addStatusListener {status->
            if(status.isSuccess){

                Log.w(TAG, "setActiveTrackIds success $longArray")
            }
            else {
                Log.w(TAG, "setActiveTrackIds failed $longArray")
            }

        }


    }

    private fun seek(arguments: Any?) {
        arguments as Map<String, Any?>
        val options = GoogleCastSeekOptionsBuilder.fromMap(arguments)
        currentRemoteMediaClient?.seek(options)
    }
    private fun queueReorderItems(arguments: Any?) {
        arguments as Map<String,Any?>
        val itemIds = arguments["itemsIds"] as IntArray
        val beforeItemWithId = (arguments["beforeItemWithId"] as Int?)?: MediaSession.QueueItem.UNKNOWN_ID
        currentRemoteMediaClient?.queueReorderItems(itemIds,beforeItemWithId, JSONObject())
    }
    private fun queueRemoveItemsWithIds(arguments: Any?) {
        arguments as IntArray
        currentRemoteMediaClient?.queueRemoveItems(arguments, JSONObject())
    }

    private fun queueJumpToItemWithId(arguments: Any?) {
        val itemId = arguments as Int
        currentRemoteMediaClient?.queueJumpToItem(itemId, JSONObject())

    }

    private fun queuePrevItem() {
        currentRemoteMediaClient?.queuePrev(JSONObject())
    }

    private fun queueNextItem() {
        currentRemoteMediaClient?.queueNext(JSONObject())
    }

    private fun queueInsertItemAndPlay(arguments: Map<String, Any?>) {
        val item =
            GoogleCastQueueItemBuilder.fromMap(arguments["item"] as Map<String, Any?>) ?: return
        val beforeItemWithId = arguments["beforeItemWithId"] as Int
        var jsonObject = JSONObject()
        currentRemoteMediaClient?.queueInsertAndPlayItem(item, beforeItemWithId, jsonObject)

    }

    private fun queueInsertItems(arguments: Map<String, Any?>) {
        val items =
            GoogleCastQueueItemBuilder.listFromMap(arguments["items"] as List<Map<String, Any?>>)
        val beforeItemWithId = (arguments["beforeItemWithId"] as Int?) ?: MediaSession.QueueItem.UNKNOWN_ID
        var jsonObject = JSONObject()
        currentRemoteMediaClient?.queueInsertItems(
            items.toTypedArray(),
            beforeItemWithId,
            jsonObject
        )

    }

    private fun pause() {
        currentRemoteMediaClient?.pause()
    }

    private fun play() {
        currentRemoteMediaClient?.play()

    }

    private fun queueLoadItems(arguments: Map<String, Any?>) {
        val queueItemsData = arguments["queueItems"] as List<Map<String, Any?>>
        val optionsData = arguments["options"] as Map<String, Any?>
        val startIndex = optionsData["startIndex"] as Int
        val repeatMode = optionsData["repeatMode"] as Int
        val playPosition = optionsData["playPosition"] as Int
        val queueItems = GoogleCastQueueItemBuilder.listFromMap(queueItemsData)
        currentRemoteMediaClient?.queueLoad(
            queueItems.toTypedArray(),
            startIndex,
            repeatMode,
            playPosition.toLong() * 1000,
            JSONObject()
        )
    }

    private fun loadMedia(arguments: Map<String, Any?>) {
        val mediaInfo =
            GoogleCastMediaInfo.fromMap(arguments["mediaInfo"] as Map<String, Any?>) ?: return
        val options = GoogleCastMediaLoadOptions.fromMap(arguments)
        currentRemoteMediaClient?.load(mediaInfo, options)
    }

    fun startListen() {
        currentRemoteMediaClient?.registerCallback(this)
        currentRemoteMediaClient?.addProgressListener(this, 500)
    }

    fun endListen() {
        currentRemoteMediaClient?.removeProgressListener(this)
        currentRemoteMediaClient?.unregisterCallback(this)
    }

    // ProgressListener
    override fun onProgressUpdated(progress: Long, duration: Long) {
        var data = mapOf<String, Any?>(
            "progress" to progress,
            "duration" to duration,
        )
        channel.invokeMethod("onPlayerPositionChanged", data)
    }
    // RemoteMediaCallBack

    override fun onStatusUpdated() {
        super.onStatusUpdated()
        val mediaStatus = currentRemoteMediaClient?.mediaStatus
        val jsonObject = currentRemoteMediaClient?.mediaStatus?.toJson()
        jsonObject?.put("activeTrackIds", Gson().toJson(mediaStatus?.activeTrackIds))
        Log.w(TAG, "onStatusUpdated $jsonObject")
        val json = jsonObject?.toString()
        channel.invokeMethod("onMediaStatusChanged", json)
    }

    override fun onQueueStatusUpdated() {
        super.onQueueStatusUpdated()
        val list = currentRemoteMediaClient?.mediaStatus?.queueItems?.map {
            it.toJson().toString()
        }
        channel.invokeMethod("onQueueStatusChanged", list)


    }
}