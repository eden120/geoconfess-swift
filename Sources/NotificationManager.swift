//
//  Notification.swift
//  GeoConfess
//
//  Created by Admin on 30/04/16.
//  Copyright © 2016 Andrei Costache. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

final class NotificationManager {
    
    class var sharedInstance: NotificationManager {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: NotificationManager? = nil
        }
        
        dispatch_once(&Static.onceToken) {
            Static.instance = NotificationManager()
        }
        
        return Static.instance!
    }

    func getAllNotifications(completion: (notifications: Array<Notification>?, success: Bool?, error: NSError?) -> Void) {
        var params = [String: AnyObject]()
        params["access_token"] = User.current.oauth.accessToken

        APICalls.sharedInstance.actualNotificationsOfCurrentUser(params, completion: {
            (response: AnyObject?, error: NSError?) -> Void in
            if (error != nil) {
                completion(notifications: nil, success: false, error: error)
            } else {
                var arrNotifications: Array<Notification> = []
                
                let notifications = JSON(response!).array
                var i: Int = 0
                for notification in notifications! {
                    do {
                        let element = try Notification(meResponse: notification)
                        arrNotifications.insert(element, atIndex: i)
                        i = i + 1
                    } catch _ as NSError {
                    }
                }
                
                completion(notifications: arrNotifications, success: true, error: nil)
            }
        })
    }

    func showNotification(id: UInt,
                                completion: (success: Bool?, error: NSError?) -> Void){
        var params = [String: AnyObject]()
        params["access_token"] = User.current.oauth.accessToken
        
        APICalls.sharedInstance.showNotification(params, notification_id: "\(id)", completion: {
            (response: AnyObject?, error: NSError?) -> Void in
            if (response == nil) {
                completion(success: false, error: error)
            } else {
                completion(success: true, error: nil)
            }
        })
    }

    func markNotificationAsRead(id: UInt,
                                completion: (success: Bool?, error: NSError?) -> Void){
        var params = [String: AnyObject]()
        params["access_token"] = User.current.oauth.accessToken

        APICalls.sharedInstance.markNotificationAsRead(params, notification_id: "\(id)", completion: {
            (response: AnyObject?, error: NSError?) -> Void in
            if (response == nil) {
                completion(success: false, error: error)
            } else {
                completion(success: true, error: nil)
            }
        })
    }
}
