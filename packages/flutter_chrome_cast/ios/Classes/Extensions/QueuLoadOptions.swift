//
//  QueuLoadOptions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 30/06/22.
//

import Foundation
import GoogleCast

extension GCKMediaQueueLoadOptions {
    static func fromMap (_ args: Dictionary<String, Any>? ) -> GCKMediaQueueLoadOptions? {
        guard args != nil else {
            return nil
        }
        
        let startIndex = args!["startIndex"] as? UInt ?? 0
        let playPosition = args!["playPosition"] as? TimeInterval ?? 0
        let repeatMode = GCKMediaRepeatMode.init(rawValue: args!["repeatMode"] as? Int ?? 0) ?? .off
        let customData = args!["customData"] as? Dictionary<String, Any>
        
        
        let options = GCKMediaQueueLoadOptions.init()
        options.startIndex = startIndex
        options.playPosition = playPosition
        options.repeatMode  = repeatMode
        options.customData = customData
        
        return options
        
    }
}
