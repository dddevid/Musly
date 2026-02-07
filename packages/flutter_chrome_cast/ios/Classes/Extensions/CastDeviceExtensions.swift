//
//  CastDeviceExtensions.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 24/06/22.
//

import Foundation
import GoogleCast

extension GCKDevice{
    func toDict() ->  Dictionary<String, Any> {
        var dict =  Dictionary<String, Any>()
        dict["networkAddress"] =    self.networkAddress.ipAddress
        dict["servicePort"] =    self.servicePort
        dict["modelName"] =   self.modelName
        dict["statusText"] =   self.statusText
        dict["isOnLocalNetwork"] =   self.isOnLocalNetwork
        dict["type"] =   self.type.rawValue
        dict["category"] =   self.category
        dict["deviceID"] =   self.deviceID
        dict["deviceVersion"] =   self.deviceVersion
        dict["friendlyName"] =   self.friendlyName
        dict["uniqueID"] = self.uniqueID
    
        
        
      
    
     
        return dict
    }
}








