//
//  AppDelegate.swift
//  BillManager
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let notificationID = response.notification.request.identifier
        
        let bill = Database.shared.getBills(notificationID)
        
        if var bill = bill {
            switch response.actionIdentifier {
            case Bill.paidActionID:
                bill.paidDate = Date()
            case Bill.remindLaterID:
                let date = Date(timeInterval: 60 * 60, since: Date())
                bill.setReminder(date) { updated in
                    if let _ = updated.notificationID {
                        bill = updated
                    } else {
                        print("Cannot schedule new reminder because notifications are off")
                    }
                }
            default:
                print("unkown action")
            }
            
            Database.shared.updateAndSave(bill)
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let center = UNUserNotificationCenter.current()
        
        let payAction = UNNotificationAction(identifier: Bill.paidActionID, title: "Mark as Paid")
        let remindLaterAction = UNNotificationAction(identifier: Bill.remindLaterID, title: "Remind Later")
        
        let billCategory = UNNotificationCategory(identifier: Bill.categoryID, actions: [payAction, remindLaterAction], intentIdentifiers: [])
        
        center.setNotificationCategories([billCategory])
        center.delegate = self
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

