import Flutter
import UIKit
import MediaPlayer
import AVFoundation
import ExternalAccessory

public class iOSBluetoothPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private static let methodChannelName = "com.devid.musly/bluetooth_avrcp"
    private static let eventChannelName = "com.devid.musly/bluetooth_avrcp_events"
    
    private var eventSink: FlutterEventSink?
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    
    private let nowPlayingCenter = MPNowPlayingInfoCenter.default()
    private var audioSession = AVAudioSession.sharedInstance()
    
    private var connectedDevices: [[String: Any]] = []
    private var isMonitoring = false
    
    private var currentArtworkURL: String?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = iOSBluetoothPlugin()
        
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
        
        print("iOSBluetoothPlugin registered")
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize()
            result(nil)
            
        case "getConnectedDevices":
            refreshConnectedDevices()
            result(connectedDevices)
            
        case "updatePlaybackState":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            updatePlaybackState(args: args)
            result(nil)
            
        case "updatePosition":
            if let args = call.arguments as? [String: Any],
               let position = args["position"] as? Int {
                updatePosition(position)
            }
            result(nil)
            
        case "updateAlbumArt":
            if let args = call.arguments as? [String: Any],
               let artworkUrl = args["artworkUrl"] as? String {
                currentArtworkURL = artworkUrl
                updateAlbumArt(artworkUrl)
            }
            result(nil)
            
        case "isA2dpConnected":
            result(isBluetoothConnected())
            
        case "setVolume":
            result(nil)
            
        case "registerAbsoluteVolumeControl":
            result(true)
            
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
        setupNotifications()
        refreshConnectedDevices()
        isMonitoring = true
        print("iOSBluetoothPlugin initialized")
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: audioSession
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMediaServerReset),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: nil
        )
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        let wasBluetoothConnected = isBluetoothConnected()
        refreshConnectedDevices()
        let isBluetoothConnectedNow = isBluetoothConnected()
        
        switch reason {
        case .newDeviceAvailable:
            if isBluetoothConnectedNow && !wasBluetoothConnected {
                if let device = getBluetoothDeviceInfo() {
                    sendEvent("deviceConnected", data: ["device": device])
                }
            }
            
        case .oldDeviceUnavailable:
            if !isBluetoothConnectedNow && wasBluetoothConnected {
                if let device = getBluetoothDeviceInfo() {
                    sendEvent("deviceDisconnected", data: ["device": device])
                }
            }
            
        default:
            break
        }
    }
    
    @objc private func handleMediaServerReset(notification: Notification) {
        print("Media server was reset, reinitializing...")
        refreshConnectedDevices()
    }
    
    private func refreshConnectedDevices() {
        connectedDevices.removeAll()
        
        let currentRoute = audioSession.currentRoute
        
        for output in currentRoute.outputs {
            var device: [String: Any] = [:]
            
            switch output.portType {
            case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
                device["address"] = output.uid
                device["name"] = output.portName
                device["isConnected"] = true
                device["supportsAvrcp"] = true
                
                device["avrcpVersion"] = 14
                device["supportsAlbumArt"] = true
                device["supportsBrowsing"] = output.portType == .bluetoothA2DP
                
                connectedDevices.append(device)
                
            case .carAudio:
                device["address"] = output.uid
                device["name"] = "CarPlay"
                device["isConnected"] = true
                device["supportsAvrcp"] = true
                device["avrcpVersion"] = 16
                device["supportsAlbumArt"] = true
                device["supportsBrowsing"] = true
                
                connectedDevices.append(device)
                
            default:
                break
            }
        }
    }
    
    private func isBluetoothConnected() -> Bool {
        let currentRoute = audioSession.currentRoute
        
        for output in currentRoute.outputs {
            if output.portType == .bluetoothA2DP ||
               output.portType == .bluetoothHFP ||
               output.portType == .bluetoothLE ||
               output.portType == .carAudio {
                return true
            }
        }
        
        return false
    }
    
    private func getBluetoothDeviceInfo() -> [String: Any]? {
        return connectedDevices.first
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
        
        currentArtworkURL = artworkUrl
        
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
    
    private func updatePosition(_ position: Int) {
        guard var currentInfo = nowPlayingCenter.nowPlayingInfo else { return }
        
        currentInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(position) / 1000.0
        nowPlayingCenter.nowPlayingInfo = currentInfo
    }
    
    private func updateAlbumArt(_ artworkUrl: String) {
        guard let url = URL(string: artworkUrl) else { return }
        
        loadArtwork(from: url) { [weak self] artwork in
            guard var currentInfo = self?.nowPlayingCenter.nowPlayingInfo else { return }
            
            if let artwork = artwork {
                currentInfo[MPMediaItemPropertyArtwork] = artwork
                self?.nowPlayingCenter.nowPlayingInfo = currentInfo
            }
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
    
    private func sendEvent(_ event: String, data: [String: Any]?) {
        var eventData: [String: Any] = ["event": event]
        if let data = data {
            eventData.merge(data) { _, new in new }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(eventData)
        }
    }
    
    private func dispose() {
        NotificationCenter.default.removeObserver(self)
        connectedDevices.removeAll()
        isMonitoring = false
        nowPlayingCenter.nowPlayingInfo = nil
    }
    
    deinit {
        dispose()
    }
}
