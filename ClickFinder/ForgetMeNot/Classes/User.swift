//
//  Person.swift
//  clickFinder
//
//  Created by Patrick on 12.03.19.
//  Copyright © 2019 Ray Wenderlich. All rights reserved.
//

import Foundation

struct UserConstant {
    static let nameKey = "name"
    static let surnameKey = "surname"
    static let emailKey = "email"
    static let phonenumberKey = "phonenumber"
    static let stretKey = "street"
    static let cityKey = "city"
}


class User: NSObject, NSCoding {
    
    let name: String
    let surname: String
    let email: String
    let phonenumber: String
    let street: String
    let city: String
    
    init(name: String, surname: String, email: String, phonenumber: String, street: String, city: String ) {
        self.name = name
        self.surname = surname
        self.email = email
        self.phonenumber = phonenumber
        self.street = street
        self.city = city
    }
    
    required init(coder aDecoder: NSCoder) {
        let aName = aDecoder.decodeObject(forKey: UserConstant.nameKey) as? String
        name = aName ?? ""
        let aSurname = aDecoder.decodeObject(forKey: UserConstant.surnameKey) as? String
        surname = aSurname ?? ""
        let aEmail = aDecoder.decodeObject(forKey: UserConstant.emailKey) as? String
        email = aEmail ?? ""
        let aPhonenumber = aDecoder.decodeObject(forKey: UserConstant.phonenumberKey) as? String
        phonenumber = aPhonenumber ?? ""
        let aCity = aDecoder.decodeObject(forKey: UserConstant.cityKey) as? String
        city = aCity ?? ""
        let aStreet = aDecoder.decodeObject(forKey: UserConstant.stretKey) as? String
        street = aStreet ?? ""
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: UserConstant.nameKey)
        aCoder.encode(surname, forKey: UserConstant.surnameKey)
        aCoder.encode(email, forKey: UserConstant.emailKey)
        aCoder.encode(phonenumber, forKey: UserConstant.phonenumberKey)
        aCoder.encode(street, forKey: UserConstant.stretKey)
        aCoder.encode(city, forKey: UserConstant.cityKey)
        
        
    }
    
    
    
}
