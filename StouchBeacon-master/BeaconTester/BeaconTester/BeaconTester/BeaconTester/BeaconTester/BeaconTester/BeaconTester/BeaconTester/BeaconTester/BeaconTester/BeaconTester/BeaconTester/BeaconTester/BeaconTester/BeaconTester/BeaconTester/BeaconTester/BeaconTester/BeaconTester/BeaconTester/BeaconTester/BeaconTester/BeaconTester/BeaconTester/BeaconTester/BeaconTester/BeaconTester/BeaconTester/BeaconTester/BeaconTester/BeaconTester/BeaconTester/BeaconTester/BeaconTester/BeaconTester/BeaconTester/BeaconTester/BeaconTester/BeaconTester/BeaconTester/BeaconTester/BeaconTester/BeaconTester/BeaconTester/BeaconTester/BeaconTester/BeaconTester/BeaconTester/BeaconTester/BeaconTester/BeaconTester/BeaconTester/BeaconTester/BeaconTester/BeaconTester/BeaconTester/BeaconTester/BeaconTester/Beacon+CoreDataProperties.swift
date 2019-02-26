//
//  Beacon+CoreDataProperties.swift
//  BeaconTester
//
//  Created by Vanni Galli on 17.11.16.
//  Copyright © 2016 Vanni Galli. All rights reserved.
//

import Foundation
import CoreData


extension Beacon {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Beacon> {
        return NSFetchRequest<Beacon>(entityName: "Beacon");
    }

    @NSManaged public var id: String?
    @NSManaged public var major: String?
    @NSManaged public var minor: String?
    @NSManaged public var sent: Bool
    @NSManaged public var isMissing: Bool

}
