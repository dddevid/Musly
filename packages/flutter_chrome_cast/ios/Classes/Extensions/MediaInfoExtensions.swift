//
//  MediaInfoExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 27/06/22.
//

import Foundation
import GoogleCast

extension GCKMediaInformation{
    
    
    static func fromMap(_ arguments: Dictionary<String, Any> ) -> GCKMediaInformation? {
        
        let contentID = arguments["contentID"] as! String
        let streamType = GCKMediaStreamType.unknown
        guard let  contentUrl = URL.init(string: arguments["contentURL"] as! String) else { return nil}
        let builder =  GCKMediaInformationBuilder.init()
        builder.contentID  = contentID
        builder.streamType = streamType
        builder.contentURL = contentUrl
        builder.customData = arguments["customData"]
      
        
    
        if let tracksDict = arguments["tracks"] as? [Dictionary<String, Any>] {
    builder.mediaTracks = tracksDict.map{
                dict in
                GCKMediaTrack.fromMap(dict)
            }
        }
      
        if let metadataDict = arguments["metadata"] {
        builder.metadata = GCKMediaMetadata.fromMap(metadataDict as! Dictionary<String, Any>)
        }
      
        let buildedMediaInfo = builder.build()
        
        return buildedMediaInfo
    
    }
    
    
    
    
    func toMap() -> Dictionary<String, Any> {
        var dict = Dictionary<String, Any>()
        dict["contentID"] = self.contentID
        dict["contentType"] = self.contentType
        dict["streamType"] = self.streamType.rawValue
        dict["contentURL"] = self.contentURL?.absoluteString
        dict["duration"] = self.streamDuration
        dict["metadata"] = self.metadata?.toMap()
        if(self.mediaTracks != nil){
            dict["tracks"] = self.mediaTracks!.map{
                track in
                track.toMap()
                
            }
        }
        
      
        
        
        
        return dict
    }
    
}
