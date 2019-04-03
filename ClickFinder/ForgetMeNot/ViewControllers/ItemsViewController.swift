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

class ItemsViewController: UIViewController {
    
    //CORE LOCATION
    //Entry point into core location
    let locationManager = CLLocationManager()
    
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
    
    //flags
    var pairingIsOn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("LOADING ITEMS VIEW CONTROLLER")
        //status.text = "Off ❌"
        
        //FIREBASE REALTIME DATABASE REFERENCE
        ref = Database.database().reference()
        
        
        /********** ADD THE LAST PAIRED IBEACONS **********/
        loadItemsToBeAdded()
        
        for item in itemsToBeAdded{
            addBeacon(item: item)
            printItem(item: item)
        }
        
        itemsToBeAdded = [Item]()
        
        deleteItemsToBeAdded()
        /**************************************************/
        
        //Update the list of items, new beacons may have been paired
        loadItems()
        
        //authenticate()
    
        //getUsers()
        
        //registerUser()
        
        //sendNotification(titolo: "Titolo", mac: "CE83111B-908F-434D-B6EF-8849AB99BE92", beacon_id: "1", gps: "lat_long", command: "CHECK ALARM", regiID: "d9vDnMtbmWY:APA91bHTplWYzwbvUIDpGyFVEcD86QIBoGiX-QLN3tZs97KD43HU48za8SmeRNu0zbEN_BkUKgpHCFnDmbLAFmGRMnzorgsQCX8p-MwEqWY1mDzRnrqIW8fOCZ-yyK3-degq9YlZwI1A")
    }
    
//    @IBAction func pairIBeacon(_ sender: Any) {
//        pairingIsOn = !pairingIsOn
//
//        if pairingIsOn == true {
//            status.text = "On ✅"
//            locationManager.startRangingBeacons(in: AppConstants.region)
//            print("PAIRING ON")
//        } else {
//            status.text = "Off ❌"
//            locationManager.stopRangingBeacons(in: AppConstants.region)
//            print("PAIRING OFF")
//        }
//    }
    
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
    
    func sendNotification(titolo: String, mac: String, beacon_id: String, gps: String, command: String, regiID: String) {
        print("Notifica inviata")
        let urlString: String = "https://fcm.googleapis.com/fcm/send"
        let time: String = "3600"
        let message: [String: Any] = [ //"body": titolo,
            "priority": "high",
            "content_available": true,
            //"url": urlString,
            //"body": mac,
            "time": time,
            //"command": command,//"CHECK_ALARM"
            //"param": beacon_id,
            //"value": gps, //GPS latitude + "_" + longitude
            "to": regiID, //token destinatario
            "notification":[
                "title":"Beacon trovato",
                "body":"ivan ha trovato il tuo beacon"
            ]
        ]
        
        
        let header: HTTPHeaders = [ "Content-Type": "application/json",
                                    "Accept": "application/json",
                                    "Authorization": "key=AIzaSyCu-EtxJSmRGA2ll2W66ugs5Rfy1oa3vZs"
        ]
        
        AF.request(urlString, method: .post, parameters: message, encoding: JSONEncoding.default, headers: header).responseString {
            response in
            switch response.result {
            case .success:
                print("SUCCESS: ", response.description)
                
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
                let item = Item(name: data.value(forKey: "name") as! String,
                                icon: data.value(forKey: "icon") as! Int,
                                uuid: UUID(uuidString: data.value(forKey: "uuid") as! String)!,
                                majorValue: data.value(forKey: "major") as! Int,
                                minorValue: data.value(forKey: "minor") as! Int)
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
                let item = Item(name: data.value(forKey: "name") as! String,
                                icon: data.value(forKey: "icon") as! Int,
                                uuid: UUID(uuidString: data.value(forKey: "uuid") as! String)!,
                                majorValue: data.value(forKey: "major") as! Int,
                                minorValue: data.value(forKey: "minor") as! Int)
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
        
        newItem.setValue(item.uuid.uuidString, forKey: "uuid")
        newItem.setValue(item.name, forKey: "name")
        newItem.setValue(item.icon, forKey: "icon")
        newItem.setValue(Int(item.majorValue), forKey: "major")
        newItem.setValue(Int(item.minorValue), forKey: "minor")
        
        //save the context with new data
        do{
            try context.save()
        } catch {
            print("Failed to save context");
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueAdd", let viewController = segue.destination as? AddItemViewController {
            viewController.delegate = self
        }
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
        items.append(item)
        
        let context = appDelegate.persistentContainer.viewContext
        
        //Create a new Entity of type Item
        let entity = NSEntityDescription.entity(forEntityName: "Items", in: context)
        let newItem = NSManagedObject(entity: entity!, insertInto: context)
        
        newItem.setValue(item.uuid.uuidString, forKey: "uuid")
        newItem.setValue(item.name, forKey: "name")
        newItem.setValue(item.icon, forKey: "icon")
        newItem.setValue(Int(item.majorValue), forKey: "major")
        newItem.setValue(Int(item.minorValue), forKey: "minor")
        
        //Update the table view
        nrOfItems = nrOfItems + 1
        
        tableView.beginUpdates()
        let newIndexPath = IndexPath(row: nrOfItems - 1, section: 0)
        tableView.insertRows(at: [newIndexPath], with: .automatic)
        tableView.endUpdates()
        
        tableView.reloadData()
        
        //save the context with new data
        do{
            try context.save()
            registerBeacon(item: item)
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
        
        if editingStyle == .delete {
            locationManager.stopRangingBeacons(in: AppConstants.region)
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Items")
            let context = appDelegate.persistentContainer.viewContext
            
            request.returnsObjectsAsFaults = false
            do {
                let result = try context.fetch(request)
                for data in result as! [NSManagedObject] {
                    if (data.value(forKey: "name") as! String).elementsEqual(items[indexPath.row].name)
                        && data.value(forKey: "icon") as! Int == items[indexPath.row].icon
                        && (data.value(forKey: "uuid") as! String).elementsEqual(items[indexPath.row].uuid.uuidString)
                        && (data.value(forKey: "major") as! Int) == Int(items[indexPath.row].majorValue)
                        && (data.value(forKey: "minor") as! Int) == Int(items[indexPath.row].minorValue){
                        
                        print(data.value(forKey: "name") as! String)
                        context.delete(data)
                    }
                }
            } catch {
                print("Failed")
            }
            
            //Update items list &
            tableView.beginUpdates()
            items.remove(at: indexPath.row)
            nrOfItems = nrOfItems - 1
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            
            tableView.reloadData()
            
            //save the context with updated data
            do{
                try context.save()
            } catch {
                print("Failed to save context");
            }
            
            locationManager.startRangingBeacons(in: AppConstants.region)
        }
    }
}

// MARK: UITableViewDelegate
extension ItemsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = items[indexPath.row]
        let detailMessage = "UUID: \(item.uuid.uuidString)\nMajor: \(item.majorValue)\nMinor: \(item.minorValue)"
        let detailAlert = UIAlertController(title: "Details", message: detailMessage, preferredStyle: .alert)
        detailAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(detailAlert, animated: true, completion: nil)
    }
}

