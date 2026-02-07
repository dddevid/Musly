package com.felnanuke.google_cast

import android.content.Context
import android.util.Log
import androidx.mediarouter.app.MediaRouteButton
import androidx.mediarouter.app.MediaRouteDialogFactory
import androidx.mediarouter.media.MediaControlIntent
import androidx.mediarouter.media.MediaRouteSelector
import androidx.mediarouter.media.MediaRouter
import com.felnanuke.google_cast.extensions.toMap
import com.google.android.gms.cast.CastDevice
import com.google.android.gms.cast.CastMediaControlIntent
import com.google.android.gms.cast.framework.CastButtonFactory
import com.google.android.gms.cast.framework.CastContext
import com.google.gson.Gson
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.*
import kotlin.system.exitProcess

private const val TAG = "DiscoveryManager"

class DiscoveryManagerMethodChannel : FlutterPlugin, MethodChannel.MethodCallHandler {

    lateinit var channel: MethodChannel
    val routerCallBack: DiscoveryRouterCallback = DiscoveryRouterCallback()
    val router: MediaRouter
        get() = MediaRouter.getInstance(context)
    private lateinit var context: Context


    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(binding.binaryMessenger, "com.felnanuke.google_cast.discovery_manager")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startDiscovery" -> startDiscovery()
            "stopDiscovery" -> stopDiscovery()
        }
    }

    private fun stopDiscovery() {

        router.removeCallback(routerCallBack)
    }

    private fun startDiscovery() {
        router.removeCallback(routerCallBack)
        val selector = MediaRouteSelector.Builder()
            .addControlCategories(listOf(CastMediaControlIntent.categoryForRemotePlayback()))
            .build()
        router.addCallback(
            selector, routerCallBack, MediaRouter.CALLBACK_FLAG_REQUEST_DISCOVERY
        )

        routerCallBack.getCastDevicesMap()
    }

    inner class DiscoveryRouterCallback : MediaRouter.Callback() {

        override fun onRouteUnselected(
            router: MediaRouter, route: MediaRouter.RouteInfo, reason: Int
        ) {
            super.onRouteUnselected(router, route, reason)

            print("routes ${router.routes.size}")
        }

        override fun onRouteAdded(router: MediaRouter, route: MediaRouter.RouteInfo) {
            super.onRouteAdded(router, route)
            getCastDevicesMap()
        }

        override fun onRouteRemoved(router: MediaRouter, route: MediaRouter.RouteInfo) {
            super.onRouteRemoved(router, route)
            getCastDevicesMap()
        }

        override fun onRouteChanged(router: MediaRouter, route: MediaRouter.RouteInfo) {
            super.onRouteChanged(router, route)
            getCastDevicesMap()
        }

        override fun onRouteVolumeChanged(router: MediaRouter, route: MediaRouter.RouteInfo) {
            super.onRouteVolumeChanged(router, route)
            getCastDevicesMap()
        }


        override fun onProviderAdded(router: MediaRouter, provider: MediaRouter.ProviderInfo) {
            super.onProviderAdded(router, provider)
            print("routes ${router?.routes?.size}")
        }

        override fun onProviderRemoved(router: MediaRouter, provider: MediaRouter.ProviderInfo) {
            super.onProviderRemoved(router, provider)
            print("routes ${router.routes.size}")
        }

        override fun onProviderChanged(router: MediaRouter, provider: MediaRouter.ProviderInfo) {
            super.onProviderChanged(router, provider)
            print("routes ${router.routes.size}")
        }

        private fun getCastDevice(routeInfo: MediaRouter.RouteInfo): Map<*, *>? {
            val device = CastDevice.getFromBundle(routeInfo.extras)
            return device?.let {
                device.toMap()
            }


        }

        fun getCastDevicesMap() {
            val devices = mutableListOf<kotlin.collections.Map<*, *>>()
            for (route in router.routes) {
                val device = getCastDevice(route)
                if (device != null) {
                    devices.add(device)
                }
            }
            val json = Gson().toJson(devices)
            this@DiscoveryManagerMethodChannel.channel.invokeMethod("onDevicesChanged", json)
            Log.w(TAG, "onDevicesChanged $json")
        }
    }

    fun selectRoute(id: String) {
        val routes = router?.routes
        val selectedRoute = routes?.find {
            val device = CastDevice.getFromBundle(it.extras)
            device?.deviceId == id
        }
        if (selectedRoute != null) {
            this.router?.selectRoute(selectedRoute)
        }
    }


}