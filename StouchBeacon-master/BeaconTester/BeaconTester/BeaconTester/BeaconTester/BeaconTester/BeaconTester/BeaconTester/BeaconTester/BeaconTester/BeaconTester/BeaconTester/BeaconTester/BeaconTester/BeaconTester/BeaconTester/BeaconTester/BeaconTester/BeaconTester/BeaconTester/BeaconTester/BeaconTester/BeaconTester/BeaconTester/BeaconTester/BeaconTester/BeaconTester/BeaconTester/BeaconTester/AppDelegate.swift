import UIKit
import CoreData
import CoreLocation
import UserNotifications
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // request authorization for local notifications
        /*
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
        }*/
        
        // Firebase notifications
        if #available(iOS 10.0, *) {
            let authOptions : UNAuthorizationOptions = [.alert, .badge, .sound]
            //UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_,_ in })
            UNUserNotificationCenter.current().delegate = self
            FIRMessaging.messaging().remoteMessageDelegate = self
            
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        FIRApp.configure()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.tokenRefreshNotification),
                                               name: .firInstanceIDTokenRefresh,
                                               object: nil)
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        let viewController = self.window!.rootViewController as! ViewController
        viewController.setView()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        ViewController.displayDistance = true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        ViewController.displayDistance = true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        connectToFcm()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BeaconTester")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("%@", userInfo)
        print("URL: \(userInfo["gcm.notification.url"]!)")
        
        let uri = userInfo["gcm.notification.url"]
        
        if uri != nil {
            let viewController = self.window?.rootViewController as! ViewController
            viewController.setWebView(uri: uri as! String)
        }
    }
    
    func tokenRefreshNotification(_ notification: Notification) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            print("InstanceID token: \(refreshedToken)")
            NetworkHelper.sendRegistrationRequest()
        }
        connectToFcm()
    }

    func connectToFcm() {
        FIRMessaging.messaging().connect { (error) in
            if (error != nil) {
                print("Unable to connect with FCM. \(error)")
            } else {
                print("Connected to FCM.")
            }
        }
    }
}

// MARK: Firebase

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
        
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("qua --> Message ID: \(userInfo["gcm.message_id"]!)")
        print("userInfo: %@", userInfo)
        print("URL: %@", userInfo["gcm.notification.url"]!)
    }
}
    
extension AppDelegate : FIRMessagingDelegate {
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        print("%@", remoteMessage.appData)
    }
}



