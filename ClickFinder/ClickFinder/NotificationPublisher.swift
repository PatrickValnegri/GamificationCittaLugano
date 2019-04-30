//
//  NotificationPublisher.swift
//
//  ClickFinder
//
//  Created by Ivan Pavic (ivan.pavic@student.supsi.ch) and Patrick Valnegri(patrick.valnegri@student.supsi.ch) on 07.03.19.
//  Copyright © 2019. All rights reserved.
//

import UIKit
import Foundation
import UserNotifications

/*
 Class NotificationPublisher.
 This class manages local notifications and it's sendNotification function
 is called repeatedly to simulate the phone's ringing when a the pairing phisycal
 button of a registered beacon is pressed.
 */
class NotificationPublisher: NSObject{
    
    func sendNotification(title: String, subtitle: String, body: String, badge: Int?, delayInterval: Int?, identifier: String, ring: Bool){
        let notificationContent = UNMutableNotificationContent()
        
        if(!ring){
            notificationContent.title = title
            notificationContent.subtitle = subtitle
            notificationContent.body = body
        }
        
        notificationContent.sound = .default
        
        var delayTimeTrigger: UNTimeIntervalNotificationTrigger?
        
        if let delayInterval = delayInterval {
            delayTimeTrigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(delayInterval), repeats: false)
        }
        
        if let badge = badge {
            var currentBadgeCount = UIApplication.shared.applicationIconBadgeNumber
            
            currentBadgeCount += badge
            
            notificationContent.badge = NSNumber(integerLiteral: currentBadgeCount)
        }
        
        notificationContent.sound = UNNotificationSound.default
        
        UNUserNotificationCenter.current().delegate = self
        
        let request = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: delayTimeTrigger)
        
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error{
                print(error.localizedDescription)
            }
        }
    }
}

extension NotificationPublisher: UNUserNotificationCenterDelegate{
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("The notification is about to be presented")
        
        completionHandler([.badge, .sound, .alert])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.actionIdentifier
        
        switch identifier {
        case UNNotificationDismissActionIdentifier:
            print("The notification has been dismissed")
            completionHandler()
        case UNNotificationDefaultActionIdentifier:
            print("The user opened the app with the notification")
            UIApplication.shared.applicationIconBadgeNumber = 0
            completionHandler()
        default:
            print("The default case has been called")
            completionHandler()
        }
    }
}
