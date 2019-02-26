//
//  AppUser+CoreDataProperties.swift
//  BeaconTester
//
//  Created by Vanni Galli on 11.11.16.
//  Copyright © 2016 Vanni Galli. All rights reserved.
//

import Foundation
import CoreData


extension AppUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppUser> {
        return NSFetchRequest<AppUser>(entityName: "AppUser");
    }

    @NSManaged public var userId: String?
    @NSManaged public var first_name: String?
    @NSManaged public var last_name: String?
    @NSManaged public var email: String?
    @NSManaged public var tel: String?

}
