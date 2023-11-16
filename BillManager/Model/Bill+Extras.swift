//
//  Bill+Extras.swift
//  BillManager
//

import Foundation
import UserNotifications

extension Bill {
    
    static var categoryID = "billCategory"
    static var paidActionID = "paid"
    static var remindLaterID = "remindLater"
    
    var hasReminder: Bool {
        return (remindDate != nil)
    }
    
    var isPaid: Bool {
        return (paidDate != nil)
    }
    
    var formattedDueDate: String {
        let dateString: String
        
        if let dueDate = self.dueDate {
            dateString = dueDate.formatted(date: .numeric, time: .omitted)
        } else {
            dateString = ""
        }
        
        return dateString
    }
    
    mutating func removeReminder() {
        if let notificationID = notificationID {
            self.notificationID = nil
            remindDate = nil
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
        }
    }
    
    mutating func setReminder(_ date: Date, completion: @escaping (Bill) -> ()) {
        removeReminder()
        var updated = self
        updated.remindDate = date
        updated.notificationID = UUID().uuidString
        authorize { granted in
            guard granted else {
                DispatchQueue.main.async {
                    completion(updated)
                }
                
                return
            }
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Bill Reminder"
        content.body = "\(updated.amount!) due on \(updated.formattedDueDate)"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = Bill.categoryID
        
        let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: updated.notificationID!, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { (error: Error?) in
            DispatchQueue.main.async {
                if let error = error {
                    print("\(error.localizedDescription)")
                    completion(updated)
                } else {
                    completion(updated)
                }
            }
        }
    }
    
    private func authorize(completion: @escaping (Bool) -> ()) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                notificationCenter.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, _) in
                    completion(granted)
                })
            case .denied:
                completion(false)
            case .authorized:
                completion(true)
            case .provisional:
                completion(false)
            case .ephemeral:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }
}
