import Flutter
import UIKit
import MediaPlayer
import AVFoundation

public class iOSSystemPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private static let methodChannelName = "com.devid.musly/android_system"
    private static let eventChannelName = "com.devid.musly/android_system_events"
    
    private var eventSink: FlutterEventSink?
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    
    private let commandCenter = MPRemoteCommandCenter.shared()
    private let nowPlayingCenter = MPNowPlayingInfoCenter.default()
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    
    private var showOnLockScreen = true
    private var handleAudioFocus = true
    private var handleMediaButtons = true
    
    private var currentArtworkURL: String?
    private var currentTitle: String = ""
    private var currentArtist: String = ""
    private var isPlaying: Bool = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = iOSSystemPlugin()
        
        let methodChannel = FlutterMethodChannel(
            name: methodChannelName,
            binaryMessenger: registrar.messenger()
        )
        
        let eventChannel = FlutterEventChannel(
            name: eventChannelName,
            binaryMessenger: registrar.messenger()
        )
        
        instance.methodChannel = methodChannel
        instance.eventChannel = eventChannel
        
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
        
        print("iOSSystemPlugin registered")
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            if let args = call.arguments as? [String: Any] {
                showOnLockScreen = args["showOnLockScreen"] as? Bool ?? true
                handleAudioFocus = args["handleAudioFocus"] as? Bool ?? true
                handleMediaButtons = args["handleMediaButtons"] as? Bool ?? true
            }
            initialize()
            result(nil)
            
        case "updatePlaybackState":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            updatePlaybackState(args: args)
            result(nil)
            
        case "setNotificationColor":
            result(nil)
            
        case "requestAudioFocus":
            result(requestAudioFocus())
            
        case "abandonAudioFocus":
            abandonAudioFocus()
            result(nil)
            
        case "updateSettings":
            if let args = call.arguments as? [String: Any] {
                showOnLockScreen = args["showOnLockScreen"] as? Bool ?? showOnLockScreen
                handleAudioFocus = args["handleAudioFocus"] as? Bool ?? handleAudioFocus
                handleMediaButtons = args["handleMediaButtons"] as? Bool ?? handleMediaButtons
            }
            result(nil)
            
        case "getSystemInfo":
            result(getSystemInfo())
            
        case "isSamsungDevice":
            result(false)
            
        case "getAndroidSdkVersion":
            result(0)
            
        case "dispose":
            dispose()
            result(nil)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    private func initialize() {
        setupAudioSession()
        setupRemoteCommandCenter()
        setupNotifications()
        print("iOSSystemPlugin initialized")
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("Audio session configured for playback")
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func setupRemoteCommandCenter() {
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.sendEvent("play", data: nil)
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.sendEvent("pause", data: nil)
            return .success
        }
        
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.sendEvent("stop", data: nil)
            return .success
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.sendEvent("skipNext", data: nil)
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.sendEvent("skipPrevious", data: nil)
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            if self?.isPlaying == true {
                self?.sendEvent("pause", data: nil)
            } else {
                self?.sendEvent("play", data: nil)
            }
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                let position = Int(event.positionTime * 1000)
                self?.sendEvent("seekTo", data: ["position": position])
            }
            return .success
        }
        
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            if let event = event as? MPSkipIntervalCommandEvent {
                let interval = Int(event.interval * 1000)
                self?.sendEvent("seekForward", data: ["interval": interval])
            }
            return .success
        }
        
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            if let event = event as? MPSkipIntervalCommandEvent {
                let interval = Int(event.interval * 1000)
                self?.sendEvent("seekBackward", data: ["interval": interval])
            }
            return .success
        }
        
        print("Remote command center configured")
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: audioSession
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: audioSession
        )
    }
    
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            sendEvent("audioFocusLoss", data: nil)
            
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    sendEvent("audioFocusGain", data: nil)
                }
            }
            
        @unknown default:
            break
        }
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            sendEvent("becomingNoisy", data: nil)
            
        case .newDeviceAvailable:
            print("New audio device connected")
            
        default:
            break
        }
    }
    
    private func updatePlaybackState(args: [String: Any]) {
        let songId = args["songId"] as? String
        let title = args["title"] as? String ?? ""
        let artist = args["artist"] as? String ?? ""
        let album = args["album"] as? String ?? ""
        let artworkUrl = args["artworkUrl"] as? String
        let duration = args["duration"] as? Int ?? 0
        let position = args["position"] as? Int ?? 0
        let playing = args["playing"] as? Bool ?? false
        let trackNumber = args["trackNumber"] as? Int
        let genre = args["genre"] as? String
        let year = args["year"] as? Int
        
        currentTitle = title
        currentArtist = artist
        currentArtworkURL = artworkUrl
        isPlaying = playing
        
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = Double(duration) / 1000.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(position) / 1000.0
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playing ? 1.0 : 0.0
        
        if let trackNumber = trackNumber {
            nowPlayingInfo[MPMediaItemPropertyAlbumTrackNumber] = trackNumber
        }
        
        if let genre = genre {
            nowPlayingInfo[MPMediaItemPropertyGenre] = genre
        }
        
        if let artworkUrl = artworkUrl, let url = URL(string: artworkUrl) {
            loadArtwork(from: url) { [weak self] artwork in
                var info = nowPlayingInfo
                if let artwork = artwork {
                    info[MPMediaItemPropertyArtwork] = artwork
                }
                self?.nowPlayingCenter.nowPlayingInfo = info
            }
        } else {
            nowPlayingCenter.nowPlayingInfo = nowPlayingInfo
        }
    }
    
    private func loadArtwork(from url: URL, completion: @escaping (MPMediaItemArtwork?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            
            DispatchQueue.main.async {
                completion(artwork)
            }
        }.resume()
    }
    
    private func requestAudioFocus() -> Bool {
        do {
            try audioSession.setActive(true)
            return true
        } catch {
            print("Failed to activate audio session: \(error)")
            return false
        }
    }
    
    private func abandonAudioFocus() {
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    private func getSystemInfo() -> [String: Any] {
        let device = UIDevice.current
        return [
            "manufacturer": "Apple",
            "model": device.model,
            "brand": "Apple",
            "sdkVersion": Int(UIDevice.current.systemVersion.split(separator: ".").first ?? "0") ?? 0,
            "release": device.systemVersion,
            "isSamsung": false,
            "hasAudioFocus": audioSession.isOtherAudioPlaying == false
        ]
    }
    
    private func sendEvent(_ event: String, data: [String: Any]?) {
        var eventData: [String: Any] = ["command": event]
        if let data = data {
            eventData.merge(data) { _, new in new }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(eventData)
        }
    }
    
    private func dispose() {
        NotificationCenter.default.removeObserver(self)
        
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.stopCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.togglePlayPauseCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        
        nowPlayingCenter.nowPlayingInfo = nil
        
        abandonAudioFocus()
    }
    
    deinit {
        dispose()
    }
}
