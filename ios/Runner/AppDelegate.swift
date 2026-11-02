import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure audio session for background playback
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, mode: .default, options: [])
      try audioSession.setActive(true)
      print("Audio session configured for background playback")
    } catch {
      print("Failed to configure audio session: \(error)")
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // UIScene lifecycle: the FlutterViewController and its engine are created
  // when the window scene connects, after didFinishLaunchingWithOptions has
  // returned (the app delegate's window is nil there). Plugins, method
  // channels and platform views are registered here instead.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    let registry = engineBridge.pluginRegistry
    GeneratedPluginRegistrant.register(with: registry)

    // iOS System Integration Plugin
    if let registrar = registry.registrar(forPlugin: "iOSSystemPlugin") {
      iOSSystemPlugin.register(with: registrar)
    }

    // iOS Bluetooth/CarPlay Plugin
    if let registrar = registry.registrar(forPlugin: "iOSBluetoothPlugin") {
      iOSBluetoothPlugin.register(with: registrar)
    }

    // AirPlay button platform view
    if let registrar = registry.registrar(forPlugin: "AirPlayButtonFactory") {
      registerAirPlayButtonFactory(with: registrar)
    }
  }
  
  override func applicationWillTerminate(_ application: UIApplication) {
    // Clean up audio session
    let audioSession = AVAudioSession.sharedInstance()
    try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
  }
}
