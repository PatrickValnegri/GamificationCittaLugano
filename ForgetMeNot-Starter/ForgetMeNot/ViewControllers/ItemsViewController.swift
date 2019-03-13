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

let storedItemsKey = "storedItems"

class ItemsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var items = [Item]()
    
    //Firebase database reference
    var ref: DatabaseReference!
    var databaseHandle: DatabaseHandle?
    
    //Entry point into core location
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        //prompt the user for access to location services if they haven’t granted it already
        //user grants Always allow app run in foreground and background
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
       
        //This sets the CLLocationManager delegate to self so you’ll receive delegate callbacks.
        locationManager.delegate = self
        
        loadItems()
        
        print("Authorization requested")
        authenticate() //TODO non serve a nulla ? le letture si possono fare senza autenticarsi
        
        //registerUser()
        getUsers()
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Override point for customization after application launch. Here you can out the code you want.
        
        
        
        return true
    }
    
    func authenticate() {
        
        Auth.auth().createUser(withEmail: "prova@supsi.ch", password: "123456") { authResult, error in
            if let error = error {
                print("Sign in failed:", error.localizedDescription)
            } else {
                print ("Signi in successfully")
            }
        }
        
        /*
        Auth.auth().signInAnonymously { (user, error) in
            if let error = error {
                print("Sign in failed:", error.localizedDescription)
                
            } else {
                print ("*********************************************************")
                print ("New user ?:", user!.additionalUserInfo?.isNewUser as Any)
            }
        }
        */
        
    }
    
    func registerUser(){
        print ("---------------------------------------------------------")
        self.ref.child("users").childByAutoId().setValue(["name": "Test", "email": "prova@test.ch", "type": "chiavi"])
    }
    
    func getUsers(){
        
        Auth.auth().signIn(withEmail: "prova@supsi.ch", password: "123456") { [weak self] user, error in
            guard let strongSelf = self else { return }
            
            self!.ref.child("users").observe(.childAdded, with: { (snapshot) in
                
                if snapshot.exists() {
                    //print("data found")
                    
                    let value = snapshot.value as? NSDictionary
                    
                    let address = value?["address"] as? String ?? ""
                    let data = value?["data"] as? String ?? ""
                    let latid = value?["latid"] as? String ?? ""
                    let longit = value?["longit"] as? String ?? ""
                    let mac = value?["mac"] as? String ?? ""
                    let name = value?["name"] as? String ?? ""
                    let owner = value?["owner"] as? String ?? ""
                    let phone = value?["phone"] as? String ?? ""
                    let switch_hdd = value?["switch_hdd"] as? String ?? ""
                    let tiposchermo = value?["tiposchermo"] as? String ?? ""
                    let type = value?["type"] as? String ?? ""
                    
                    print(name)
                    //print(tiposchermo.size)
                }else{
                    print("no data found")
                }
            })
            
        }
        
        
    }
    
    func loadItems() {
        guard let storedItems = UserDefaults.standard.array(forKey: storedItemsKey) as? [Data] else { return }
        for itemData in storedItems {
            guard let item = NSKeyedUnarchiver.unarchiveObject(with: itemData) as? Item else { continue }
            items.append(item)
            
            startMonitoringItem(item)
            
        }
    }
    
    func persistItems() {
        var itemsData = [Data]()
        for item in items {
            let itemData = NSKeyedArchiver.archivedData(withRootObject: item)
            itemsData.append(itemData)
        }
        UserDefaults.standard.set(itemsData, forKey: storedItemsKey)
        UserDefaults.standard.synchronize()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueAdd", let viewController = segue.destination as? AddItemViewController {
            viewController.delegate = self
        }
    }
    
    //This method takes an Item instance and creates a CLBeaconRegion using asBeaconRegion
    func startMonitoringItem(_ item: Item) {
        let beaconRegion = item.asBeaconRegion()
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
    }
    
    func stopMonitoringItem(_ item: Item) {
        let beaconRegion = item.asBeaconRegion()
        locationManager.stopMonitoring(for: beaconRegion)
        locationManager.stopRangingBeacons(in: beaconRegion)
    }
}

extension ItemsViewController: AddBeacon {
    func addBeacon(item: Item) {
        items.append(item)
        
        tableView.beginUpdates()
        let newIndexPath = IndexPath(row: items.count - 1, section: 0)
        tableView.insertRows(at: [newIndexPath], with: .automatic)
        tableView.endUpdates()
        
        startMonitoringItem(item)
        
        persistItems()
    }
}


//extends itemsviewcontroller functionalities
extension ItemsViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Failed monitoring region: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        
        // Find the same beacons in the table.
        var indexPaths = [IndexPath]()
        for beacon in beacons {
            for row in 0..<items.count {
                if items[row] == beacon {
                    items[row].beacon = beacon
                    indexPaths += [IndexPath(row: row, section: 0)]
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
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
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

// MARK: UITableViewDataSource
extension ItemsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
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
            stopMonitoringItem(items[indexPath.row])
            
            tableView.beginUpdates()
            items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            
            persistItems()
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

