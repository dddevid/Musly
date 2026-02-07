//
//  FlutterGoogleCastSessionMethodChannel.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 24/06/22.
//

import Foundation

class FGCSessionMethodChannel: UIResponder, FlutterPlugin{
    
 private var channel : FlutterMethodChannel?
    
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FGCSessionMethodChannel()
        
        instance.channel = FlutterMethodChannel(name: "google_cast.session", binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
        
    }
    
    
    
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        switch call.method {
            
            case "setDeviceVolume":
            
            
            break
     

        default:
            result(FlutterError(code: "1", message: "No Handler for \(call.method)", details: nil))
            break
            
        }
        
        
        
    }
    
    
}
