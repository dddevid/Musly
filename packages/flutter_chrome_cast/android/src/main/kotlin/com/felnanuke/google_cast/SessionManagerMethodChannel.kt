package com.felnanuke.google_cast

import android.util.Log
import com.felnanuke.google_cast.extensions.toMap
import com.google.android.gms.cast.framework.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
private const val TAG = "SessionManager"
class SessionManagerMethodChannel(discoveryManager: DiscoveryManagerMethodChannel) : FlutterPlugin,
    MethodChannel.MethodCallHandler, SessionManagerListener<Session> {

    private lateinit var channel: MethodChannel
    private val discoveryManagerMethodChannel: DiscoveryManagerMethodChannel = discoveryManager
    private val remoteMediaClientMethodChannel = RemoteMediaClientMethodChannel()

    private val sessionManager: SessionManager?
        get() {
            return CastContext.getSharedInstance()?.sessionManager
        }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(binding.binaryMessenger, "com.felnanuke.google_cast.session_manager")
        channel.setMethodCallHandler(this)
        remoteMediaClientMethodChannel.onAttachedToEngine(binding)

    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startSessionWithDeviceId" -> startSession(call.arguments, result)
            "endSessionAndStopCasting"-> sessionManager?.endCurrentSession(true)
            "endSession"-> sessionManager?.endCurrentSession(false)
            "setStreamVolume" -> sessionManager?.currentCastSession?.volume = call.arguments as Double

        }
    }

    private fun startSession(arguments: Any?, result: MethodChannel.Result) {
        val deviceId = arguments as String
        Log.w(TAG, "startSession with deviceId: $deviceId")
        discoveryManagerMethodChannel.selectRoute(deviceId)
        result.success(true)

    }


    //SessionManagerLister
    override fun onSessionEnded(session: Session, p1: Int) {
        Log.w(TAG, "onSessionEnded")
        onSessionChanged()
    }

    override fun onSessionEnding(p0: Session) {
        Log.w(TAG, "onSessionEnding")
        onSessionChanged()
    }

    override fun onSessionResumeFailed(p0: Session, p1: Int) {
        Log.w(TAG, "onSessionResumeFailed")
        onSessionChanged()
    }

    override fun onSessionResumed(p0: Session, p1: Boolean) {
        Log.w(TAG, "onSessionResumed")
        remoteMediaClientMethodChannel.startListen()
        onSessionChanged()
    }

    override fun onSessionResuming(p0: Session, p1: String) {
        Log.w(TAG, "onSessionResuming")
        onSessionChanged()
    }

    override fun onSessionStartFailed(p0: Session, p1: Int) {
        Log.w(TAG, "onSessionStartFailed error: $p1")
        onSessionChanged()
    }

    override fun onSessionStarted(session: Session, p1: String) {
        Log.w(TAG, "onSessionStarted")
        remoteMediaClientMethodChannel.startListen()
        onSessionChanged()
    }

    override fun onSessionStarting(p0: Session) {
        Log.w(TAG, "onSessionStarting")
        onSessionChanged()
    }

    override fun onSessionSuspended(p0: Session, p1: Int) {
        Log.w(TAG, "onSessionSuspended")
        onSessionChanged()
    }


    private fun onSessionChanged() {
        val session = sessionManager?.currentCastSession
        val map = session?.toMap()
        Log.w(TAG, "onSessionChanged: $map")
        channel.invokeMethod("onSessionChanged", map)
    }


}