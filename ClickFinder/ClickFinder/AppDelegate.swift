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

/*
 Class AppDelegate -> This class works alongside the app object to ensure your app interacts properly with the system and with other appsThe app delegate works alongside the app object to ensure your app interacts properly with the system and with other apps
 -Request notification authorization
 -CoreData:
    -Persistent container
    -Save context
 -Firebase:
    -Refresh token
 -Notification handling:
    -Notification presentation¨
    -Open notification in background
    -Open notfication in foreground
 */
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    let gcmMessageURL = "gcm.notification.url"
    let gcmMessageTime = "gcm.notification.time"
    let gcmMessageParam = "gcm.notification.param"
    let gcmMessagePhone = "gcm.notification.antenna_phone"
    let gcmMessageName = "gcm.notification.antenna_name"
    
    override init() {
        super.init()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        //makes sure the configure code gets executed when AppDelegate is initialised
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        
        // request permission from user to send notification
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { authorized, error in
            if authorized {
                DispatchQueue.main.async(execute: {
                    application.registerForRemoteNotifications()
                })
            }
        })
        
        return true
    }

    
    
    private func requestNotificationAuthorization(application: UIApplication){
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = UNAuthorizationOptions([.alert, .badge, .sound])
        
        center.requestAuthorization(options: options) { granted, error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        //reset icon badge number to 0 when app is opened
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    //In case of error
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("i am not available in simulator \(error)")
    }
    
    
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
                
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    //Core Data Saving support
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
    
    //refresh token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token","Firebase registration token: \(fcmToken)")
        
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    }
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
        
        //Foreground notification tap
        if(application.applicationState == .active){
            print("user tapped the notification bar when the app is in foreground")
            
            // Print message URL
            if let messageURL = userInfo[gcmMessageURL] {
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
            
            // antenna name
            if let messageAntennaName = userInfo[gcmMessageName] {
                notificationViewController.urlAntennaName = "\(messageAntennaName)"
            }
            
            if let time = userInfo[gcmMessageTime] {
                print("\(time)")
            }
        }
        
        //Background notification tap
        if(application.applicationState == .inactive){
            print("user tapped the notification bar when the app is in background")
            
            // message URL
            if let messageURL = userInfo[gcmMessageURL] {
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
            
            // antenna name
            if let messageAntennaName = userInfo[gcmMessageName] {
                notificationViewController.urlAntennaName = "\(messageAntennaName)"
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
