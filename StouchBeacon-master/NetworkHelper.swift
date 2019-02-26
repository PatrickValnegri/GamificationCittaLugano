import UIKit
import AVFoundation
import CoreData
import CoreLocation

import Alamofire
import Firebase

class NetworkHelper {
    
    static func parameter(key: String, value: String) -> String {
        return String(format: "&%@=%@", key, value)
    }
    
    static func risposta() -> String {
        return parameter(key: "risposta", value: "risposta")
    }
    
    
    static func sendRegistrationRequest() {
        print("in sendRegistrationRequest")
        
        let phoneId = UIDevice.current.identifierForVendor
        let token   = FIRInstanceID.instanceID().token()
        
        if nil == phoneId || nil == token {
            print("token non trovato")
            return
        }
        
        let uri = AppConstants.checkUserDet + parameter(key: "mac", value: phoneId!.uuidString)  + parameter(key: "param", value: "ios_LAC_regId_" + token!) + risposta()
                
        Alamofire.request(uri).responseData { response in            
            if response.result.value != nil {
                if let str = String(data: response.result.value!, encoding: String.Encoding.utf8) {
                    print("sendRegistrationRequest OK")
                    var myId = str.substring(to: str.index(before: str.endIndex))
                    myId = myId.substring(to: myId.index(before: myId.endIndex))
                    myId = myId.substring(to: myId.index(before: myId.endIndex))
                    myId = myId.components(separatedBy: "\"risposta\":")[1].replacingOccurrences(of: "\"", with: "")
                    print("adding user in core data with id: \(myId)")
                    CoreDataHelper.instance.storeUser(userId: myId)
                }
            } else {
                print("not a valid UTF-8 sequence")
            }
        }
    }
    
    static func sendBeacon() {
        print("in sendBeacon")
        
        let beacon = CoreDataHelper.instance.getBeacon()
        let user = CoreDataHelper.instance.getUser();
        
        if nil == beacon || nil == user {
            print("beacon o user nil")
            return
        }
        
        let beaconString = beacon!.id! + "/" + beacon!.major! + "/" + beacon!.minor!
        
        let uri = AppConstants.checkUserDet + parameter(key: "mac", value: beaconString) + parameter(key: "param", value: "Beacon-" + user!.userId!) + risposta()
        
        Alamofire.request(uri).responseData { response in
            if String(data: response.result.value!, encoding: String.Encoding.utf8) != nil {
                print("sendBeacon OK, set SENT in coredata")
                CoreDataHelper.instance.updateBeacon(key: "sent", value: true)
            } else {
                print("not a valid UTF-8 sequence")
            }
        }
    }
    

    static func sendMyBeaconAsMissing(beacon : Beacon) {
        sendMyBeaconInformation(beacon: beacon, param: "true")
    }
    
    static func sendMyBeaconAsFound(beacon : Beacon) {
        sendMyBeaconInformation(beacon: beacon, param: "false")
    }
    
    static func sendMyBeaconInformation(beacon : Beacon, param: String) {
        print("in sendMyBeaconAsMissing")
        
        let user = CoreDataHelper.instance.getUser()
        
        if nil == user {
            print("user nil")
            return
        }
        
        let beaconString = "\(beacon.id!)" + "/" + "\(beacon.major!)" + "/" + "\(beacon.minor!)"
        
        let uri = AppConstants.setHdd + parameter(key: "idUser", value: beaconString) + parameter(key: "param", value: param) + risposta()
        
        print(uri)
        
        Alamofire.request(uri).responseData { response in
            if response.result.value != nil {
                if String(data: response.result.value!, encoding: String.Encoding.utf8) != nil {
                    print("sendMissing OK")
                    // TO DO: aggiungere il beacon a quelli inviati come mancanti
                } else {
                    print("not a valid UTF-8 sequence")
                }
            }
        }
    }
    
    static func sendFoundMissingBeacon(beacon : CLBeacon, location: CLLocationCoordinate2D) {
        print("in sendMissing")
        
        let user = CoreDataHelper.instance.getUser()
        
        if nil == user {
            print("user nil")
            return
        }
        
        let beaconString = "\(beacon.proximityUUID)" + "/" + "\(beacon.major)" + "/" + "\(beacon.minor)"
        let param = user!.userId! + "/" + "\(location.latitude)" + "/" + "\(location.longitude)"
        
        let uri = AppConstants.checkAlarm + parameter(key: "idUser", value: beaconString) +  parameter(key: "param", value: param) + risposta()
        
        print(uri)
        
        Alamofire.request(uri).responseData { response in
            if String(data: response.result.value!, encoding: String.Encoding.utf8) != nil {
                print("sendMissing OK")
                // TO DO: aggiungere il beacon a quelli inviati come mancanti
            } else {
                print("not a valid UTF-8 sequence")
            }
        }
    }
}
