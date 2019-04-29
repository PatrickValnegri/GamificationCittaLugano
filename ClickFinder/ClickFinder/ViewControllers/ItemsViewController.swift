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
import FirebaseAuth
import Firebase
import CoreData
import Alamofire
import FirebaseInstanceID
import UserNotifications
import CoreLocation

var indexToEdit: Int = -1

class ItemsViewController: UIViewController, UIImagePickerControllerDelegate{

    //UI LIST OF ITEMS
    @IBOutlet weak var tableView: UITableView!

    //list of known items
    var items = [Item]()
    var itemsToBeAdded = [Item]()

    var nrOfItems = 0;

    @IBOutlet weak var status: UILabel!

    //CORE DATA
    let appDelegate = UIApplication.shared.delegate as! AppDelegate //delegate of AppDelegate

    //FIREBASE REALTIME DATABASE
    var ref: DatabaseReference!
    var databaseHandle: DatabaseHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        

        //Navigation controller:
        //self.navigationController?.setNavigationBarHidden(true, animated: true)

        //FIREBASE REALTIME DATABASE REFERENCE
        ref = Database.database().reference()


        /********** ADD THE LAST PAIRED IBEACONS **********/
        //Clear
        itemsToBeAdded = [Item]()

        loadItemsToBeAdded()

        for item in itemsToBeAdded{
            addBeacon(item: item)
            print("Item: ", item.name)
            //printItem(item: item)
        }

        itemsToBeAdded = [Item]()

        deleteItemsToBeAdded()
        /**************************************************/

        //Update the list of items, new beacons may have been paired
        loadItems()
        self.tableView.reloadData()

        //locationManager.stopRangingBeacons(in: AppConstants.region)

        //authenticate()

        //getUsers()

        //registerUser()

    }

    //TODO non funziona dopo edit
    @IBAction func homeTapped(_ sender: Any) {
        let mainViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainView") as! MainViewController
        self.navigationController?.pushViewController(mainViewController, animated: true)
    }

    func authenticate() {
         Auth.auth().signInAnonymously { (user, error) in
             if let error = error {
             print("Sign in failed:", error.localizedDescription)

             } else {
             print ("New user ?:", user!.user.isAnonymous as Any)
             }
         }
    }

    func getUsers(){
        self.ref.child("users").observe(.value, with: { (snapshot) in

            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot {

                    let value = childSnapshot.value as? NSDictionary

                    _ = value?["address"] as? String ?? ""
                    _ = value?["data"] as? String ?? ""
                    _ = value?["latid"] as? String ?? ""
                    _ = value?["longit"] as? String ?? ""
                    let mac = value?["mac"] as? String ?? ""
                    _ = value?["name"] as? String ?? ""
                    _ = value?["owner"] as? String ?? ""
                    _ = value?["phone"] as? String ?? ""
                    _ = value?["switch_hdd"] as? String ?? ""
                    _ = value?["tiposchermo"] as? String ?? ""
                    _ = value?["type"] as? String ?? ""

                    print(mac)
                }
            }
        })
    }

    func sendNotification(titolo: String, mac: String, beacon_id: String, gps: String, command: String, regiID: String, antenna_name: String, antenna_phone: String) {
        print("Notifica inviata")
        let urlString: String = "https://fcm.googleapis.com/fcm/send"
        let time_to_live = 3600

        let notification: [String: Any] = [
            "title": titolo,
            "body": mac,
            //"url": urlString,
            "command": command,//"CHECK_ALARM"
            "param": beacon_id,
            "value": gps, //GPS latitude + "_" + longitude
            "from": regiID, //token destinatario
            "antenna_name": antenna_name,
            "antenna_phone": antenna_phone
        ]


        let message: [String: Any] = [
            "priority": "high",
            "content_available": true,
            "time_to_live": time_to_live,
            //"collapse_key": min,

            "to": regiID,
            "notification": notification
                //"title":"Beacon trovato",
               //"body":"ivan ha trovato il tuo beacon"
        ]


        let header: HTTPHeaders = [ "Content-Type": "application/json",
                                    "Accept": "application/json",
                                    "Authorization": "key=AIzaSyCu-EtxJSmRGA2ll2W66ugs5Rfy1oa3vZs"
        ]

        AF.request(urlString, method: .post, parameters: message, encoding: JSONEncoding.default, headers: header).responseString {
            response in
            switch response.result {
            case .success:
                print("SUCCESS: ", response)

                break
            case .failure(let error):
                print("FAILURE: ", error)
            }
        }

    }

    func loadItems() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Items")
        let context = appDelegate.persistentContainer.viewContext

        nrOfItems = 0

        request.returnsObjectsAsFaults = false

        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {

                let imageData = Data(base64Encoded: data.value(forKey: "photo") as! String, options: Data.Base64DecodingOptions.ignoreUnknownCharacters)!
                let decodedImage = UIImage(data: imageData)!

                let majorValue = data.value(forKey: "major") as! Int
                let minorValue = data.value(forKey: "minor") as! Int
                let type = data.value(forKey: "type") as! String

                let item = Item(name: data.value(forKey: "name") as! String,
                                photo: decodedImage,
                                uuid: UUID(uuidString: data.value(forKey: "uuid") as! String)!,
                                majorValue: majorValue,
                                minorValue: minorValue,
                                type: type)

                items.append(item)
                nrOfItems = nrOfItems + 1
                print(data.value(forKey: "uuid") as! String)
            }
        } catch {
            print("Failed")
        }
    }

    func loadItemsToBeAdded() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ItemsToBeAdded")
        let context = appDelegate.persistentContainer.viewContext

        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {

                let imageData = Data(base64Encoded: data.value(forKey: "photo") as! String, options: Data.Base64DecodingOptions.ignoreUnknownCharacters)!
                let decodedImage = UIImage(data: imageData)!

                let item = Item(name: data.value(forKey: "name") as! String,
                                photo: decodedImage,
                                uuid: UUID(uuidString: data.value(forKey: "uuid") as! String)!,
                                majorValue: data.value(forKey: "major") as! Int,
                                minorValue: data.value(forKey: "minor") as! Int,
                                type: data.value(forKey: "type") as! String)
                itemsToBeAdded.append(item)
                print(data.value(forKey: "uuid") as! String)
            }
        } catch {
            print("Failed")
        }
    }

    func addItemToBeAdded(item: Item){
        let context = appDelegate.persistentContainer.viewContext

        //Create a new Entity of type Item
        let entity = NSEntityDescription.entity(forEntityName: "Items", in: context)
        let newItem = NSManagedObject(entity: entity!, insertInto: context)

        let imageData = item.photo.pngData()!
        let strBase64 =  imageData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)

        newItem.setValue(item.uuid.uuidString, forKey: "uuid")
        newItem.setValue(item.name, forKey: "name")
        newItem.setValue(strBase64, forKey: "photo")
        newItem.setValue(Int(item.majorValue), forKey: "major")
        newItem.setValue(Int(item.minorValue), forKey: "minor")
        newItem.setValue(item.type, forKey: "type")

        //save the context with new data
        do{
            try context.save()
        } catch {
            print("Failed to save context");
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "listItems", let viewController = segue.destination as? MainViewController {
            viewController.delegate = self
            viewController.loadMainPage(url: AppConstants.pairingPage)
        }
    }

    @IBAction func loadParingPage(_ sender: Any) {
        let mainView:MainViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainView") as! MainViewController
        //mainView.delegate = self
        //mainView.loadMainPage(url: AppConstants.pairingPage)
        AppVariables.pairingIsOn = true
//        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.pushViewController(mainView, animated: true)
        //self.present(mainView, animated: false, completion: nil)
    }

    func deleteItemsToBeAdded(){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ItemsToBeAdded")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        let context = appDelegate.persistentContainer.viewContext

        do{
            try context.execute(deleteRequest)
        }catch {
            print("Error while trying to delete objects in VisitedItems Entity.")
        }
    }
}

extension ItemsViewController: AddBeacon {
    func addBeacon(item: Item) {

        print("Item salvato", item.name)
        items.append(item)

        let context = appDelegate.persistentContainer.viewContext

        //Create a new Entity of type Item
        let entity = NSEntityDescription.entity(forEntityName: "Items", in: context)
        let newItem = NSManagedObject(entity: entity!, insertInto: context)

        //Compress the image
        let imageData = item.photo.jpegData(compressionQuality: 0.25)!
        //Encode to base64
        let strBase64 =  imageData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)

        newItem.setValue(item.uuid.uuidString, forKey: "uuid")
        newItem.setValue(item.name, forKey: "name")
        newItem.setValue(strBase64, forKey: "photo")
        newItem.setValue(Int(item.majorValue), forKey: "major")
        newItem.setValue(Int(item.minorValue), forKey: "minor")
        newItem.setValue(item.type, forKey: "type")

        //Update the table view
        nrOfItems = nrOfItems + 1

        tableView.beginUpdates()
        let newIndexPath = IndexPath(row: nrOfItems - 1, section: 0)
        tableView.insertRows(at: [newIndexPath], with: .automatic)
        tableView.endUpdates()

        tableView.reloadData()

        //Save the Core Data context
        do{
            try context.save()
        } catch {
            print("Failed to save context");
        }
    }
}

// MARK: UITableViewDataSource
extension ItemsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nrOfItems //the current number of items
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath) as! ItemCell
        cell.item = items[indexPath.row]

        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        //Rimozione beacon
        if editingStyle == .delete {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Items")
            let context = self.appDelegate.persistentContainer.viewContext

            request.returnsObjectsAsFaults = false
            do {
                let result = try context.fetch(request)
                for data in result as! [NSManagedObject] {
                    //Rimozione beacon da SQLite
                    if (data.value(forKey: "name") as! String).elementsEqual(items[indexPath.row].name)
                        && (data.value(forKey: "uuid") as! String).elementsEqual(items[indexPath.row].uuid.uuidString)
                        && (data.value(forKey: "major") as! Int) == Int(items[indexPath.row].majorValue)
                        && (data.value(forKey: "minor") as! Int) == Int(items[indexPath.row].minorValue){

                        print(data.value(forKey: "name") as! String)
                        context.delete(data)

                        //Rimozione beacon da Firebase
                        let beaconID = "\(items[indexPath.row].uuid.uuidString)_\(items[indexPath.row].majorValue)_\(items[indexPath.row].minorValue)"
                         ref.child("users").child(beaconID).removeValue()
                    }
                }
            } catch {
                print("Failed")
            }

            //Update items list &
            tableView.beginUpdates()
            self.items.remove(at: indexPath.row)
            self.nrOfItems = self.nrOfItems - 1

            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()

            tableView.reloadData()

            //save the context with updated data
            do{
                try context.save()
            } catch {
                print("Failed to save context");
            }
        }
    }




}

// MARK: UITableViewDelegate
extension ItemsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = items[indexPath.row]

        let detailMessage = "UUID: \(item.uuid.uuidString)\nMajor: \(item.majorValue)\nMinor: \(item.minorValue)\nType: \(item.type)"
        let detailAlert = UIAlertController(title: "Details", message: detailMessage, preferredStyle: .alert)
        detailAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        let editAction = UIAlertAction(title: "Edit", style: .default, handler: { _ -> Void in
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "addItem") as! AddItemViewController

            nextViewController.item = item
            nextViewController.currentIndex = indexPath.row
            nextViewController.isEdit = true

            //self.navigationController?.popViewController(animated: true)
            self.dismiss(animated: true, completion: nil)
            
            self.present(nextViewController, animated: true, completion: nil)
        })
        detailAlert.addAction(editAction)

        self.present(detailAlert, animated: true, completion: nil)

    }



}
