package com.felnanuke.google_cast

import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.util.Log
import android.widget.MediaController
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.mediarouter.app.MediaRouteButton
import androidx.mediarouter.app.MediaRouteControllerDialog
import androidx.mediarouter.media.MediaRouter
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import com.google.android.gms.cast.LaunchOptions
import com.google.android.gms.cast.framework.CastButtonFactory
import com.google.android.gms.cast.framework.CastStateListener
import java.util.concurrent.Executors
import kotlin.system.exitProcess

private const val TAG = "CastContext"

class CastContextMethodChannel : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context
    private val discoveryManager = DiscoveryManagerMethodChannel()
    private lateinit var sessionManagerMethodChannel: SessionManagerMethodChannel
    private lateinit var nearbyWifiDevicesPermissionLauncher: ActivityResultLauncher<String>
    private val executor = Executors.newSingleThreadExecutor()


    //FlutterPlugin
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {

        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.felnanuke.google_cast.context")
        channel.setMethodCallHandler(this)
        discoveryManager.onAttachedToEngine(binding)
        sessionManagerMethodChannel = SessionManagerMethodChannel(discoveryManager)
        sessionManagerMethodChannel.onAttachedToEngine(binding)

    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }


    // MethodCallHandler
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setSharedInstance" -> setSharedInstance(call.arguments, result)
            else -> result.notImplemented()
        }
    }

    private fun setupActivityResult(activity: ComponentActivity) {
        nearbyWifiDevicesPermissionLauncher =
            activity.registerForActivityResult(ActivityResultContracts.RequestPermission()) { isGranted: Boolean ->
                if (isGranted) {

                }
            }
        exitProcess(1)
    }


    private fun setSharedInstance(arguments: Any?, result: MethodChannel.Result) {
        val map = arguments as HashMap<*, *>
        val optionsBuilder = CastOptions.Builder()
        optionsBuilder.setReceiverApplicationId(map["appId"] as String)
        val launcherOptions = LaunchOptions.Builder().setAndroidReceiverCompatible(true).build()
        optionsBuilder.setLaunchOptions(launcherOptions)
        optionsBuilder.setResumeSavedSession(true)
        optionsBuilder.setEnableReconnectionService(true)
        GoogleCastOptionsProvider.options = optionsBuilder.build()
        CastContext.getSharedInstance(appContext).sessionManager.addSessionManagerListener(sessionManagerMethodChannel)
        result.success(true)

    }

}