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
import CoreLocation
import FirebaseDatabase
import FirebaseAuth
import Firebase
import CoreData
import Alamofire
import FirebaseInstanceID
import UserNotifications

let storedItemsKey = "storedItems"

//extends itemsviewcontroller functionalities
extension ItemsViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Failed monitoring region: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        var indexPaths = [IndexPath]()
        
        //Handling of the found beacons
        for beacon in beacons {
            
            if items.isEmpty {
                handleUnknownIBeacons(beacon: beacon)
            }else{
                for row in 0..<items.count {
                    if items[row] == beacon {
                        items[row].beacon = beacon
                        indexPaths += [IndexPath(row: row, section: 0)]
                    } else {
                        handleUnknownIBeacons(beacon: beacon)
                    }
                }
            }
            
        }
        
        // Update beacon locations of visible rows.
        if let visibleRows = tableView.indexPathsForVisibleRows {
            let rowsToUpdate = visibleRows.filter { indexPaths.contains($0) }
            for row in rowsToUpdate {
                let cell = tableView.cellForRow(at: row) as! ItemCell
                cell.refreshLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        self.currentLocation.latitude = locValue.latitude
        self.currentLocation.longitude = locValue.longitude
        print(locValue.latitude)
        print(locValue.longitude)
    }
    
    private func handleUnknownIBeacons(beacon: CLBeacon){
        var newBeacon : CLBeacon?
        
        //major value > 32000 -> the pairing button has been pressed
        if Int(truncating: beacon.major) > 32000{
            newBeacon = beacon
        } else {
            let item = Item(name: "New", icon: 4, uuid: beacon.proximityUUID, majorValue: Int(truncating: beacon.major), minorValue: Int(truncating: beacon.minor))
            let endDate = Date()
            let elapsed = Int(endDate.timeIntervalSince(startDate))
            
            //print("\(elapsed) + \(beacon.major) + \(beacon.minor)")
            
            if  elapsed > 60 { // delay to avoid backend overloading
                //print("alreadyRangedItems array cleaned")
                startDate = Date()
                alreadyRangedItems.removeAll(keepingCapacity: false)
            }
            
            var found = false
            for itemN in alreadyRangedItems{
                if ( (itemN.majorValue == item.majorValue) && (itemN.minorValue == item.minorValue) ){
                    found = true
                }
            }
            
            if found == false{
                alreadyRangedItems.append(item)
                print(alreadyRangedItems)
                checkIfLost(item: item)
            }
        }
        
        if pairingIsOn == true {
            
            if(newBeacon != nil){
                let major = Int(truncating: newBeacon!.major)-32000 //Pairing done
                
                let item = Item(name: "New", icon: 4, uuid: newBeacon!.proximityUUID, majorValue: major, minorValue: Int(truncating: newBeacon!.minor))
                
                var flag = false
                
                for itemN in items{
                    if ( (itemN.majorValue == item.majorValue) && (itemN.minorValue == item.minorValue) ){
                        flag = true
                    }
                }
                
                if flag == false{
                    createAlert(title: "New beacon found!", message: itemAsString(item: item), item: item)
                }
                
                flag = true
            }
            
        }
    }
    
    private func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            break
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            break
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            break
        case .restricted:
            // restricted by e.g. parental controls. User can't enable Location Services
            break
        case .denied:
            // user denied your app access to Location Services, but can grant access from Settings.app
            break
        default:
            break
        }
    }
}

class ItemsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    //list of known items
    var items = [Item]()
    var nrOfItems = 0;
    //used to cache already ranged unkown iBeacons -> avoid backend overloading
    var alreadyRangedItems = [Item]()
    var startDate = Date()
    
    //CORE DATA
    let appDelegate = UIApplication.shared.delegate as! AppDelegate //delegate of AppDelegate
    var pairingIsOn = false
    
    @IBOutlet weak var pair: UILabel!
    
    //CORE LOCATION
    //Entry point into core location
    let locationManager = CLLocationManager()
    //current location coordinates
    var currentLocation = Coordinate(latitude: 0, longitude: 0)
    
    //FIREBASE REALTIME DATABASE
    var ref: DatabaseReference!
    var databaseHandle: DatabaseHandle?
    
    //Local notifications
    private let notificationPublisher = NotificationPublisher()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        pair.text = "Off ❌"
        
        //FIREBASE REALTIME DATABASE REFERENCE
        ref = Database.database().reference()
        
        //CLBEACON REAGION
        //Allow beacon reagion to notify if the device entered or exited from it
        AppConstants.region.notifyEntryStateOnDisplay = true
        AppConstants.region.notifyOnEntry = true
        AppConstants.region.notifyOnExit = true
        
        //CORE LOCATION
        setUpLocationManager()
        
        loadItems()
        
        //authenticate()
    
        //getUsers()
        
        //registerUser()
        
        //sendNotification()
        
    }
    
    func setUpLocationManager(){
        //prompt the user for access to location services if they haven’t granted it already
        locationManager.requestAlwaysAuthorization()
        
        //This sets the CLLocationManager delegate to self so you’ll receive delegate callbacks.
        if CLLocationManager.locationServicesEnabled() && CLLocationManager.isRangingAvailable() && CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            locationManager.startMonitoring(for: AppConstants.region)
            locationManager.startRangingBeacons(in: AppConstants.region)
        }
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
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region")
//        notificationPublisher.sendNotification(
//            title: "Entered region",
//            subtitle: region.identifier,
//            body: "This is a background test local notification",
//            badge: 1,
//            delayInterval: nil,
//            identifier: "enter notification"
//        )
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Left region")
//        notificationPublisher.sendNotification(
//            title: "Left region",
//            subtitle: region.identifier,
//            body: "This is a background test local notification",
//            badge: 1,
//            delayInterval: nil,
//            identifier: "exit notification"
//        )
    }
    
    func registerUser(){
        let iphoneID = UIDevice.current.identifierForVendor?.uuidString

        getToken { (token: String) in
            let tokenID: String = token
            let tipoSchermo: String = "iOS_LAC_regId_"+tokenID
            print("TOKEN", tokenID)
            print("IPHONE ID",iphoneID!)
            
            self.ref.child("users").child(iphoneID!).setValue(["tiposchermo":tipoSchermo, "switch_hdd": "0", "mac": iphoneID!]) {
                (error:Error?, ref:DatabaseReference) in
                if let error = error {
                    print("Data could not be saved: \(error).")
                } else {
                    print("Data saved successfully!")
                }
            }
        }
    }
    
    //completion: @escaping(String)->() per estrarre il valore da una closure quando é pronto
    func getToken(completion: @escaping(String)->()) {
        InstanceID.instanceID().instanceID { (result, error) in
            var tokenID: String = ""
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
               
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
                tokenID = result.token
            }
            completion(tokenID);
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
    
    func sendNotification() {
        let urlString: String = "https://fcm.googleapis.com/fcm/send"
        let destination: String = "245070747207@gcm.googleapis.com"
        let messageId = UUID().uuidString
        
        let message: [String: String] = [ "title": "titolo"
        ]
        
        Messaging.messaging().sendMessage(message,
                                          to: destination,
                                          withMessageID: messageId,
                                          timeToLive: 1000) //tempo che il server ha per rispondere
        
    }

    //cycles the users table and checks if the passed beacon has been lost by someone
    func checkIfLost(item: Item){
        let beaconID = "\(item.uuid.uuidString)_\(Int(item.majorValue))_\(Int(item.minorValue))"
        
        let iBeaconsRef = self.ref.child("users")
        
        iBeaconsRef.observe(.value, with: { (snapshot) in
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot{
                    let value = childSnapshot.value as? NSDictionary
                    let mac = value?["mac"] as? String ?? ""
                    let switch_hdd = value?["switch_hdd"] as? String ?? ""
                    
                    if mac == beaconID && switch_hdd == "1"{
                        self.notificationPublisher.sendNotification(
                            title: "UUID: \(item.uuid.uuidString)",
                            subtitle: "Major: \(Int(item.majorValue)), Minor: \(Int(item.minorValue))",
                            body: "Current location: lat=\(self.currentLocation.latitude), long=\(self.currentLocation.longitude)",
                            badge: 1,
                            delayInterval: nil,
                            identifier: "found new beacon"
                        )
                        
                        print("Current location: lat=\(self.currentLocation.latitude), long=\(self.currentLocation.longitude)")
                        print("set current beacon location")
                        print("send notification")
                    }
                }
            }
        })
    }
    
    @IBAction func pairBeacon(_ sender: UIButton) {
        pairingIsOn = !pairingIsOn
        
        if pairingIsOn == true {
            pair.text = "On ✅"
        } else {
            pair.text = "Off ❌"
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueAdd", let viewController = segue.destination as? AddItemViewController {
            viewController.delegate = self
        }
    }
    
    func deleteVisitedBeacoons(){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VisitedItems")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        let context = appDelegate.persistentContainer.viewContext
        
        do{
            try context.execute(deleteRequest)
        }catch {
            print("Error while trying to delete objects in VisitedItems Entity.")
        }
    }
}

//Allerts
extension ItemsViewController{
    func createAlert(title: String, message: String, item: Item){
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        //Annulla il pairing
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
        
            alertController.dismiss(animated: true, completion: nil)
        }))
        
        //TODO aprire la pagina di registrazione con i campi inerenti il beacon già compilati
        alertController.addAction(UIAlertAction(title: "Pair", style: .default, handler: { (action) in
            self.addBeacon(item: item)
        }))
        
        self.present(alertController, animated: true, completion: nil)
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

