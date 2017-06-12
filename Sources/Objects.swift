//
//  Objects.swift
//  GeoConfess
//
//  Created  by Andreas Muller on 4/6/16.
//  Reviewed by Paulo Mattos on 5/9/16.
//  Copyright © 2016 Andrei Costache. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

// MARK: - REST Object

/// Type for all unique, REST-ish resources ID.
typealias ResourceID = UInt64

/// A top-level protocol for REST-ish objects/resources.
protocol RESTObject: CustomStringConvertible {
	
	/// Uniquely identifies this resource.
	var id: ResourceID { get }
}

/// Default implementations.
extension RESTObject {
	var description: String {
		return "\(self.dynamicType)(id: \(self.id))"
	}
}

/// JSON encoding.
extension JSON {
	init(_ id: ResourceID) {
		self.init(UInt64(id))
	}
}

// MARK: - JSON Coding

/// Support for **JSON** compatible decoding and encoding.
protocol JSONCoding {
	
	/// Parses a JSON-encoded representation of this object.
	init?(fromJSON: JSON)
	
	/// Returns a JSON-encoded representation of this object.
	func toJSON() -> JSON
}

// MARK: - Priest & Penitent

/// Partial information about a given **priest**.
struct PriestInfo: RESTObject, Equatable {
    
    let id: ResourceID
    let name: String?
    let surname: String?
	
	/// Priest has location if he is active right *now*.
	let location: CLLocationCoordinate2D?
	
    init(id: ResourceID, name: String?, surname: String?) {
        self.id       = id
        self.name     = name
        self.surname  = surname
		self.location = nil
    }
	
	init(fromJSON json: [String: JSON]) {
		precondition(json.count <= 5)
		
		self.id      = json["id"]!.uInt64!
		self.name    = json["name"]?.string
		self.surname = json["surname"]?.string
		
		if let lat = json["latitude"]?.double, let lon = json["longitude"]?.double {
			self.location = CLLocationCoordinate2D(
				latitude:  CLLocationDegrees(lat),
				longitude: CLLocationDegrees(lon))
		} else {
			self.location = nil
		}
	}
	
	init(from priest: Priest) {
		self.id       = priest.id
		self.name     = priest.name
		self.surname  = priest.surname
		self.location = nil
	}
}

func ==(x: PriestInfo, y: PriestInfo) -> Bool {
	return x.id == y.id && x.name == y.name && x.surname == y.surname
}

/// Partial information about a given **penitent** (aka, user).
struct PenitentInfo: RESTObject {
	
    let id: ResourceID
    let name : String
    let surname: String
    let location: CLLocationCoordinate2D!
	
    init(id: ResourceID, name: String, surname: String,
         latitude: String, longitude: String) {
		
        self.id = id
        self.name = name
        self.surname = surname
        self.location = CLLocationCoordinate2D(
			latitude:  CLLocationDegrees(latitude)!,
			longitude: CLLocationDegrees(longitude)!)
    }
	
	init(fromJSON json: [String: JSON]) {
		precondition(json.count <= 5)
		
		self.id      = json["id"]!.uInt64!
		self.name    = json["name"]!.string!
		self.surname = json["surname"]!.string!
		
		if let lat = json["latitude"]?.double, let lon = json["longitude"]?.double {
			self.location = CLLocationCoordinate2D(
				latitude:  CLLocationDegrees(lat),
				longitude: CLLocationDegrees(lon))
		} else {
			self.location = nil
		}
	}
}

// TODO: Should this really be a *struct*?
// TODO: All fields are optionals -- we can do better.

// MARK: -

/* CHURCH HAS BEEN DEPRECATED BY OLEG & CO
struct Church
{
    var id: Int64!
    var name: String!
    var street: String!
    var postCode: String!
    var city: String!
    var state: String!
    var country: String!
    
    init(id: Int64,
         name: String,
         street: String,
         postCode: String,
         city: String,
         state: String,
         country: String)
	{
        
        self.id = id
        self.name = name
        self.street = street
        self.postCode = postCode
        self.city = city
        self.state = state
        self.country = country
    }
}
*/

struct NotificationModel {
	static let MeetRequestModel = "MeetRequest"
	static let MessageModel = "Message"
}

//notification models
struct CreateMeetRequestNotification {
    var id: ResourceID!
    var status: String!
    var priestId: ResourceID!
    var penitent: PenitentInfo!
    
    init(id: ResourceID!, status: String!, priest_id: ResourceID!, penitent: PenitentInfo) {
        self.id = id
        self.status = status
        self.priestId = priest_id;
        self.penitent = penitent
    }
}

struct SentMeetRequestNotification {
    var id: ResourceID!
    var status: String!
    var priest: PriestInfo!
    var penitentId: UInt64!
    
    init(id: ResourceID!, status: String!, priest: PriestInfo, penitentId: ResourceID!) {
        self.id = id
        self.status = status
        self.priest = priest
        self.penitentId = penitentId
    }
}

struct MessageNotification {
    var id: UInt64!
    var sender_id: UInt64!
    var recipient_id: UInt64!
    var text: String!
    var createdAt: NSDate!
    var updatedAt: NSDate!
    
    init(id: UInt64!, sender_id: UInt64!, recipient_id: UInt64!, text: String!, createdAt: NSDate!, updatedAt: NSDate!) {
        self.id = id
        self.sender_id = sender_id
        self.recipient_id = recipient_id
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
