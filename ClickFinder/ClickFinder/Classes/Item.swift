//
//  Item.swift
//
//  ClickFinder
//
//  Created by Ivan Pavic (ivan.pavic@student.supsi.ch) and Patrick Valnegri(patrick.valnegri@student.supsi.ch) on 30.03.19.
//  Copyright © 2019. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

struct ItemConstant {
    static let nameKey = "name"
    static let iconKey = "icon"
    static let uuidKey = "uuid"
    static let majorKey = "major"
    static let minorKey = "minor"
}

/*
 Class Item representing an item to which the user hooks an iBeacon
 */
class Item: NSObject{
    var name: String
    var photo: UIImage
    let uuid: UUID
    let majorValue: CLBeaconMajorValue
    let minorValue: CLBeaconMinorValue
    var type: String
    
    // This property stores the last CLBeacon instance seen for this specific item, used for proximity informations
    var beacon: CLBeacon?
    
    init(name: String, photo: UIImage, uuid: UUID, majorValue: Int, minorValue: Int, type: String) {
        self.name = name
        self.photo = photo
        self.uuid = uuid
        self.majorValue = CLBeaconMajorValue(majorValue)
        self.minorValue = CLBeaconMinorValue(minorValue)
        self.type = type
    }
    
    //CLLocationManager, expects you to provide a CLBeaconRegion instance in order to begin monitoring a region.
    //This returns a new CLBeaconRegion instance derived from the current Item
    func asBeaconRegion() -> CLBeaconRegion {
        return CLBeaconRegion(proximityUUID: uuid,
                              major: majorValue,
                              minor: minorValue,
                              identifier: name)
    }
    
    //returns the proximity
    func nameForProximity(_ proximity: CLProximity) -> String {
        switch proximity {
        case .unknown:
            return "Unknown"
        case .immediate:
            return "<10cm"
        case .near:
            return "<10m"
        case .far:
            return ">10m"
        }
    }
    
    // toString of an iBeacon
    func locationString() -> String {
        guard let beacon = beacon else { return "Location: Unknown" }
        let proximity = nameForProximity(beacon.proximity)
        let accuracy = String(format: "%.2f", beacon.accuracy)
        
        var location = "Location: \(proximity)"
        if beacon.proximity != .unknown {
            location += " (approx. \(accuracy)m)"
        }
        
        return location
    }
}

func ==(item: Item, beacon: CLBeacon) -> Bool {
    return ((beacon.proximityUUID.uuidString == item.uuid.uuidString)
        && (Int(truncating: beacon.major) == Int(item.majorValue))
        && (Int(truncating: beacon.minor) == Int(item.minorValue)))
}

func printBeacon(beacon: CLBeacon?){
    print("Beacon: \(beacon!.proximityUUID.uuidString) (minor: \(Int(truncating: beacon!.major)), major: \(Int(truncating: beacon!.minor)))")
}

func printItem(item: Item){
    print("Item: \(item.uuid.uuidString); \(Int(item.majorValue)); \(Int(item.minorValue))")
}

func itemAsString(item: Item) -> String{
    return "UUID: \(item.uuid.uuidString)\nMajor:\(Int(item.majorValue))\nMinor:\(Int(item.minorValue))\n"
}
