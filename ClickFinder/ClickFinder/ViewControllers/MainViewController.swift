//
//  MainViewController.swift
//
//  ClickFinder
//
//  Created by Ivan Pavic (ivan.pavic@student.supsi.ch) and Patrick Valnegri(patrick.valnegri@student.supsi.ch) on 30.03.19.
//  Copyright © 2019. All rights reserved.
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

/*
 This extension exposes all the methods that are used in CoreLocation's context.
 All the functions that implement the pairing and monitoring are declareted in this extension.
 */
extension MainViewController: CLLocationManagerDelegate {

    /*
     Setup of CoreLocation's location manager. This function handles the authorization requests
     and checks if all the needed services are available.
     Location accuracy is also set.
     */
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

    /*
     This function is called every time new location data is available
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }

        //Update the current location
        self.currentLocation.latitude = locValue.latitude
        self.currentLocation.longitude = locValue.longitude
    }

    /*
     This function is called when the device enters a beacon region
     */
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if(!checkIfActive()){
            locationManager.startRangingBeacons(in: AppConstants.region)
        }
    }

    /*
     This function is called when the device leaves a beacon region
    */
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if(!checkIfActive()){
            locationManager.stopRangingBeacons(in: AppConstants.region)
        }
    }

    /*
     This function is called every time a beacon has been ranged
    */
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        print("ranging")
        for beacon in beacons {
            /*
             This first part of the didRangeBeacons function is used to implement the "Search my phone"
             functionality. When the user presses the phisycal button of a known beacon, the user's phone
             has to start ringing so that the user can find it.
             */
            //If the ranged beacon has a major value bigger than the pairing value
            if(Int(truncating: beacon.major) > AppConstants.pairingValue){
                let major = UInt16(truncating: beacon.major)-UInt16(AppConstants.pairingValue)
                let minor = UInt16(truncating: beacon.minor)
                //And if it is a known beacon
                if let known = ivc.items.first(where:{$0.majorValue == major && $0.minorValue == minor}){
                    //make the phone ring
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

            //if no beacons have been registered, just handle the ranged beacon as unknown
            if ivc.items.isEmpty {
                handleUnknownIBeacons(beacon: beacon)
            }else{
                //if the app is unactive
                if( !checkIfActive() ){
                    if let item = ivc.items.first(where:{$0.majorValue == UInt16(truncating: beacon.major) && $0.minorValue == UInt16(truncating: beacon.minor)}){
                        checkIfLost(item: item, known: true)
                    } else {
                        handleUnknownIBeacons(beacon: beacon)
                    }
                }else{
                    //If a the app is active
                    //HANDLING OF THE SELECTED BEACON (with the search button)
                    if itemToLookFor != nil{
                        if itemToLookFor!.majorValue == UInt16(truncating: beacon.major) && itemToLookFor!.minorValue == UInt16(truncating: beacon.minor){
                            locationManager.stopRangingBeacons(in: AppConstants.region)
                            foundDate = Date()
                            itemToLookFor!.beacon = beacon
                            
                            showToast(message: "\(itemToLookFor!.name) \n\(itemToLookFor!.nameForProximity(beacon.proximity))")
                            toastStartDate = Date()
                            
                            checkIfLost(item: itemToLookFor!, known: true)
                            
                            //reset item to look for so that the app keeps looking for other beacons
                            itemToLookFor = nil
                            locationManager.startRangingBeacons(in: AppConstants.region)
                        }else{
                            handleUnknownIBeacons(beacon: beacon)
                        }

                        let now = Date()
                        
                        let elapsedNotFound = Int(now.timeIntervalSince(foundDate))

                        print(elapsedNotFound)
                        
                        if elapsedNotFound > AppConstants.notFoundDelay{
                            searchIsOn = false
                            let beaconID = "\(itemToLookFor!.uuid)_\(itemToLookFor!.majorValue)_\(itemToLookFor!.minorValue)"
                            showToast(message: "Beacon not found, server notified!")
                            updateBeaconStatus(beaconID: beaconID, lost: true)

                            //reset item to look for so that the app keeps looking for other beacons
                            itemToLookFor = nil
                            locationManager.startRangingBeacons(in: AppConstants.region)
                        }
                    }else{
                        //A KNOWN NOT SELECTED BEACON HAS BEEN FOUND
                        if let item = ivc.items.first(where:{$0.majorValue == UInt16(truncating: beacon.major) && $0.minorValue == UInt16(truncating: beacon.minor)}){
                            if Int((foundKnownDate.timeIntervalSince(foundDate))) > AppConstants.knownNotificationDelay{
                                checkNotSelectedKnownItem(item: item)
                                foundDate = Date()
                            }
                            foundKnownDate = Date()
                        } else {
                            handleUnknownIBeacons(beacon: beacon)
                        }
                    }
                }
            }
        }

        //if no beacons have been found
        if beacons.isEmpty{
            let now = Date()

            //notify the server that the beacon selected by the user is missing
            if(itemToLookFor != nil && searchIsOn == true){
                if Int(now.timeIntervalSince(foundDate)) > AppConstants.notFoundDelay{
                    foundDate = Date()
                    searchIsOn = false

                    locationManager.stopRangingBeacons(in: AppConstants.region)

                    let beaconID = "\(itemToLookFor!.uuid)_\(itemToLookFor!.majorValue)_\(itemToLookFor!.minorValue)"

                    itemToLookFor = nil

                    showToast(message: "Beacon not found, server notified!")
                    updateBeaconStatus(beaconID: beaconID, lost: true)

                    locationManager.startRangingBeacons(in: AppConstants.region)
                }
            }
        }
    }

    /*
     This function handles all the unknown beacons, even the beacons that requested a pairing
    */
    private func handleUnknownIBeacons(beacon: CLBeacon){
        var newBeacon : CLBeacon?

        //major value > 39168 -> the pairing button of an unknown beacon has been pressed
        if Int(truncating: beacon.major) > AppConstants.pairingValue{
            newBeacon = beacon //assign the pairing beacon
        } else {
            // HANDLING OF AN UNKNOWN BEACON
            let item = Item(name: "New", photo: UIImage(), uuid: beacon.proximityUUID, majorValue: Int(truncating: beacon.major), minorValue: Int(truncating: beacon.minor), type: AppConstants.types[0])
            let endDate = Date()
            let elapsed = Int(endDate.timeIntervalSince(startDate))

            if  elapsed > AppConstants.notificationDelay { // delay to avoid backend overloading
                startDate = Date()
                alreadyRangedUnknownItems.removeAll(keepingCapacity: false)
            }

            var found = false
            for itemN in alreadyRangedUnknownItems{
                if ( (itemN.majorValue == item.majorValue) && (itemN.minorValue == item.minorValue) ){
                    found = true
                }
            }

            if found == false{
                alreadyRangedUnknownItems.append(item)
                checkIfLost(item: item, known: false)
            }
        }

        // PAIRING OF A NEW BEACON
        if pairingIsOn == true {
            if(newBeacon != nil){
                let end = Date()

                let major = Int(truncating: newBeacon!.major)-AppConstants.pairingValue //Pairing done
                let item = Item(name: "New", photo: UIImage(), uuid: newBeacon!.proximityUUID, majorValue: major, minorValue: Int(truncating: newBeacon!.minor), type: AppConstants.types[0])

                var flag = false

                let elapsed2 = Int(end.timeIntervalSince(pairingStartDate))
                
                if elapsed2 > AppConstants.pairingDelay{ // delay to avoid backend overloading
                    pairingStartDate = Date()
                    alreadyRangedPairingItems.removeAll(keepingCapacity: false)
                }

                //Check if the beacon has already been ranged
                for itemN in alreadyRangedPairingItems{
                    if ( (itemN.majorValue == item.majorValue) && (itemN.minorValue == item.minorValue) ){
                        flag = true
                    }
                }

                //Check if the beacon is already registered on this device
                for itemN in ivc.items{
                    if ( (itemN.majorValue == item.majorValue) && (itemN.minorValue == item.minorValue) ){
                        flag = true
                    }
                }

                //Check if the beacon has been added but not already loaded on the table view
                for itemN in ivc.itemsToBeAdded{
                    if ( (itemN.majorValue == item.majorValue) && (itemN.minorValue == item.minorValue) ){
                        flag = true
                    }
                }

                if flag == false{
                    alreadyRangedPairingItems.append(item)
                    checkIfBelongs(item: item)
                }

                flag = true
            }
        }
    }

    /*
     This function check if the given item belongs to another user.
     If it does, a toast is displayed.
     If it doesn't, the pairing alert is displayed.
     */
    private func checkIfBelongs(item: Item){
        let beaconID = "\(item.uuid.uuidString)_\(Int(item.majorValue))_\(Int(item.minorValue))"

        self.ref.child("users").observe(.value, with: { (snapshot) in
            if (snapshot.hasChild(beaconID)) { //Se già presente nel db
                self.locationManager.stopRangingBeacons(in: AppConstants.region)
                self.showToast(message: "Beacon belongs to another person")
                self.pairingIsOn = true
                self.locationManager.startRangingBeacons(in: AppConstants.region)
            }else{
                AppVariables.pairingIsOn = false
                self.pairingIsOn = false
                self.locationManager.stopRangingBeacons(in: AppConstants.region)
                self.createAlert(title: "New beacon found!", message: itemAsString(item: item), item: item)
            }
        })
    }
    
    /*
     If the device ranges a registered beacon that i've lost: send a request to the server that will notify me.
     */
    func checkNotSelectedKnownItem(item: Item){
        let beaconID = "\(item.uuid.uuidString)_\(Int(item.majorValue))_\(Int(item.minorValue))"
        let iphoneID = UIDevice.current.identifierForVendor?.uuidString

        let iBeaconsRef = self.ref.child("users")

        iBeaconsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot{
                    let value = childSnapshot.value as? NSDictionary
                    let mac = value?["mac"] as? String ?? ""
                    let switch_hdd = value?["switch_hdd"] as? String ?? ""

                    if mac == beaconID && switch_hdd == "1"{
                        self.sendNotificationFirebase(titolo: "Ritrovamento mio beacon", mac: iphoneID!, beacon_id: beaconID, gps: "\(self.currentLocation.latitude)_\(self.currentLocation.longitude)")
                    }
                }
            }
        })
    }
    
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
                    } else if mac == beaconID && switch_hdd == "1" && known{
                        //Known lost iBeacon found while app was in background
                        //Request the server to send a notification so that the user is aware of
                        if !self.checkIfActive(){
                            self.sendNotificationFirebase(titolo: "Ritrovamento beacon", mac: iphoneID!, beacon_id: beaconID, gps: "\(self.currentLocation.latitude)_\(self.currentLocation.longitude)")
                            self.locationManager.stopRangingBeacons(in: AppConstants.region)
                            //self.updateBeaconStatus(beaconID: beaconID, lost: false)
                        }else{
                            self.updateBeaconStatus(beaconID: beaconID, lost: false)
                            self.itemToLookFor = nil
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
        
        self.ref.child("users").child(beaconID).updateChildValues(values)
    }

    /*
     Authorizations managing
     */
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

/*
 Class MainViewController -> it is used to implement the following functionalities:
    -Beacon ranging, monitoring and pairing
    -Location updating
    -Webview displaying the main page and the pairing page of the app
        -Pairing page is displayed when there are no beacons registered.
        -Main page is displayed when the user registered at least one beacons
    -Beacon searching
    -Device searching
 */
class MainViewController: UIViewController, WKNavigationDelegate, UIPickerViewDelegate, UIPickerViewDataSource{
    /******************** FIELDS *******************/

    var delegate: ItemsViewController?
    //Instance of ItemsViewController
    let ivc = ItemsViewController(nibName: nil, bundle: nil)

    //Instance of UserViewController
    let uvc = UserViewController(nibName: nil, bundle: nil)

    //PICKER VIEW
    @IBOutlet weak var iBeaconPicker: UIPickerView!

    //used to cache already ranged known/unkown iBeacons -> avoid backend overloading
    var alreadyRangedUnknownItems = [Item]()
    var alreadyRangedKnownItems = [Item]()
    var alreadyRangedPairingItems = [Item]()

    var itemToLookFor: Item? = nil

    //TIME
    var startDate = Date()
    var pairingStartDate = Date()
    var toastStartDate = Date()
    var foundDate = Date()
    var foundKnownDate = Date()

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

    //FLAGS
    var searchIsOn = false
    var pairingIsOn = false
    var menuShowing = false

    //UI Connections
    @IBOutlet weak var search: UIButton!
    @IBOutlet weak var mainPage: WKWebView!
    var currentPage: URL?

    //SideBar menu
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        //import registered beacons from core data
        ivc.loadItems()

        if ivc.items.isEmpty || AppVariables.pairingIsOn == true{
            loadPairing()
        }else{
            loadSearching()
        }

        //serch beacon initialized to nil
        itemToLookFor = nil

        leadingConstraint.constant = -85

        //Connect picker:
        iBeaconPicker.delegate = self
        iBeaconPicker.dataSource = self
        iBeaconPicker.isHidden = true

        //CLBEACON REGION
        //Allow beacon reagion to notify if the device entered or exited from it
        AppConstants.region.notifyEntryStateOnDisplay = true
        AppConstants.region.notifyOnEntry = true
        AppConstants.region.notifyOnExit = true

        //Observe the app status
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        //FIREBASE REALTIME DATABASE REFERENCE
        ref = Database.database().reference()

        //TODO La prima registrazione la fa quando il token è pronto -> prossimo refresh
        registerUser() //first time registration or only update token

        //CORE LOCATION
        setUpLocationManager()

        /*
         For each registered beacon, monitor it's pairing reagion.
         The pairing region is used to implement the "Search my phone" functionality.
         When the user click the physical beacon button, the device has to ring
         */
        for itemN in ivc.items{
            let region = CLBeaconRegion(proximityUUID: AppConstants.uuid, major: itemN.majorValue + UInt16(AppConstants.pairingValue), minor: itemN.minorValue, identifier: AppConstants.uuid.uuidString)
            region.notifyEntryStateOnDisplay = true
            region.notifyOnEntry = true
            region.notifyOnExit = true
            locationManager.startMonitoring(for: region)
        }

        //Start CoreLocation services
        locationManager.startUpdatingLocation()
        locationManager.startRangingBeacons(in: AppConstants.region)
        locationManager.startMonitoring(for: AppConstants.region)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.locationManager.stopRangingBeacons(in: AppConstants.region)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.setNavigationBarHidden(false, animated: true)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        //self.locationManager.startRangingBeacons(in: AppConstants.region)
    }

    @objc func appMovedToBackground() {
        print("ClickFineder is now in background")

        pairingIsOn = false

        locationManager.startUpdatingLocation()
        locationManager.startMonitoring(for: AppConstants.region)
    }

    @objc func appMovedToForeground(){
        print("ClickFineder is now in foreground")

        locationManager.startRangingBeacons(in: AppConstants.region)
        locationManager.startMonitoring(for: AppConstants.region)
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
    
    //Beacon list button
    @IBAction func listaTapped(_ sender: Any) {
        locationManager.stopRangingBeacons(in: AppConstants.region)
    }
    
    //User registration page button
    @IBAction func userTapped(_ sender: Any) {
        locationManager.stopRangingBeacons(in: AppConstants.region)
    }
    
    //Menu button
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

    //Search button
    @IBAction func searchIBeacon(_ sender: Any) {
            iBeaconPicker.isHidden = !iBeaconPicker.isHidden

            if iBeaconPicker.isHidden{
                foundDate = Date()
                searchIsOn = true
                locationManager.startRangingBeacons(in: AppConstants.region)
            } else {
                locationManager.stopRangingBeacons(in: AppConstants.region)
            }
    }

    func loadMainPage(url: URL?){
        mainPage.scrollView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        mainPage.load(URLRequest(url: url!))
        mainPage.allowsBackForwardNavigationGestures = true
    }

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

    // The function called when an item is called
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        itemToLookFor = ivc.items[row]
    }

    func loadPairing(){
        let url = AppConstants.pairingPage!
        mainPage.load(URLRequest(url: url))
        pairingIsOn = true
        search.isHidden = true
    }

    func loadSearching(){
        let url = AppConstants.mainPageURL!
        mainPage.load(URLRequest(url: url))

        pairingIsOn = false
        search.isHidden = false
    }
    
    /*
     c
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
            self.pairingIsOn = true
            AppVariables.pairingIsOn = false
            self.locationManager.startRangingBeacons(in: AppConstants.region)
        }))

        //Save the paired beacon
        alertController.addAction(UIAlertAction(title: "Pair", style: .default, handler: { (action) in
            item.name = alertController.textFields![0].text ?? "New"

            detailItem = item
            flag = true

            self.locationManager.stopRangingBeacons(in: AppConstants.region)

            let addItemViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "addItem") as! AddItemViewController
            self.navigationController?.pushViewController(addItemViewController, animated: true)

        }))

        self.present(alertController, animated: true, completion: nil)
    }

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
    /*
     This function is used to register a user first time inside database or update token if the user is already register into the database
     */
    func registerUser(){
        let iphoneID = UIDevice.current.identifierForVendor?.uuidString
        
        print("Iphone id: ", iphoneID!)

        getToken { (token: String) in
            let tokenID: String = token
            let tipoSchermo: String = "iOS_LAC_regId_"+tokenID
            
            self.ref.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
                //User is already inside database -> update only token
                if (snapshot.hasChild(iphoneID!)) {
                    self.ref.child("users").child(iphoneID!).updateChildValues(["tiposchermo":tipoSchermo]) {
                        (error:Error?, ref:DatabaseReference) in
                        if let error = error {
                            print("Token not updated: \(error).")
                        } else {
                            print("Token updated successfully!")
                        }
                    }
                 //User is not registered inside database -> register a new user
                } else {
                    self.ref.child("users").child(iphoneID!).setValue(["tiposchermo":tipoSchermo, "switch_hdd": "0", "mac": iphoneID!]) {
                        (error:Error?, ref:DatabaseReference) in
                        if let error = error {
                            print("User registration could not be saved: \(error).")
                        } else {
                            print("User registered successfully!")
                        }
                    }
                }
            })
        }
    }

    func sendNotificationFirebase(titolo: String, mac: String, beacon_id: String, gps: String) {
        print("Notification sent!")
        let urlString: String = "https://fcm.googleapis.com/fcm/send"
        let time_to_live = 36000

        let command = AppConstants.comandCheckAlarm
        let regID = AppConstants.publicKeyServer
        let url: String = ""

        //User info
        uvc.loadUser()
        let antenna_name = AppVariables.userName
        let antenna_phone = AppVariables.userPhone

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
