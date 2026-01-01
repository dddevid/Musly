package com.devid.musly

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Plugin for Bluetooth AVRCP integration
 * Handles metadata transmission and control from Bluetooth audio devices
 */
object BluetoothAvrcpPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    
    private const val TAG = "BluetoothAvrcpPlugin"
    private const val METHOD_CHANNEL = "com.devid.musly/bluetooth_avrcp"
    private const val EVENT_CHANNEL = "com.devid.musly/bluetooth_avrcp_events"
    
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    
    private var bluetoothHelper: BluetoothMediaHelper? = null
    
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel?.setMethodCallHandler(this)
        
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                bluetoothHelper?.setEventSink(events)
            }
            
            override fun onCancel(arguments: Any?) {
                eventSink = null
                bluetoothHelper?.setEventSink(null)
            }
        })
        
        context?.let { ctx ->
            bluetoothHelper = BluetoothMediaHelper(ctx)
        }
        
        Log.d(TAG, "BluetoothAvrcpPlugin attached")
    }
    
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        bluetoothHelper?.dispose()
        bluetoothHelper = null
        
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        context = null
    }
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val helper = bluetoothHelper
        if (helper == null) {
            result.error("NOT_INITIALIZED", "BluetoothMediaHelper not initialized", null)
            return
        }
        
        helper.onMethodCall(call, result)
    }
}
