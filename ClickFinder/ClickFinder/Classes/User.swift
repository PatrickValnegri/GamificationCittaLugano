//
//  User.swift
//
//  ClickFinder
//
//  Created by Ivan Pavic (ivan.pavic@student.supsi.ch) and Patrick Valnegri(patrick.valnegri@student.supsi.ch) on 12.03.19.
//  Copyright © 2019. All rights reserved.
//

import Foundation

/*
 User registration fields
 */
struct UserConstant {
    static let nameKey = "name"
    static let emailKey = "email"
    static let phonenumberKey = "phonenumber"
    static let stretKey = "street"
    static let cityKey = "city"
    static let capKey = "cap"
}

/*
 Classe User representing a real user
 */
class User: NSObject, NSCoding {
    
    let name: String
    let email: String
    let phonenumber: String
    let street: String
    let city: String
    let cap: String
    
    init(name: String, email: String, phonenumber: String, street: String, city: String, cap:String ) {
        self.name = name
        self.email = email
        self.phonenumber = phonenumber
        self.street = street
        self.city = city
        self.cap = cap
    }
    
    required init(coder aDecoder: NSCoder) {
        let aName = aDecoder.decodeObject(forKey: UserConstant.nameKey) as? String
        name = aName ?? ""
        let aEmail = aDecoder.decodeObject(forKey: UserConstant.emailKey) as? String
        email = aEmail ?? ""
        let aPhonenumber = aDecoder.decodeObject(forKey: UserConstant.phonenumberKey) as? String
        phonenumber = aPhonenumber ?? ""
        let aCity = aDecoder.decodeObject(forKey: UserConstant.cityKey) as? String
        city = aCity ?? ""
        let aStreet = aDecoder.decodeObject(forKey: UserConstant.stretKey) as? String
        street = aStreet ?? ""
        let aCap = aDecoder.decodeObject(forKey: UserConstant.capKey) as? String
        cap = aCap ?? ""
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: UserConstant.nameKey)
        aCoder.encode(email, forKey: UserConstant.emailKey)
        aCoder.encode(phonenumber, forKey: UserConstant.phonenumberKey)
        aCoder.encode(street, forKey: UserConstant.stretKey)
        aCoder.encode(city, forKey: UserConstant.cityKey)
        aCoder.encode(cap, forKey: UserConstant.capKey)
    }
}
