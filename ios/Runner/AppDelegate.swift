import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register custom iOS plugins
    if let controller = window?.rootViewController as? FlutterViewController {
      // iOS System Integration Plugin
      let systemPluginRegistrar = registrar(forPlugin: "iOSSystemPlugin")
      if systemPluginRegistrar != nil {
        iOSSystemPlugin.register(with: systemPluginRegistrar!)
      }
      
      // iOS Bluetooth/CarPlay Plugin
      let bluetoothPluginRegistrar = registrar(forPlugin: "iOSBluetoothPlugin")
      if bluetoothPluginRegistrar != nil {
        iOSBluetoothPlugin.register(with: bluetoothPluginRegistrar!)
      }
    }
    
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
  
  override func applicationWillResignActive(_ application: UIApplication) {
    // Keep audio session active when app goes to background
  }
  
  override func applicationDidEnterBackground(_ application: UIApplication) {
    // Maintain audio playback in background
  }
  
  override func applicationWillTerminate(_ application: UIApplication) {
    // Clean up audio session
    let audioSession = AVAudioSession.sharedInstance()
    try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
  }
}
