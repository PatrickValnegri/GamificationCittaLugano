//
//  AuthViewController.swift
//  clickFinder
//
//  Created by Patrick on 10.03.19.
//  Copyright © 2019 Ray Wenderlich. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase

let storedUserKey = "storedUser"

class UserViewController: UIViewController {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var phonenumberField: UITextField!
    @IBOutlet weak var streetField: UITextField!
    @IBOutlet weak var cityField: UITextField!
    @IBOutlet weak var capField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    var user: User = User(name: "", email: "", phonenumber: "", street: "", city: "", cap: "")
    
    //Firebase database reference
    var ref: DatabaseReference!
    var databaseHandle: DatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
        
        usernameField.delegate = self
        usernameField.backgroundColor = Colors.background
        emailField.delegate = self
        emailField.backgroundColor = Colors.background
        phonenumberField.delegate = self
        phonenumberField.backgroundColor = Colors.background
        streetField.delegate = self
        streetField.backgroundColor = Colors.background
        cityField.delegate = self
        cityField.backgroundColor = Colors.background
        capField.delegate = self
        capField.backgroundColor = Colors.background
        
        loginButton.isEnabled = true;
    }
    
    //Salvare utente in userdetails
    func persistUser() {
        
        var usersData = [Data]()
        //for u in users {
            let userData = NSKeyedArchiver.archivedData(withRootObject: user)
            usersData.append(userData)
        //}
        UserDefaults.standard.set(usersData, forKey: storedUserKey)
        UserDefaults.standard.synchronize()
    }
    
    //Caricare utente da userdetails
    func loadUser() {
        
        guard let storedUsers = UserDefaults.standard.array(forKey: storedUserKey) as? [Data] else { return }
        
        for userData in storedUsers {
            guard let item = NSKeyedUnarchiver.unarchiveObject(with: userData) as? User else { continue }
            user = item
            AppVariables.userName = user.name
            AppVariables.userPhone = user.phonenumber
            print("User name: ", user.name)
            print("User phone: ", user.phonenumber)
        }
    }
    
    
    @IBAction func loginTapped(_ sender: UIButton) {
        
        let username: String = usernameField.text!
        let email: String = emailField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let phonenumber: String = phonenumberField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let street: String = streetField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let city: String = cityField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let cap: String = capField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        user = User(name: username, email: email, phonenumber: phonenumber, street: street, city: city, cap: cap)
        
        persistUser() //salvato in locale
        //loadUser()
        
        updateUserInfo() //salvato nel database di firebase
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func updateUserInfo(){
        
        //FIREBASE REALTIME DATABASE REFERENCE
        ref = Database.database().reference()
        
        let iphoneID = UIDevice.current.identifierForVendor?.uuidString //usato per identificare lo user
        
        let name = usernameField.text
        let phone_number = phonenumberField.text
        let email = emailField.text
        let address = "\(streetField.text!) \(capField.text!) \(cityField.text!)"

        print("Name", name!)
        print("Phone_number", phone_number!)
        print("email", email!)
        print("Address", address)
    
        self.ref.child("users").child(iphoneID!).setValue(
            [
                "name":name!,
                "phone": phone_number!,
                "email": email!,
                "address": address,
                "latid": "0",
                "longid": "0",
            ]
        ){(error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("User could not be saved: \(error).")
            } else {
                print("User saved successfully!")
            }
        }
    }
    
    @IBAction func cancelRegistration(_ sender: Any) {
        let transition: CATransition = CATransition()
        transition.duration = 0.5
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.reveal
        transition.subtype = CATransitionSubtype.fromBottom
        self.view.window!.layer.add(transition, forKey: nil)
        self.dismiss(animated: false, completion: nil)
    }
}

extension UserViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
