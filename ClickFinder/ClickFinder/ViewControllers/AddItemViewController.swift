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

var detailItem = Item(name: "", photo: UIImage(), uuid: AppConstants.uuid, majorValue: 0, minorValue: 0, type: AppConstants.types[0])
var flag = false
var edit = false

extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }

    func jpeg(_ jpegQuality: JPEGQuality) -> Data? {
        return jpegData(compressionQuality: jpegQuality.rawValue)
    }
}

class AddItemViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource{

    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtUUID: UITextField!
    @IBOutlet weak var txtMajor: UITextField!
    @IBOutlet weak var txtMinor: UITextField!
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var txtType: UITextField!
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

        txtType.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(typeTapped))
        txtType.addGestureRecognizer(tap)

        //Connect picker:
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.isHidden = true
        pickerView.showsSelectionIndicator = true


        btnAdd.isEnabled = false
        btnEdit.isHidden = true

        ivc.loadItems()
        
        imgIcon.image = icon.image()

        if isEdit {
            txtName.text = item?.name
            txtUUID.text = item?.uuid.uuidString
            txtMajor.text = "\(item!.majorValue)"
            txtMinor.text = "\(item!.minorValue)"
            txtType.text = item?.type
            imgIcon.image = item?.photo

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
            btnAdd.isEnabled = (nameValid && uuidValid && txtType.text?.isEmpty ?? false)
        }
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
        if(!isEdit){
            btnAdd.isEnabled = (nameValid && uuidValid)
        }else{
        btnEdit.isEnabled = (nameValid && uuidValid)
        }
    }

    @IBAction func btnEdit_Pressed(_ sender: UIButton) {

        let uuidString = txtUUID.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard let uuid = UUID(uuidString: uuidString.uppercased()) else { return }
        let major = Int(txtMajor.text!) ?? 0
        let minor = Int(txtMinor.text!) ?? 0
        let name = txtName.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let type = txtType.text!

        //Compress the image
        let imageData = imgIcon.image!.jpegData(compressionQuality: 0.25)!
        //Encode to base64
        let strBase64 =  imageData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
        
        let editedItem = Item(name: name, photo: imgIcon.image!, uuid: uuid, majorValue: major, minorValue: minor, type: type)
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
            editedItem.setValue(type, forKey: "type")
            editedItem.setValue(strBase64, forKey: "photo")
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
                self.ref.child("users").child(beaconID).updateChildValues(["name":name, "type":type, "photo":strBase64]) {
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


    @IBAction func btnAdd_pressed(_ sender: Any) {
        AppVariables.pairingIsOn = false
        // Create new beacon item
        let uuidString = txtUUID.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard let uuid = UUID(uuidString: uuidString.uppercased()) else { return }
        let major = Int(txtMajor.text!) ?? 0
        let minor = Int(txtMinor.text!) ?? 0
        let name = txtName.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let type = txtType.text!

        let newItem = Item(name: name, photo: imgIcon.image!, uuid: uuid, majorValue: major, minorValue: minor, type: type)

        delegate?.addBeacon(item: newItem)

        //this collection is used to keep track of the beacons that have been paired but not still displayed in the items view
        //Da fare solo dopo un pairing
        self.ivc.itemsToBeAdded.append(newItem)
        self.ivc.addItemToBeAdded(item: newItem) //save it in coredata

        self.registerBeacon(item: newItem)

//        notificationPublisher.sendNotification(
//            title: "Added a new iBeacon!",
//            subtitle: "Pairing successful.",
//            body: "ClickFinder",
//            badge: 1,
//            delayInterval: nil,
//            identifier: "added new beacon",
//            ring: false
//        )

        let itemsViewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "itemsController") as UIViewController
        self.navigationController?.pushViewController(itemsViewController, animated: true)
        //self.present(itemsViewController, animated: false, completion: nil)
    }

    func registerBeacon(item: Item){
        let iphoneID = UIDevice.current.identifierForVendor?.uuidString
        let beaconID = "\(item.uuid.uuidString)_\(Int(item.majorValue))_\(Int(item.minorValue))"

        //Compress the image
        let imageData = item.photo.jpegData(compressionQuality: 0.25)!
        //Encode to base64
        let strBase64 =  imageData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)

        self.ref.child("users").child(beaconID).setValue(
            [
                "latid": "0",
                "longit": "0",
                "mac": beaconID,
                "name": item.name,
                "owner": iphoneID!,
                "switch_hdd": "0",
                "tiposchermo": "Beacon-\(iphoneID!)",
                "type": item.type,
                "photo": strBase64
            ]
        ){(error:Error?, ref:DatabaseReference) in
            if let error = error {
                print("Data could not be saved: \(error).")
            } else {
                print("Data saved successfully!")
            }
        }
    }

    //Image pickers (Camera & Gallery)
    @IBAction func btnCancel_Pressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func selectFromGallery(_ sender: Any) {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary

        present(imagePicker, animated: true, completion: nil)
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

    //Type Picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return AppConstants.types.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return AppConstants.types[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        txtType.text = AppConstants.types[row]

        // Is name valid?
        let nameValid = (txtName.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count > 0)
        pickerView.isHidden = true

        btnAdd.isHidden = false
        btnCancel.isHidden = false
        btnEdit.isHidden = false

        btnAdd.isEnabled = (nameValid && txtType.text != nil)

        self.view.endEditing(true)
    }

    @objc func cancelPicker(){
        pickerView.isHidden = true
        txtType.text?.removeAll()
    }

    //type label
    @objc func typeTapped(){
        pickerView.isHidden = false
        btnAdd.isHidden = true
        btnCancel.isHidden = true
        btnEdit.isHidden = true
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
