//
//  MediaMetatadaExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 28/06/22.
//

import Foundation
import GoogleCast



extension GCKMediaMetadata {
    func toMap() -> Dictionary<String,Any?> {
        var dict = Dictionary<String,Any?>()
        dict["type"] = self.metadataType.rawValue
        dict["images"] =  (self.images() as! [GCKImage]).map{
            image in
            image.toMap()
            
        }
        let creationDate = self.date(forKey: kGCKMetadataKeyCreationDate)
        let releaseDate = self.date(forKey: kGCKMetadataKeyReleaseDate)
        let broadCastDate = self.date(forKey: kGCKMetadataKeyBroadcastDate)
        let title = self.string(forKey: kGCKMetadataKeyTitle)
        let subtitle = self.string(forKey: kGCKMetadataKeySubtitle)
        let artist = self.string(forKey: kGCKMetadataKeyArtist)
        let albumArtist = self.string(forKey: kGCKMetadataKeyAlbumArtist)
        let albumTitle = self.string(forKey: kGCKMetadataKeyAlbumTitle)
        let albumComposer = self.string(forKey: kGCKMetadataKeyComposer)
        let albumDiscNumber = self.integer(forKey: kGCKMetadataKeyDiscNumber)
        let albumTrackNumber = self.integer(forKey: kGCKMetadataKeyTrackNumber)
        let seasonNumber = self.integer(forKey: kGCKMetadataKeySeasonNumber)
        let episodeNumber = self.integer(forKey: kGCKMetadataKeyEpisodeNumber)
        let serieTitle = self.string(forKey: kGCKMetadataKeySeriesTitle)
        let studio = self.string(forKey: kGCKMetadataKeyStudio)
        let width = self.string(forKey: kGCKMetadataKeyWidth)
        let height = self.string(forKey: kGCKMetadataKeyHeight)
        let locationName = self.string(forKey: kGCKMetadataKeyLocationName)
        let locationLatitude = self.double(forKey: kGCKMetadataKeyLocationLatitude)
        let locationLongitude = self.double(forKey: kGCKMetadataKeyLocationLongitude)
        dict["creationDate"] = creationDate?.timeIntervalSince1970
        dict["releaseDate"] = releaseDate?.timeIntervalSince1970
        dict["broadcastDate"] = broadCastDate?.timeIntervalSince1970
        dict["title"] = title
        dict["subtitle"] = subtitle
        dict["artist"] = artist
        dict["albumArtist"] = albumArtist
        dict["albumTitle"] = albumTitle
        dict["composer"] = albumComposer
        dict["discNumber"] = albumDiscNumber
        dict["trackNumber"] = albumTrackNumber
        dict["seasonNumber"] = seasonNumber
        dict["episodeNumber"] = episodeNumber
        dict["serieTitle"] = serieTitle
        dict["studio"] = studio
        dict["width"] = width
        dict["height"] = height
        dict["locationName"] = locationName
        dict["locationLatitude"] = locationLatitude
        dict["locationLongitude"] = locationLongitude
        return dict
        
    }
    
    
    static func fromMap(_ imulatbleDict : Dictionary<String, Any >) ->  GCKMediaMetadata? {
        var mutableDict = imulatbleDict
       
        
       guard  let metadataType = GCKMediaMetadataType.init(rawValue: mutableDict["metadataType"] as! Int) else {
           return nil
           
       }
        mutableDict.removeValue(forKey: "metadataType")
        let metadata = GCKMediaMetadata.init(metadataType: metadataType)
        
        if let images = mutableDict["images"] as? [Dictionary<String, Any>] {
            for image in images {

            guard let url = URL.init(string: image["url"] as? String ?? "" ) else {
                    continue
                }    
                metadata.addImage(GCKImage.init(url: url, width: image["width"] as? Int ?? 0 , height: image["height"] as? Int ?? 0 ))
                
            }
        }
        
        mutableDict.removeValue(forKey: "images")
        
        
      
        for mapValue in mutableDict{
            switch mapValue.value {
            case is String:
                metadata.setString(mapValue.value as! String, forKey: mapValue.key)
                break
            case is Int:
                metadata.setInteger(mapValue.value as! Int, forKey: mapValue.key)
                break
            default:
                break
            }
            
            switch mapValue.key {
            case "broadcastDate":
                let  date = Date(timeIntervalSince1970:  mapValue.value as! TimeInterval / 1000)
                metadata.setDate(date, forKey: kGCKMetadataKeyBroadcastDate)
                break
            case "releaseDate":
                let  date = Date(timeIntervalSince1970:  mapValue.value as! TimeInterval / 1000)
                metadata.setDate(date, forKey: kGCKMetadataKeyReleaseDate)
                break
            case "creationDate":
                let  date = Date(timeIntervalSince1970:  mapValue.value as! TimeInterval / 1000)
                metadata.setDate(date, forKey: kGCKMetadataKeyCreationDate)
                
                break
            default:
                break
            }
            
        }

        
        return metadata
        
        
    }
}
