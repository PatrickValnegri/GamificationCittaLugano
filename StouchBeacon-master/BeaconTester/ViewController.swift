import UIKit
import AVFoundation
import CoreBluetooth
import CoreLocation

import Firebase
import Toast_Swift
import PermissionScope

class ViewController: UIViewController, CLLocationManagerDelegate, UITabBarControllerDelegate, CBPeripheralManagerDelegate {
    var locationManager: CLLocationManager!
    
    var currentLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    var checkedNumber = 0
    static var displayDistance = false
    
    var lastTimeMyBeaconWasSent: NSDate? = nil
    var lastTimeOtherBeaconWasSent: NSDate? = nil
    var lastTimeSound: NSDate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareScope()
        initLocationManager()
        setView()

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func initLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
    }
    
    func setView() {
        // controlla lo stato del Bluetooth e, se necessario, mostra di accenderlo
        statusBluetooth()
        
        if ScopesHelper.displayScope() {
            displayScope()
        }
        
        // gestione utente: inviamo la richiesta di registrazione al server
        NetworkHelper.sendRegistrationRequest()
        
        // gestione del beacon: se non siamo ancora pairati, mostriamo la pagina di registrazione e inviamo le informazioni sul device
        if CoreDataHelper.instance.getBeacon() != nil {
            setWebView(uri: AppConstants.mainUri)
        }
        else {
            setWebView(uri: AppConstants.pairUri)
        }
        
        // nel caso che il beacon non sia ancora stato inviato al server
        let beacon = CoreDataHelper.instance.getBeacon()
        if beacon != nil {
            if beacon!.sent == false {
                NetworkHelper.sendBeacon()
            }
        }
    }
    
    func setWebView(uri: String) {
        let uri2 = uri.replacingOccurrences(of: " ", with: "%20")
        let url = NSURL (string: uri2)

        if url == nil {
            Logger.log(what: "URL non valido")
            return
        }
        
        let requestObj = NSURLRequest(url: url! as URL)
        webView.loadRequest(requestObj as URLRequest)
    }
    
    
    // MARK: location manager
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedAlways{
            print("status authorized")
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self){
                print("is monitoring")
                if CLLocationManager.isRangingAvailable() {
                    print("scanning")
                    startScanning()
                }
            }
        }
    }
    
    func startScanning() {
        let beaconRegion = CLBeaconRegion(proximityUUID: AppConstants.uuid as! UUID, identifier: "EM_region")
        beaconRegion.notifyOnEntry = true
        beaconRegion.notifyOnExit  = true
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
        
        let myBeacon = CoreDataHelper.instance.getBeacon()
        
        if(myBeacon != nil && myBeacon!.major != nil)
        {
            let minor = Int(myBeacon!.minor!)!
            var major = Int(myBeacon!.major!)!
            
            major = major + 39168
            
            if minor < 0 || major < 0 {
                return
            }
            
            Logger.log(what: "start monitoring per major: " + String(major) + ", minor: " + String(minor) + ", region: My_beacon")
            
            let myRegion = CLBeaconRegion(proximityUUID: AppConstants.uuid as! UUID, major: UInt16(major), minor: UInt16(minor), identifier: "My_beacon")
            myRegion.notifyOnEntry = true
            myRegion.notifyOnExit  = true
            locationManager.startMonitoring(for: myRegion)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        locationManager.requestState(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Logger.log(what: " --> entrato in regione: " + region.identifier)
        
        locationManager.startRangingBeacons(in: region as! CLBeaconRegion)
        
        if(region.identifier == "My_beacon")
        {
            Logger.log(what: " --> mio beacon entrato")
            
            AudioHelper.sharedInstance().playSound(long: false)
            
            let state: UIApplicationState = UIApplication.shared.applicationState
            
            if state == .background {
                NotificationsHelper.scheduleLocal()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Logger.log(what: " --> uscito da regione: " + region.identifier)
        locationManager.stopRangingBeacons(in: region as! CLBeaconRegion)
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        print("found " + String(describing: beacons.count) + " beacons in region " + region.identifier)
        
        // se non ci sono beacons esco
        if beacons.count < 1 {
            return
        }
        
        for beacon in beacons  {
            Logger.log(what: "major: " + String(describing: beacon.major) + ", minor: " + String(describing: beacon.minor) + ", rssi: " + String(describing: beacon.rssi))
        }
        
        let beacon = beacons.first! as CLBeacon
        
        // funzione 0: pairing (se il beacon non è ancora stato aggiunto)
        if CoreDataHelper.instance.getBeacon() == nil  {
            var major = beacon.major.intValue
            
            if(major > 32000) {
                major = major - 39168
                
                playSound(rssi: nil)
                // aggiungo a coredata
                CoreDataHelper.instance.storeBeacon(id: String(describing: beacon.proximityUUID), major: String(describing: major), minor: String(describing: beacon.minor))
                // invio al server
                NetworkHelper.sendBeacon()
                // aggiorno webview
                setWebView(uri: AppConstants.pairedUri)
                // mostro toast
                displayToast(distance: "beacon agganciato") 
                
                let myRegion = CLBeaconRegion(proximityUUID: AppConstants.uuid as! UUID, major: CLBeaconMajorValue(beacon.major.intValue), minor: CLBeaconMinorValue(beacon.minor.intValue), identifier: "My_beacon")
                myRegion.notifyOnEntry = true
                myRegion.notifyOnExit  = true
                locationManager.startMonitoring(for: myRegion)
            }
        }
        else {
            checkedNumber = checkedNumber+1
            
            // invio al server solo il primo beacon non mio
            var otherBeaconSent = false
            
            let state: UIApplicationState = UIApplication.shared.applicationState
            
            // se il mio beacon è già aggangiato ciclo su tutti i beacon che vedo
            for beacon in beacons  {
                
                // check su RSSI, se 0 passa al prossimo beacon
                let rssi = beacon.rssi
                Logger.log(what: "rssi: "  + String(rssi))
                
                if rssi == 0 {
                    continue
                }
                
                Logger.log(what: "regione: " + region.identifier)
                
                if region.identifier == "EM_region" {
                    let major = beacon.major.intValue
                    
                    if major > 32000 {
                        continue
                    }
                    else {
                        // se è mio - funzione 4.b
                        if CoreDataHelper.instance.isMyBeacon(beacon: beacon) {
                            
                            let myBeacon = CoreDataHelper.instance.getBeacon()!
                            
                            if(myBeacon.isMissing) {
                                Logger.log(what: "my beacon is missing")
                                
                                if state == .background {
                                    if lastTimeMyBeaconWasSent == nil || Date().timeIntervalSince(lastTimeMyBeaconWasSent as! Date) > 6 {
                                        playSound(rssi: rssi)
                                        NetworkHelper.sendFoundMissingBeacon(beacon: beacon, location: currentLocation)
                                        lastTimeMyBeaconWasSent = NSDate()
                                    }
                                }
                                else {
                                    playSound(rssi: nil)
                                    CoreDataHelper.instance.updateBeacon(key: "isMissing", value: false)
                                    
                                    if lastTimeMyBeaconWasSent == nil || Date().timeIntervalSince(lastTimeMyBeaconWasSent as! Date) > 6 {
                                        NetworkHelper.sendMyBeaconAsFound(beacon: myBeacon)
                                        lastTimeMyBeaconWasSent = NSDate()
                                    }
                                }
                            }
                            // funzione 3
                            if state == .active && ViewController.displayDistance && checkedNumber % 10 == 0 {
                                updateDistance(distance: beacon.proximity)
                                checkedNumber=0
                            }
                        }
                        // se non è mio - funzione 4.a
                        else if !otherBeaconSent {
                            otherBeaconSent = true
                            if lastTimeOtherBeaconWasSent == nil || Date().timeIntervalSince(lastTimeOtherBeaconWasSent as! Date) > 120 {
                                NetworkHelper.sendFoundMissingBeacon(beacon: beacon, location: currentLocation)
                                lastTimeOtherBeaconWasSent = NSDate()
                            }
                        }
                    }
                }
                if region.identifier == "My_beacon" {
                    Logger.log(what: "prima di play sound " + String(rssi))
                    playSound(rssi: rssi)
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
         currentLocation = locations[0].coordinate
    }
    
    
    
    // MARK: UI & Sounds
    
    @IBOutlet weak var webView: UIWebView!

    @IBAction func barButtonClick(_ sender: UIBarButtonItem) {
        if let wnd = self.view{
            let v = UIView(frame: wnd.bounds)
            v.backgroundColor = UIColor.red
            v.alpha = 0.7
                
            wnd.addSubview(v)
            UIView.animate(withDuration: 1, animations: {
                v.alpha = 0.0
            }, completion: {(finished:Bool) in
                v.removeFromSuperview()
            })
        }
        setMyBeaconAsMissing()
    }
 
    func setMyBeaconAsMissing() {
        let myBeacon = CoreDataHelper.instance.getBeacon()
        
        if myBeacon != nil {
            
            ViewController.displayDistance = true
            CoreDataHelper.instance.updateBeacon(key: "isMissing", value: true)
            NetworkHelper.sendMyBeaconAsMissing(beacon: myBeacon!)
        }
    }
    
    func updateDistance(distance: CLProximity) {
        switch distance {
        case .unknown:
            Logger.log(what: "unknown")
            displayToast(distance: "lontano")
        case .far:
            Logger.log(what: "far")
            displayToast(distance: "lontano")
        case .near:
            Logger.log(what: "near")
            displayToast(distance: "vicino")
        case .immediate:
            Logger.log(what: "immediate")
            displayToast(distance: "immediato")
        }
    }
    
    func displayToast(distance: String) {
        self.view.makeToast(distance, duration: 3.0, position: .center)
    }
    
    func playSound(rssi: Int?) {
        if rssi == nil {
            let systemSoundID: SystemSoundID = 1016
            AudioServicesPlaySystemSound (systemSoundID)
            Logger.log(what: "suono normale")
            return
        }
        
        if lastTimeSound == nil || Date().timeIntervalSince(lastTimeSound as! Date) > 7 {
            if rssi! < -87 {
                Logger.log(what: "suono lungo")
                AudioHelper.sharedInstance().playSound(long: true)
                lastTimeSound = NSDate()
            } else if rssi! < -75 {
                Logger.log(what: "suono corto")
                AudioHelper.sharedInstance().playSound(long: false)
                lastTimeSound = NSDate()
            }
            else {
                Logger.log(what: "senza suono troppo vicino")
            }
        }
        else {
            Logger.log(what: "senza suono fuori da intervallo")
        }
    }


    
    // MARK: permission scopes
    
    let multiPscope = PermissionScope()
    
    func prepareScope() {
        multiPscope.headerLabel.text = "Clic Lac"
        multiPscope.bodyLabel.text = "Accendi il Bluetooth dalle impostazioni. Inoltre:"
        multiPscope.addPermission(NotificationsPermission(notificationCategories: nil), message: "permetti all'App di mandarti notifiche:")
        multiPscope.addPermission(LocationWhileInUsePermission(), message: "permetti all'App di sapere dove ti trovi:")
    }
    
    func displayScope() {
        multiPscope.show({finished, results in print("got results \(results)")}, cancelled: { results in print("thing was cancelled")})
    }
    
    
    
    // MARK: Bluetooth
    
    lazy var bluetoothManager:CBPeripheralManager = {
        return CBPeripheralManager(delegate: self, queue: nil, options:[CBPeripheralManagerOptionShowPowerAlertKey: false])
    }()
    
    lazy var defaults:UserDefaults = {
        return .standard
    }()

    // Returns whether Bluetooth access was asked before or not.
    fileprivate var askedBluetooth:Bool {
        get {
            return defaults.bool(forKey: "PS_requestedBluetooth")
        }
        set {
            defaults.set(newValue, forKey: "PS_requestedBluetooth")
            defaults.synchronize()
        }
    }
    
    // Returns whether PermissionScope is waiting for the user to enable/disable bluetooth access or not.
    fileprivate var waitingForBluetooth = false
    
    public func statusBluetooth() {
        // if already asked for bluetooth before, do a request to get status, else wait for user to request
        if askedBluetooth{
            triggerBluetoothStatusUpdate()
        } else {
            print("XX uknown")
        }
        
        let state = (bluetoothManager.state, CBPeripheralManager.authorizationStatus())
        switch state {
        case (.unsupported, _), (.poweredOff, _), (_, .restricted):
            print("AA disabled")
            displayScope()
        case (.unauthorized, _), (_, .denied):
            print("AA unauthorized")
        case (.poweredOn, .authorized):
            print("AA authorized")
        default:
            print("AA uknown")
        }
        
    }

    fileprivate func triggerBluetoothStatusUpdate() {
        if !waitingForBluetooth && bluetoothManager.state == .unknown {
            bluetoothManager.startAdvertising(nil)
            bluetoothManager.stopAdvertising()
            askedBluetooth = true
            waitingForBluetooth = true
        }
    }
    
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        waitingForBluetooth = false
        let state = (bluetoothManager.state, CBPeripheralManager.authorizationStatus())
        switch state {
        case (.unsupported, _), (.poweredOff, _), (_, .restricted):
            print("BB disabled")
            displayScope()
        case (.unauthorized, _), (_, .denied):
            print("BB unauthorized")
        case (.poweredOn, .authorized):
            print("BB authorized")
        default:
            print("BB uknown")
        }
    }
}
