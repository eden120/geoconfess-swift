//
//  Notification.swift
//  GeoConfess
//
//  Created by Admin on 25/04/16.
//  Copyright © 2016 Andrei Costache. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

final class Notification : NSObject {

	let id: UInt
    let unread: Bool
    let model: Model
    let action: Action
    var content: AnyObject?

    enum Model: String {
        case MeetRequest   = "MeetRequest"
        case Message  = "Message"
    }

    enum Action: String {
        case Create   = "create"
        case Sent = "sent"
        case Received  = "received"
    }

    init(meResponse: JSON) throws {
        guard let id = meResponse["id"].uInt else {
            throw meResponse["id"].error!
        }
        
        guard let model = meResponse["model"].string else {
            throw meResponse["model"].error!
        }
        
        guard let action = meResponse["action"].string else {
            throw meResponse["action"].error!
        }

        self.id = id
        self.unread = meResponse["unread"].boolValue
        self.model = Notification.Model(rawValue: model)!
        self.action = Notification.Action(rawValue: action)!
        
        self.content = nil
        if self.model == Notification.Model.MeetRequest {
            guard let notificationInfo = meResponse["meet_request"].dictionary else {
                throw meResponse["meet_request"].error!
            }

            guard let request_id = notificationInfo["id"]!.uInt64 else {
                throw notificationInfo["id"]!.error!
            }
            
            guard let request_status = notificationInfo["status"]!.string else {
                throw notificationInfo["status"]!.error!
            }

            if self.action == Notification.Action.Create {

                guard let priest_id = notificationInfo["priest_id"]!.uInt64 else {
                    throw notificationInfo["priest_id"]!.error!
                }

                guard let penitent = notificationInfo["penitent"]?.dictionary else {
                    throw notificationInfo["penitent"]!.error!
                }
                
                let createMeetRequest = CreateMeetRequestNotification(
					id: request_id,
					status: request_status,
					priest_id: priest_id,
					penitent: PenitentInfo(fromJSON: penitent))
                self.content = createMeetRequest as? AnyObject
                
            } else if self.action == Notification.Action.Sent {
                guard let penitent_id = notificationInfo["penitent_id"]!.uInt64 else {
                    throw notificationInfo["penitent_id"]!.error!
                }
                
                guard let priest = notificationInfo["priest"]?.dictionary else {
                    throw notificationInfo["priest"]!.error!
                }
                
                let sentMeetRequest = SentMeetRequestNotification(
					id: request_id,
					status: request_status,
					priest: PriestInfo(fromJSON: priest),
					penitentId: penitent_id)
                self.content = sentMeetRequest as? AnyObject
            }
            
         } else if self.model == Notification.Model.Message {
            guard let notificationInfo = meResponse["message"].dictionary else {
                throw meResponse["message"].error!
            }

            guard let message_id = notificationInfo["id"]!.uInt64 else {
                throw notificationInfo["id"]!.error!
            }
            
            guard let sender_id = notificationInfo["sender_id"]!.uInt64 else {
                throw notificationInfo["sender_id"]!.error!
            }
            
            guard let recipient_id = notificationInfo["recipient_id"]!.uInt64 else {
                throw notificationInfo["recipient_id"]!.error!
            }
            
            guard let message_text = notificationInfo["text"]!.string else {
                throw notificationInfo["text"]!.error!
            }

            guard let message_createdAt = notificationInfo["created_at"]!.string else {
                throw notificationInfo["created_at"]!.error!
            }
            
            guard let message_updatedAt = notificationInfo["updated_at"]!.string else {
                throw notificationInfo["updated_at"]!.error!
            }

            let message = MessageNotification(
				id: message_id, sender_id: sender_id, recipient_id: recipient_id,
				text: message_text,
				createdAt: Date.parseFrom(message_createdAt),
				updatedAt: Date.parseFrom(message_updatedAt))
			
            self.content = message as? AnyObject
        }
        
        super.init()
    }
    
}

extension Date {
	
	/// Parse date from string (ie, 2016-04-27T08:08:28.917+2:00).
	static private func parseFrom(string: String) -> NSDate {
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
		dateFormatter.timeZone = NSTimeZone(name: "UTC")
		return dateFormatter.dateFromString(string)!
	}
}


