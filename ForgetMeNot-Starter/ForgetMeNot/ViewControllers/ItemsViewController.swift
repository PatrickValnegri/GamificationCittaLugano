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
        var newBeacon : CLBeacon?
        
        for beacon in beacons {
//            print(beacon)
            if items.isEmpty {
                if Int(truncating: beacon.major) > 32000{
                    newBeacon = beacon
                }
            }
            for row in 0..<items.count {
                if items[row] == beacon {
                    items[row].beacon = beacon
                    indexPaths += [IndexPath(row: row, section: 0)]
                } else {
                    //Once a beacon that it's still not in the list has been found
                    //check its major value to see if a pairing has been requested
                    if Int(truncating: beacon.major) > 32000{
                        newBeacon = beacon
                    }
                }
            }
        }
        
//        print()
        
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
        
        // Update beacon locations of visible rows.
        if let visibleRows = tableView.indexPathsForVisibleRows {
            let rowsToUpdate = visibleRows.filter { indexPaths.contains($0) }
            for row in rowsToUpdate {
                let cell = tableView.cellForRow(at: row) as! ItemCell
                cell.refreshLocation()
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
    
    var items = [Item]()
    var nrOfItems = 0;
    
    //CORE DATA
    let appDelegate = UIApplication.shared.delegate as! AppDelegate //delegate of AppDelegate
    var pairingIsOn = false
    @IBOutlet weak var pair: UILabel!
    
    //Entry point into core location
    let locationManager = CLLocationManager()
    
    //Firebase database reference
    var ref: DatabaseReference!
    var databaseHandle: DatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        pair.text = "Off ❌"
        
        ref = Database.database().reference()
        
        //CORE DATA
        //let context = appDelegate.persistentContainer.viewContext //get the context from appDelegate
        
        //prompt the user for access to location services if they haven’t granted it already
        //user grants Always allow app run in foreground and background
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        //This sets the CLLocationManager delegate to self so you’ll receive delegate callbacks.
        locationManager.delegate = self
        
        loadItems()
        startMonitoringStandardRegion()
        
        authenticate()
    
        getUsers()
        
        //registerUser()
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
    
    func registerUser(){
         let iphoneID = UIDevice.current.identifierForVendor?.uuidString

        getToken { (token: String) in
            let tokenID: String = token
            let tipoSchermo: String = "iOS_LAC"+"_"+tokenID
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
    
    //ompletion: @escaping(String)->() per estrarre il valore da una closure quando é pronto
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

        //Auth.auth().signIn(withEmail: "prova@supsi.ch", password: "123456") { [weak self] user, error in
           // guard let strongSelf = self else { return }
        
        self.ref.child("users").observe(.childAdded, with: { (snapshot) in
            
            if snapshot.exists() {
                //print("data found")
                
                var value = snapshot.value as? NSDictionary
                
                var address = value?["address"] as? String ?? ""
                var data = value?["data"] as? String ?? ""
                var latid = value?["latid"] as? String ?? ""
                var longit = value?["longit"] as? String ?? ""
                var mac = value?["mac"] as? String ?? ""
                var name = value?["name"] as? String ?? ""
                var owner = value?["owner"] as? String ?? ""
                var phone = value?["phone"] as? String ?? ""
                var switch_hdd = value?["switch_hdd"] as? String ?? ""
                var tiposchermo = value?["tiposchermo"] as? String ?? ""
                var type = value?["type"] as? String ?? ""
                
                print(mac)
                //print(tiposchermo.size)
            }else{
                print("no data found")
            }
        })
        
    }
    
    
    
    
    
    func startMonitoringStandardRegion(){
        locationManager.startRangingBeacons(in: AppConstants.region)
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

