//
//  MainViewController.swift
//  clickFinder
//
//  Created by Ivan Pavic on 30.03.19.
//  Copyright © 2019 Ray Wenderlich. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import CoreLocation
import FirebaseDatabase
import FirebaseAuth
import Firebase
import Alamofire
import FirebaseInstanceID

let storedItemsKey = "storedItems"

extension MainViewController: CLLocationManagerDelegate {
    
    func setUpLocationManager(){
        //prompt the user for access to location services if they haven’t granted it already
        locationManager.requestAlwaysAuthorization()
        
        AppConstants.region.notifyOnEntry = true;
        AppConstants.region.notifyOnExit = true;
        AppConstants.region.notifyEntryStateOnDisplay = true;
        
        //This sets the CLLocationManager delegate to self so you’ll receive delegate callbacks.
        if CLLocationManager.locationServicesEnabled() && CLLocationManager.isRangingAvailable() && CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }
    }
    
    func startMeasuringData(){
        locationManager.startUpdatingLocation()
        locationManager.startMonitoring(for: AppConstants.region)
        locationManager.startRangingBeacons(in: AppConstants.region)
    }
    
    func stopRanging(){
        locationManager.stopRangingBeacons(in: AppConstants.region)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        self.currentLocation.latitude = locValue.latitude
        self.currentLocation.longitude = locValue.longitude
//        print(locValue.latitude)
//        print(locValue.longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        //ivc.loadItems()
//        let userDefaults = UserDefaults.standard
//        let decoded  = userDefaults.data(forKey: storedItemsKey)
//        ivc.items = NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! [Item]
//
//        print("DECODED")
//        for item in ivc.items {
//            printItem(item: item)
//        }
        
        if(!checkIfActive()){
            notificationPublisher.sendNotification(
                title: "Entered region",
                subtitle: region.identifier,
                body: "This is a background test local notification",
                badge: 1,
                delayInterval: nil,
                identifier: "exit notification",
                ring: false
            )
            
            print("Entered region")
            
            //locationManager.startUpdatingLocation()
            locationManager.startRangingBeacons(in: AppConstants.region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if(!checkIfActive()){
            notificationPublisher.sendNotification(
                title: "Left region",
                subtitle: region.identifier,
                body: "This is a background test local notification",
                badge: 1,
                delayInterval: nil,
                identifier: "exit notification",
                ring: false
            )
            
            print("Left region")
            
            //locationManager.stopUpdatingLocation()
            locationManager.stopRangingBeacons(in: AppConstants.region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        print("ranging")
        
        //Handling of the found beacons
        for beacon in beacons {
            if(!checkIfActive()){
                if(Int(truncating: beacon.major) > AppConstants.pairingValue){
                    
                    let major = UInt16(truncating: beacon.major)-UInt16(AppConstants.pairingValue)
                    let minor = UInt16(truncating: beacon.minor)
                    if let known = ivc.items.first(where:{$0.majorValue == major && $0.minorValue == minor}){
                        print("PHONE FOUND")
                        notificationPublisher.sendNotification(
                            title: "\(known.majorValue)",
                            subtitle: region.identifier,
                            body: "This is a background test local notification",
                            badge: 0,
                            delayInterval: nil,
                            identifier: "exit notification",
                            ring: true
                        )
                    }
                }
            }
            
            if ivc.items.isEmpty {
                print("Unknown iBeacon found")
                handleUnknownIBeacons(beacon: beacon)
            }else{
                if( !checkIfActive() ){
                    print("BACKGROUND")
                    
                    if let item = ivc.items.first(where:{$0.majorValue == UInt16(truncating: beacon.major) && $0.minorValue == UInt16(truncating: beacon.minor)}){
                        
                        checkIfLost(item: item, known: true)
                        
                    } else {
                        print("Unknown iBeacon found")
                        handleUnknownIBeacons(beacon: beacon)
                    }
                    
                }else{
                    print("FOREGROUND")
                    if itemToLookFor != nil{
                        print("beacon selected")
                        if itemToLookFor!.majorValue == UInt16(truncating: beacon.major) && itemToLookFor!.minorValue == UInt16(truncating: beacon.minor){
                            
                            print("Found known Beacon")
                            
                            locationManager.stopRangingBeacons(in: AppConstants.region)
                            
                            foundDate = Date()
                            
                            itemToLookFor!.beacon = beacon
                            
//                            let endDate = Date()
//                            let elapsed = Int(endDate.timeIntervalSince(toastStartDate))
//
//                            if elapsed > 5{
                                showToast(message: "\(itemToLookFor!.name) \n\(itemToLookFor!.nameForProximity(beacon.proximity))")
                                toastStartDate = Date()
//                            }
                
                            checkIfLost(item: itemToLookFor!, known: true)
                        }else{
                            print("Unknown iBeacon found")
                            handleUnknownIBeacons(beacon: beacon)
                        }
                        
                        let now = Date()
                        
                        if Int(now.timeIntervalSince(foundDate)) > 15{
                            print("15 seconds, selected beacon has not been found")
                            
                            locationManager.stopRangingBeacons(in: AppConstants.region)
                            
                            searchIsOn = false
                            
                            let beaconID = "\(itemToLookFor!.uuid)_\(itemToLookFor!.majorValue)_\(itemToLookFor!.minorValue)"
                            
                            showToast(message: "Beacon not found, server notified!")
                            
                            updateBeaconStatus(beaconID: beaconID, lost: true)
                        }
                    }
                }
            }
        }
        
        //if no beacons have been found
        if beacons.isEmpty{
            let now = Date()
            
            //notify the server that the user selected beacon is missing
            if(itemToLookFor != nil && searchIsOn == true){
                if Int(now.timeIntervalSince(foundDate)) > 15{
                    searchIsOn = false
                    
                    locationManager.stopRangingBeacons(in: AppConstants.region)

                    print("15 seconds, selected beacon is missing")
                    
                    foundDate = Date()
                    
                    let beaconID = "\(itemToLookFor!.uuid)_\(itemToLookFor!.majorValue)_\(itemToLookFor!.minorValue)"
                    
                    showToast(message: "Beacon not found, server notified!")

                    updateBeaconStatus(beaconID: beaconID, lost: true)
                }
            }
        }
    }
    
    private func handleUnknownIBeacons(beacon: CLBeacon){
        var newBeacon : CLBeacon?
        
        //major value > 32000 -> the pairing button has been pressed
        if Int(truncating: beacon.major) > AppConstants.pairingValue{
            print("Pairing iBeacon found")
            newBeacon = beacon
        } else {
            let item = Item(name: "New", photo: UIImage(), uuid: beacon.proximityUUID, majorValue: Int(truncating: beacon.major), minorValue: Int(truncating: beacon.minor))
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
                
                checkIfLost(item: item, known: false)
            }
        }
        
        print(pairingIsOn)
        
        if pairingIsOn == true {
            print("Pairing the new iBeacon")
            if(newBeacon != nil){
                self.pairingIsOn = false
                
                let major = Int(truncating: newBeacon!.major)-AppConstants.pairingValue //Pairing done
                
                let item = Item(name: "New", photo: UIImage(), uuid: newBeacon!.proximityUUID, majorValue: major, minorValue: Int(truncating: newBeacon!.minor))
                
                var flag = false
                
                for itemN in ivc.items{
                    if ( (itemN.majorValue == item.majorValue) && (itemN.minorValue == item.minorValue) ){
                        flag = true
                    }
                }
                
                for itemN in ivc.itemsToBeAdded{
                    if ( (itemN.majorValue == item.majorValue) && (itemN.minorValue == item.minorValue) ){
                        flag = true
                    }
                }
                
                if flag == false{
                    print("ALERT")
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

class MainViewController: UIViewController, WKNavigationDelegate, UIPickerViewDelegate, UIPickerViewDataSource{
    /******************** FIELDS *******************/

    //Instance of ItemsViewController
    let ivc = ItemsViewController(nibName: nil, bundle: nil)

    //Instance of UserViewController
    let uvc = UserViewController(nibName: nil, bundle: nil)
    
    //PICKER VIEW
    @IBOutlet weak var iBeaconPicker: UIPickerView!
    
    //used to cache already ranged unkown iBeacons -> avoid backend overloading
    var alreadyRangedItems = [Item]()
    
    var itemToLookFor: Item? = nil
    
    //TIME
    var startDate = Date()
    var toastStartDate = Date()
    var foundDate = Date()
    
    //CORE DATA
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //CORE LOCATION
    //Entry point into core location
    let locationManager = CLLocationManager()
    //current location coordinates
    var currentLocation = Coordinate(latitude: 0, longitude: 0)
    
    //LOCAL NOTIFICATIONS PUBLISHER
    private let notificationPublisher = NotificationPublisher()
    
    //FIREBASE REALTIME DATABASE
    var ref: DatabaseReference!
    
    //PAIRING FLAG
    var searchIsOn = false
    var pairingIsOn = false
    
    //UI Connections
    @IBOutlet weak var search: UIButton!
    @IBOutlet weak var mainPage: WKWebView!

    //SideBar menu
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    
    //Homebutton sidebar
    @IBAction func homeButttonTapped(_ sender: Any) {
        //AppConstants.mainPageURL = URL(string: "https://www.ticinonews.ch/")!
        loadMainPage()
        
    }
    
    @IBAction func refreshTapped(_ sender: Any) {
        print("MainPageURL", AppConstants.mainPageURL!)
        let url = AppConstants.mainPageURL!
        mainPage.load(URLRequest(url: url))
    }
    
    
    var menuShowing = false

    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        leadingConstraint.constant = -85
        
        //Connect picker:
        iBeaconPicker.delegate = self
        iBeaconPicker.dataSource = self
        
        iBeaconPicker.isHidden = true
        
        loadMainPage()
        
        //CLBEACON REAGION
        //Allow beacon reagion to notify if the device entered or exited from it
        AppConstants.region.notifyEntryStateOnDisplay = true
        AppConstants.region.notifyOnEntry = true
        AppConstants.region.notifyOnExit = true
        
        //LOAD DATA
        ivc.loadItems()
        
        for itemN in ivc.items{
            let region = CLBeaconRegion(proximityUUID: AppConstants.uuid, major: itemN.majorValue + UInt16(AppConstants.pairingValue), minor: itemN.minorValue, identifier: AppConstants.uuid.uuidString)
            
            locationManager.startMonitoring(for: region)
        }
        
        locationManager.startUpdatingLocation()
        locationManager.startMonitoring(for: AppConstants.region)
        
        //Observe the app status
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        //CORE LOCATION
        setUpLocationManager()
        
        //FIREBASE REALTIME DATABASE REFERENCE
        ref = Database.database().reference()
        
        registerUser() //first time registration or only update token
        
        //sendNotificationFirebase(titolo: "Prova", mac: "76EE64EC-54C6-46E3-82FD-A897A42F6F21", beacon_id: "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5_11_12", gps: "000_000")
        
    }
    
    @objc func appMovedToBackground() {
        print("ClickFineder is now in background")
        
        pairingIsOn = false
    
        locationManager.startUpdatingLocation()
        locationManager.startMonitoring(for: AppConstants.region)
    }
    
    @objc func appMovedToForeground(){
        print("ClickFineder is now in foreground")

        locationManager.stopRangingBeacons(in: AppConstants.region)
        locationManager.stopMonitoring(for: AppConstants.region)
    }
    
    /*
     Returns true if the app is in the foreground, false if it is not.
     */
    func checkIfActive() -> Bool{
        switch UIApplication.shared.applicationState{
        case .background, .inactive :
            return false
        case .active :
            return true
        default:
            return false
        }
    }
    
    /*********************************************
    UI ACTIONS & UI COMPONENTS
    **********************************************/
    
    
    
    @IBAction func openMenu(_ sender: Any) {
        if (menuShowing) {
            leadingConstraint.constant = -85
        } else {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
                self.view.layoutIfNeeded()
            })
            leadingConstraint.constant = 0
        }
        menuShowing = !menuShowing
    }
    
    @IBAction func searchIBeacon(_ sender: Any) {
        if !ivc.items.isEmpty{
            iBeaconPicker.isHidden = !iBeaconPicker.isHidden
            
            if iBeaconPicker.isHidden{
                foundDate = Date()
                
                pairingIsOn = true
                searchIsOn = true
                locationManager.startRangingBeacons(in: AppConstants.region)
            } else {
                locationManager.stopRangingBeacons(in: AppConstants.region)
            }
        }else{
            showToast(message: "No paired beacons detected")
            pairingIsOn = true
            locationManager.startRangingBeacons(in: AppConstants.region)
        }
    }
    
    //Funzione che carica la view principale
    func loadMainPage(){
        mainPage.scrollView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        
        //let url = URL(string: "https://www.ticinonews.ch/")!
        let url = AppConstants.mainPageURL!
        
        mainPage.load(URLRequest(url: url))
        mainPage.allowsBackForwardNavigationGestures = true
    }
    
    //Funzione per caricare url di inviato nella risposta del server
    func loadURL(notificationURL: String){
        mainPage.scrollView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        
        let url = URL(string: notificationURL)!
        AppConstants.mainPageURL = url
        mainPage.load(URLRequest(url: url))
        mainPage.allowsBackForwardNavigationGestures = true
    }
    
    func hidePicker(){
        iBeaconPicker.removeFromSuperview()
    }
    
    func showPicker(){
        self.view.addSubview(iBeaconPicker)
    }
    
    // The number of columns(components) in the picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows in the picker
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return ivc.items.count
    }
    
    // The data to return for the row and component (column)
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return ivc.items[row].name
    }
    
    //
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        itemToLookFor = ivc.items[row]
    }
    
    /*
     This function creates a new toast with the given message
     */
    func showToast(message : String) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 60))
        self.view.bringSubviewToFront(toastLabel)
        toastLabel.numberOfLines = 2
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 9.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 2.0, delay: 3, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    func createAlert(title: String, message: String, item: Item){
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        //Textfield for the beacon name
        alertController.addTextField { (textField) in
            textField.placeholder = "Insert beacon name here"
        }
        
        //Deny pairing
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }))
        
        //Save the paired beacon
        alertController.addAction(UIAlertAction(title: "Pair", style: .default, handler: { (action) in
            item.name = alertController.textFields![0].text ?? "New"
            
            let beaconID = "\(item.uuid.uuidString)_\(Int(item.majorValue))_\(Int(item.minorValue))"
            
            self.ref.child("users").observe(.value, with: { (snapshot) in
                
                if (snapshot.hasChild(beaconID)) { //Se già presente nel db
                    self.showToast(message: "Beacon belongs to another person")
                    alertController.dismiss(animated: true, completion: nil)
                    
                } else { //Se non è già presente nel db
                    detailItem = item
                    flag = true
                    AppConstants.isPairing = true
                    
                    let addItemViewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "addItem") as UIViewController
                    
                    self.locationManager.stopRangingBeacons(in: AppConstants.region)
                    
                    //self.navigationController?.pushViewController(aivc, animated: true)
                    self.present(addItemViewController, animated: false, completion: nil)
                }
            })
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func handleSelectBeaconImageView(){
        print("Select image from gallery")
    }
    
    /*********************************************/
    /*********************************************
     IBEACON MANAGING
     *********************************************/
    
    /*
     Cycles the users table and checks if the passed beacon has been lost by someone.
     If the passed item is owned by the user, it swtich_hdd value is reset.
     Else, the app notificates the main server that a lost item has been found in the current location.
     */
    
    func checkIfLost(item: Item, known: Bool){
        let beaconID = "\(item.uuid.uuidString)_\(Int(item.majorValue))_\(Int(item.minorValue))"
        let iphoneID = UIDevice.current.identifierForVendor?.uuidString

        let iBeaconsRef = self.ref.child("users")
        
        iBeaconsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot{
                    let value = childSnapshot.value as? NSDictionary
                    let mac = value?["mac"] as? String ?? ""
                    let switch_hdd = value?["switch_hdd"] as? String ?? ""
                    
                    if mac == beaconID && switch_hdd == "1" && !known{
                        self.sendNotificationFirebase(titolo: "Ritrovamento beacon", mac: iphoneID!, beacon_id: beaconID, gps: "\(self.currentLocation.latitude)_\(self.currentLocation.longitude)")
                        
                        print("UNKNOWN BEACON FOUND, send notification")
                    } else if mac == beaconID && switch_hdd == "1" && known{
                        //Known lost iBeacon found while app was in background
                        //Request the server to send a notification so that the user is aware of
                        if !self.checkIfActive(){
                           self.sendNotificationFirebase(titolo: "Ritrovamento beacon", mac: iphoneID!, beacon_id: beaconID, gps: "\(self.currentLocation.latitude)_\(self.currentLocation.longitude)")
                            self.locationManager.stopRangingBeacons(in: AppConstants.region)
                            //self.updateBeaconStatus(beaconID: beaconID, lost: false)
                        }else{
                            print("Found known \(beaconID), set switch_hdd to 0")
                            self.locationManager.stopRangingBeacons(in: AppConstants.region)
                            self.updateBeaconStatus(beaconID: beaconID, lost: false)
                        }
                    }
                }
            }
        })
    }
    
    /*
     This function updates the iBeacon status on the database.
     Usually this function is called when a lost known iBeacon has been found or when a know beacon cant' be found.
     */
    func updateBeaconStatus(beaconID: String, lost: Bool){
        
        var values = [String:String]()
        
        if lost{
            values = ["switch_hdd": "1"]
        }else{
            values = ["switch_hdd": "0"]
        }
        
        print("BEACON STATU UPDATED \(values)")
        self.ref.child("users").child(beaconID).updateChildValues(values)
    }
    
    /*******************************************/
    
    /*******************************************
     FIREBASE
     *******************************************/
    
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
    
    func registerUser(){
        let iphoneID = UIDevice.current.identifierForVendor?.uuidString
        
        getToken { (token: String) in
            let tokenID: String = token
            let tipoSchermo: String = "iOS_LAC_regId_"+tokenID
            print("TOKEN", tokenID)
            print("IPHONE ID",iphoneID!)
            
            self.ref.child("users").observe(.value, with: { (snapshot) in
                
                if (snapshot.hasChild(iphoneID!)) { //se l'utente esiste già nel database
                    self.ref.child("users").child(iphoneID!).updateChildValues(["tiposchermo":tipoSchermo]) {
                        (error:Error?, ref:DatabaseReference) in
                        if let error = error {
                            print("Token not updated: \(error).")
                        } else {
                            print("Token updated successfully!")
                        }
                    }
                } else { //se l'utente non esiste nel database
                    
                    self.ref.child("users").child(iphoneID!).setValue(["tiposchermo":tipoSchermo, "switch_hdd": "0", "mac": iphoneID!]) {
                        (error:Error?, ref:DatabaseReference) in
                        if let error = error {
                            print("Data could not be saved: \(error).")
                        } else {
                            print("Data saved successfully!")
                        }
                    }
                }
            })
        }
    }
    
    func sendNotificationFirebase(titolo: String, mac: String, beacon_id: String, gps: String) {
        print("Notifica inviata")
        let urlString: String = "https://fcm.googleapis.com/fcm/send"
        let time_to_live = 36000
        
        let command = AppConstants.comandCheckAlarm
        let regID = AppConstants.publicKeyServer
        let url: String = ""
        
        //User info
        uvc.loadUser()
        let antenna_name = AppConstants.userName
        let antenna_phone = AppConstants.userPhone
        
        let notification: [String: Any] = [
            "title": titolo,
            "body": mac,
            "url": url,
            "command": command,//"CHECK_ALARM"
            "param": beacon_id,
            "value": gps, //GPS latitude + "_" + longitude
            "from": regID, //token destinatario
            "antenna_name": antenna_name,
            "antenna_phone": antenna_phone,
            "sound": "true",
            "badge": "1"
        ]
        
        let message: [String: Any] = [
            "priority": "high",
            "content_available": true,
            "time_to_live": time_to_live,
            //"collapse_key": min,
            
            "to": AppConstants.publicKeyServer,
            "notification": notification,
        ]
        
        let authorization: String = "key=\(AppConstants.privateKeyServer)"
        let header: HTTPHeaders = [ "Content-Type": "application/json",
                                    "Accept": "application/json",
                                    "Authorization": authorization
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
}
