//
//  MediaStatusExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 28/06/22.
//

import Foundation
import GoogleCast

extension GCKMediaStatus {
    
    func toMap() -> Dictionary<String, Any> {
    
        var dict = Dictionary<String, Any>()
        dict["mediaSessionID"] = self.mediaSessionID
        dict["playerState"] = self.playerState.rawValue
        dict["playingAd"] = self.playingAd
        dict["idleReason"] = self.idleReason.rawValue
        dict["playbackRate"] = self.playbackRate
        dict["mediaInformation"] = self.mediaInformation?.toMap()
        dict["repeatMode"] = self.queueRepeatMode.rawValue
        dict["activeTrackIds"] = self.activeTrackIDs
        dict["queueHasNextItem"] = self.queueHasNextItem
        dict["queueHasPreviousItem"] =  self.queueHasPreviousItem
        dict["currentItemId"] = self.currentItemID
        return dict
    }
    
    
    
}
