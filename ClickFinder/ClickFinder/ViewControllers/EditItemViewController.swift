//
//  EditViewController.swift
//  clickFinder
//
//  Created by Ivan Pavic on 19.04.19.
//  Copyright © 2019 Ray Wenderlich. All rights reserved.
//

import Foundation
import UIKit

var itemToEdit: Item?

class EditItemViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var uuid: UILabel!
    @IBOutlet weak var major: UILabel!
    @IBOutlet weak var minor: UILabel!
    
    var delegate: ItemsViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if itemToEdit != nil{
            name.text = itemToEdit?.name
            uuid.text = itemToEdit?.uuid.uuidString
            //major.text = "\(String(describing: itemToEdit?.majorValue))"
            //minor.text = "\(String(describing: itemToEdit?.minorValue))"
        }
        
    }
    
    @IBAction func editItem(_ sender: Any) {
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
