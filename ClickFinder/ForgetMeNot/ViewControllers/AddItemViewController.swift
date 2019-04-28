/*
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import FirebaseDatabase
import CoreData

protocol AddBeacon {
    func addBeacon(item: Item)
}

var detailItem = Item(name: "", photo: UIImage(), uuid: AppConstants.uuid, majorValue: 0, minorValue: 0)
var flag = false
var edit = false

class AddItemViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtUUID: UITextField!
    @IBOutlet weak var txtMajor: UITextField!
    @IBOutlet weak var txtMinor: UITextField!
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var btnAdd: UIButton!
    @IBOutlet weak var btnEdit: UIButton!
    
    private let notificationPublisher = NotificationPublisher()
    
    let uuidRegex = try! NSRegularExpression(pattern: "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", options: .caseInsensitive)
    
    var delegate: AddBeacon?
    let allIcons = Icons.allIcons
    var icon = Icons.bag
    
    //Instance of ItemsViewController
    let ivc = ItemsViewController(nibName: nil, bundle: nil)
    //Instance of MainViewController
    let mvc = MainViewController(nibName: nil, bundle: nil)
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate //delegate of AppDelegate    
    
    //FIREBASE REALTIME DATABASE
    var ref: DatabaseReference!
    
    //Image picker
    var imagePicker: UIImagePickerController!
    
    //Item
    var item: Item?
    var isEdit: Bool = false
    var currentIndex: Int = -1
    
//    init(item: Item, currentIndex: Int) {
//        self.item = item
//        self.isEdit = true
//        self.currentIndex = currentIndex
//        super.init(nibName: nil, bundle: nil)
//    }
//    
//    //default constructor
//    required init?(coder aDecoder: NSCoder) {
//        self.item = nil
//        super.init(coder: aDecoder)
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //FIREBASE REALTIME DATABASE REFERENCE
        ref = Database.database().reference()
        
        btnAdd.isEnabled = false
        btnEdit.isHidden = true
        
        ivc.loadItems()
        
        if isEdit {
            txtName.text = item?.name
            txtUUID.text = item?.uuid.uuidString
            txtMajor.text = "\(item!.majorValue)"
            txtMinor.text = "\(item!.minorValue)"
            
            btnAdd.isHidden = true
            btnEdit.isHidden = false
            
            isEdit = false
        }
        
        
        if flag{
            
            flag = false
            txtName.text = detailItem.name
            txtUUID.text = detailItem.uuid.uuidString
            txtMajor.text = "\(detailItem.majorValue)"
            txtMinor.text = "\(detailItem.minorValue)"
            
            // Is name valid?
            let nameValid = (txtName.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count > 0)
            
            // Is UUID valid?
            var uuidValid = false
            let uuidString = txtUUID.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if uuidString.count > 0 {
                uuidValid = (uuidRegex.numberOfMatches(in: uuidString, options: [], range: NSMakeRange(0, uuidString.count)) > 0)
            }
            txtUUID.textColor = (uuidValid) ? .black : .red
            
            // Toggle btnAdd enabled based on valid user entry
            btnAdd.isEnabled = (nameValid && uuidValid)
        }
        
        imgIcon.image = icon.image()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Dismiss keyboard
        self.view.endEditing(true)
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        // Is name valid?
        let nameValid = (txtName.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count > 0)
        
        // Is UUID valid?
        var uuidValid = false
        let uuidString = txtUUID.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if uuidString.count > 0 {
            uuidValid = (uuidRegex.numberOfMatches(in: uuidString, options: [], range: NSMakeRange(0, uuidString.count)) > 0)
        }
        txtUUID.textColor = (uuidValid) ? .black : .red
        
        // Toggle btnAdd enabled based on valid user entry
        btnAdd.isEnabled = (nameValid && uuidValid)
        btnEdit.isEnabled = (nameValid && uuidValid)
    }
    
    @IBAction func btnEdit_Pressed(_ sender: UIButton) {
        
        let uuidString = txtUUID.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard let uuid = UUID(uuidString: uuidString.uppercased()) else { return }
        let major = Int(txtMajor.text!) ?? 0
        let minor = Int(txtMinor.text!) ?? 0
        let name = txtName.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        //TODO aggiungere type e photo
        
        let editedItem = Item(name: name, photo: imgIcon.image!, uuid: uuid, majorValue: major, minorValue: minor)
        print("Indice da modificare", currentIndex)
        print("Capacity lista", ivc.items.isEmpty)
        print("Edited name", editedItem.name)
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Items")
        let context = appDelegate.persistentContainer.viewContext
        
        //Cerca quelli con major e minor che devono essere edidati
        let p1 = NSPredicate(format: "major == %@", Int(ivc.items[currentIndex].majorValue) as NSNumber)
        let p2 = NSPredicate(format: "minor == %@", Int(ivc.items[currentIndex].minorValue) as NSNumber)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2])
        
        //Aggiornamento su coredata
        request.predicate = predicate
        do
        {
            let test = try context.fetch(request)
            
                let editedItem = test[0] as! NSManagedObject
                editedItem.setValue(name, forKey: "name")
                do {
                    try context.save()
                }
                catch
                {
                    print(error)
                }
        }
        catch
        {
            print(error)
        }
        
        //Aggiornamento su firebase
        let beaconID = "\(uuid.uuidString)_\(Int(major))_\(Int(minor))"
        self.ref.child("users").observe(.value, with: { (snapshot) in
            
            if (snapshot.hasChild(beaconID)) {
                self.ref.child("users").child(beaconID).updateChildValues(["name":name]) { //TODO aggiungere type e photo
                    (error:Error?, ref:DatabaseReference) in
                    if let error = error {
                        print("Item not edited: \(error).")
                    } else {
                        print("Item edited successfully!")
                    }
                }
            }
        })
        
        
        indexToEdit = currentIndex
        ivc.items[currentIndex] = editedItem
        print("PROVA", ivc.items[currentIndex].name)
    }
    
    @IBAction func btnAdd_Pressed(_ sender: UIButton) {
        // Create new beacon item
        let uuidString = txtUUID.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard let uuid = UUID(uuidString: uuidString.uppercased()) else { return }
        let major = Int(txtMajor.text!) ?? 0
        let minor = Int(txtMinor.text!) ?? 0
        let name = txtName.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        let newItem = Item(name: name, photo: imgIcon.image!, uuid: uuid, majorValue: major, minorValue: minor)
        
        delegate?.addBeacon(item: newItem)
        
        //this collection is used to keep track of the beacons that have been paired but not still displayed in the items view
        //Da fare solo dopo un pairing
        if (AppConstants.isPairing) {
            self.ivc.itemsToBeAdded.append(newItem)
            self.ivc.addItemToBeAdded(item: newItem) //save it in coredata
            AppConstants.isPairing = false
        }
        
        self.registerBeacon(item: newItem)
        
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Items") as UIViewController
        
        self.present(viewController, animated: false, completion: nil)
        
        notificationPublisher.sendNotification(
            title: "Added a new iBeacon!",
            subtitle: "Pairing successful.",
            body: "ClickFinder",
            badge: 1,
            delayInterval: nil,
            identifier: "added new beacon",
            ring: false
        )
        
        //dismiss(animated: true, completion: nil)
    }
    
    func registerBeacon(item: Item){
        let iphoneID = UIDevice.current.identifierForVendor?.uuidString
        let beaconID = "\(item.uuid.uuidString)_\(Int(item.majorValue))_\(Int(item.minorValue))"
        
        self.ref.child("users").child(beaconID).setValue(
            [
                "latid":"0",
                "longit":"0",
                "mac":beaconID,
                "name":item.name,
                "owner":iphoneID!,
                "switch_hdd": "0",
                "tiposchermo": "Beacon-\(iphoneID!)",
                "type":""
            ]
        ){(error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("Data could not be saved: \(error).")
            } else {
                print("Data saved successfully!")
            }
        }
    }
    
    @IBAction func btnCancel_Pressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func selectFromGallery(_ sender: Any) {
    }
    
    @IBAction func takeBeaconPhoto(_ sender: Any) {
        print("TAKE")
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        imgIcon.image = info[.originalImage] as? UIImage
    }
}

extension AddItemViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allIcons.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell", for: indexPath) as! IconCell
        cell.icon = allIcons[indexPath.row]
        
        return cell
    }
}

extension AddItemViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Enter key hides keyboard
        textField.resignFirstResponder()
        return true
    }
}
