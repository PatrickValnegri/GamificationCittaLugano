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

class AuthViewController: UIViewController {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var surnameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var phonenumberField: UITextField!
    @IBOutlet weak var streetField: UITextField!
    @IBOutlet weak var cityField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    var users = [User]()
    
    //Firebase database reference
    var ref: DatabaseReference!
    var databaseHandle: DatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.background
        
        usernameField.delegate = self
        surnameField.delegate = self
        emailField.delegate = self
        phonenumberField.delegate = self
        streetField.delegate = self
        cityField.delegate = self
        
        loginButton.isEnabled = true;
    }
    
    func persistUser() {
       // let userData = NSKeyedArchiver.archivedData(withRootObject: user!)
    
        //UserDefaults.standard.set(userData, forKey: storedUserKey)
        //UserDefaults.standard.synchronize()
        
        var usersData = [Data]()
        for u in users {
            let userData = NSKeyedArchiver.archivedData(withRootObject: u)
            usersData.append(userData)
        }
        UserDefaults.standard.set(usersData, forKey: storedUserKey)
        UserDefaults.standard.synchronize()
    }
    
    
    func loadUser() {
       // guard let storedUser = UserDefaults.standard.data(forKey: storedUserKey) else { return }
        //guard let userTmp = NSKeyedUnarchiver.unarchiveObject(with: storedUser) as? User else { return }
        
        guard let storedUsers = UserDefaults.standard.array(forKey: storedUserKey) as? [Data] else { return }
        for userData in storedUsers {
            guard let item = NSKeyedUnarchiver.unarchiveObject(with: userData) as? User else { continue }
            users.append(item)
            print("trovato")
            
        }
    }
    
    
    @IBAction func loginTapped(_ sender: UIButton) {
        let username: String = usernameField.text!
        let surname: String = surnameField.text!
        let email: String = emailField.text!
        let phonenumber: String = phonenumberField.text!
        let street: String = streetField.text!
        let city: String = cityField.text!
        
        users.append(User(name: username, surname: surname, email: email, phonenumber: phonenumber, street: street, city: city))
        
        persistUser()
        
        loadUser()
        
        dismiss(animated: true, completion: nil)

    }
    
}

    /*
    @IBAction func fieldChanged(_ sender: UITextField) {
    let validName: String = usernameField.text!
    let validPswd: String = usernameField.text!


    if (validName.isEmpty || validPswd.isEmpty) {
    loginButton.isEnabled = false
    } else {
    loginButton.isEnabled = true
    }

    }
    */

extension AuthViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
