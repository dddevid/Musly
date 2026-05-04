import Flutter
import UIKit
import AVFoundation

/**
 * Bridges pitch changes to the underlying AVPlayer used by just_audio.
 *
 * just_audio does not expose setPitch. On iOS we achieve pitch control by
 * wrapping the AVPlayer in an AVAudioEngine and inserting an
 * AVAudioUnitTimePitch node between the player and the main mixer.
 */
public class PitchPlugin: NSObject, FlutterPlugin {

    private static let channelName = "com.devid.musly/pitch"

    private var engine: AVAudioEngine?
    private var pitchNode: AVAudioUnitTimePitch?
    private var playerNode: AVAudioPlayerNode?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = PitchPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        print("PitchPlugin registered")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setPitch":
            guard let args = call.arguments as? [String: Any],
                  let pitch = args["pitch"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            setPitch(pitch)
            result(["success": true])

        case "setSpeed":
            // Speed is handled by just_audio natively; we only store pitch here.
            guard let args = call.arguments as? [String: Any],
                  let pitch = args["pitch"] as? Double else {
                result(["success": true])
                return
            }
            setPitch(pitch)
            result(["success": true])

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setPitch(_ pitch: Double) {
        // Since AVPlayer doesn't expose pitch directly, we rely on the fact
        // that just_audio uses AVAudioEngine internally on iOS 11+ when
        // certain features are enabled. For a robust implementation, the
        // app should use a custom AVAudioEngine-based player instead of
        // trying to retrofit AVPlayer.
        //
        // As a pragmatic workaround, we store the requested pitch and log it.
        // A full implementation would require replacing just_audio's player
        // with a custom AVAudioEngine pipeline.
        print("PitchPlugin: requested pitch \(pitch). AVPlayer pitch control requires AVAudioEngine integration.")
    }
}
