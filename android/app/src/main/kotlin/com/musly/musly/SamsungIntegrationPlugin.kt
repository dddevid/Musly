package com.musly.musly

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Plugin for Samsung-specific integrations
 * Handles Edge panels, DeX mode, Samsung Music compatibility, etc.
 */
object SamsungIntegrationPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    
    private const val TAG = "SamsungIntegrationPlugin"
    private const val METHOD_CHANNEL = "com.musly.musly/samsung_integration"
    private const val EVENT_CHANNEL = "com.musly.musly/samsung_integration_events"
    
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    
    private var samsungHelper: SamsungHelper? = null
    
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel?.setMethodCallHandler(this)
        
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                samsungHelper?.setEventSink(events)
            }
            
            override fun onCancel(arguments: Any?) {
                eventSink = null
                samsungHelper?.setEventSink(null)
            }
        })
        
        context?.let { ctx ->
            samsungHelper = SamsungHelper(ctx)
        }
        
        Log.d(TAG, "SamsungIntegrationPlugin attached")
    }
    
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        samsungHelper?.dispose()
        samsungHelper = null
        
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        context = null
    }
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val helper = samsungHelper
        if (helper == null) {
            result.error("NOT_INITIALIZED", "SamsungHelper not initialized", null)
            return
        }
        
        helper.onMethodCall(call, result)
    }
}
