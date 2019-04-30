//
//  AppDelegate.swift
//
//  ClickFinder
//
//  Created by Ivan Pavic (ivan.pavic@student.supsi.ch) and Patrick Valnegri(patrick.valnegri@student.supsi.ch) on 30.03.19.
//  Copyright © 2019. All rights reserved.
//

import UIKit
import UserNotifications
import Firebase
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    let gcmMessageURL = "gcm.notification.url"
    let gcmMessageTime = "gcm.notification.time"
    let gcmMessageParam = "gcm.notification.param"
    let gcmMessagePhone = "gcm.notification.antenna_phone"
    
    //let mvc = MainViewController(nibName: nil, bundle: nil)
    
    private func requestNotificationAuthorization(application: UIApplication){
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = UNAuthorizationOptions([.alert, .badge, .sound])
        
        center.requestAuthorization(options: options) { granted, error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    override init() {
        super.init()
        //FirebaseApp.configure()
        //makes sure the configure code gets executed when AppDelegate is initialised
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self

        
        /*
        //requestNotificationAuthorization(application: application);
        // [START register_for_notifications]
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        // [END register_for_notifications]
         */
        
        //connectToFcm() //TODO non necessario
        
        UNUserNotificationCenter.current().delegate = self
        
        // request permission from user to send notification
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { authorized, error in
            if authorized {
                DispatchQueue.main.async(execute: {
                    application.registerForRemoteNotifications()
                })
            }
        })
        
        
        // When the app launch after user tap on notification (originally was not running / not in background)
        if(launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] != nil){
            // your code here
            print("NOTIFICA APERTA")
        }

        return true
    }
    
    
    /*
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        //Time
        if let messageTime = userInfo[gcmMessageTime] {
            print("Time: \(messageTime)")
        }
        
        //URL
        if let messageURL = userInfo[gcmMessageURL] {
            //mvc.loadURL(notificationURL: "\(messageURL)")
            print("URL: \(messageURL)")
            AppConstants.mainPageURL = URL(string: "\(messageURL)")
            //print("mainPageURL: ", AppConstants.mainPageURL!)
        }

        
        // Print full message.
        print("USER INFO: ", userInfo)
        
        
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        //Time
        if let messageTime = userInfo[gcmMessageTime] {
            print("Time: \(messageTime)")
        }
        
        // Print full message.
        print("USER INFO: ", userInfo)
        
        //URL
        if let messageURL = userInfo[gcmMessageURL] {
            print("URL: \(messageURL)")
            AppConstants.mainPageURL = URL(string: "\(messageURL)")
            //print("mainPageURL: ", AppConstants.mainPageURL!)
        }
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
     */
    
    //Abilita l'invio di messaggi
    func connectToFcm() {

        // Won't connect since there is no token
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instange ID: \(error)")
            }
        }
        Messaging.messaging().shouldEstablishDirectChannel = true
    }
    
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0 //reset icon badge number to 0 when app is opened
    }
    
    //In case of error
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("i am not available in simulator \(error)")
    }
    
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "clickFinder")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
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
}


extension AppDelegate: MessagingDelegate {
    
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token","Firebase registration token: \(fcmToken)")
        
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    // [END refresh_token]
    /*
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Message data: ", remoteMessage.appData)
        UIApplication.shared.applicationIconBadgeNumber += 1
    }
    // [END ios_10_data_message]
 */
}
 


@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate{
    
    // This function will be called when the app receive notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([.alert, .sound, .badge])
    }
    
    
    // This function will be called right after user tap on the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        //body of messagge
        let userInfo = response.notification.request.content.userInfo
        
        let application = UIApplication.shared
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let notificationViewController = storyBoard.instantiateViewController(withIdentifier: "notificationViewController") as! NotificationViewController
        
        //Foreground tap
        if(application.applicationState == .active){
            print("user tapped the notification bar when the app is in foreground")
            
            // Print message URL
            if let messageURL = userInfo[gcmMessageURL] {
                //print("\(messageURL)")
                //AppConstants.notificationURL = "\(messageURL)"
                notificationViewController.urlString = "\(messageURL)"
            }
            
            // param (lost beacon)
            if let messageParam = userInfo[gcmMessageParam] {
                notificationViewController.urlParam = "\(messageParam)"
            }
            
            // antenna phone
            if let messageAntennaPhone = userInfo[gcmMessagePhone] {
                notificationViewController.urlAntennaPhone = "\(messageAntennaPhone)"
            }
            
            if let time = userInfo[gcmMessageTime] {
                print("\(time)")
            }
        }
        
        //Background tap
        if(application.applicationState == .inactive){
            print("user tapped the notification bar when the app is in background")
            
            // message URL
            if let messageURL = userInfo[gcmMessageURL] {
                //print("\(messageURL)")
                //AppConstants.notificationURL = "\(messageURL)"
                notificationViewController.urlString = "\(messageURL)"
            }
            
            // param (lost beacon)
            if let messageParam = userInfo[gcmMessageParam] {
                notificationViewController.urlParam = "\(messageParam)"
            }
            
            // antenna phone
            if let messageAntennaPhone = userInfo[gcmMessagePhone] {
                notificationViewController.urlAntennaPhone = "\(messageAntennaPhone)"
            }
            
            if let time = userInfo[gcmMessageTime] {
                print("\(time)")
            }
        }
        
        
        // Change root view controller to a specific viewcontrollerm
        self.window?.rootViewController?.present(notificationViewController, animated: true, completion: nil)
 
        // tell the app that we have finished processing the user’s action / response
        completionHandler()
    }
}

/*

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([.alert, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler()
    }
    // [END ios_10_message_handling]
}

*/



