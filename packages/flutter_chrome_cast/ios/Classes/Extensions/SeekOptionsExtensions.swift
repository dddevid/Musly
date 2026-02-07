//
//  SeekOptionsExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 27/06/22.
//

import Foundation
import GoogleCast

extension GCKMediaSeekOptions {
    static func fromMap(args : Dictionary<String, Any>) -> GCKMediaSeekOptions {
        let options = GCKMediaSeekOptions.init()
        options.interval = TimeInterval(args["position"] as! Int)
        options.relative = args["relative"] as! Bool
        options.resumeState = .init(rawValue: args["resumeState"] as! Int) ?? .play
        options.seekToInfinite = args["seekToInfinity"] as! Bool
        return options
    }
}
