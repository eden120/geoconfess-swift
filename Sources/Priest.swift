//
//  Priest.swift
//  GeoConfess
//
//  Created by Paulo Mattos on 5/10/2016.
//  Copyright © 2016 Andrei Costache. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

// MARK: - Priest Class

/// Stores information about a given **priest**.
/// An instance is available after a priest did a successful login.
final class Priest: User {

	required init(oauth: OAuthTokens, userData: JSON, subclassData: JSON?) throws {
		self.staticSpots = [ ]
		self.dynamicSpot = nil
		try super.init(oauth: oauth, userData: userData, subclassData: nil)
		assert(self.role == .Priest)
		
		let priestInfo = PriestInfo(from: self)
		var dynamicSpotCount = 0
		for spotJSON in subclassData!.array! {
			let spot = Spot(fromJSON: spotJSON, forPriest: priestInfo)!
			switch spot.activityType {
			case .Static:
				staticSpots.append(spot)
			case .Dynamic:
				dynamicSpotCount += 1
				assert(dynamicSpotCount <= 1)
				// This is probably a *leftover* from a previous session.
				// Since we are *not* available for meeting, it should be deleted.
				assert(self.availableToMeet == false)
				spot.deleteSpot(userTokens: oauth) {
					result in
					switch result {
					case .Success, .Failure:
						/* We don't really care. */
						break
					}
				}
			}
		}
		assert(self.availableToMeet == false && self.dynamicSpot == nil)
	}
	
	// MARK: Static Spots
	
	/// All **static** spots defined by this priest.
	private(set) var staticSpots: [Spot]
	
	class override func loadSubclassData(oauth: OAuthTokens, completion: JSON? -> Void) {
		log("Loading priest spots in background...")
		getMySpots(oauth) {
			result in
			switch result {
			case .Success(let spots):
				let count = spots.array!.count
				log("Loading priest spots in background... OK (\(count) spots)")
				completion(spots)
			case .Failure(let error):
				logError("Spots loading failed: \(error)")
				completion(nil)
			}
		}
	}
	
	// MARK: Live Tracking
	
	/// Is this priest currently available to meet?
	/// If set, the priest will be *geolocated* in real-time
	/// so other users can see his position on the map.
	private(set) var availableToMeet: Bool = false {
		didSet {
			preconditionIsMainQueue()
			notifyPriestObservers {
				priestObserver in
				let newValue = self.availableToMeet
				priestObserver.priest(self, didSetAvailableToMeet: newValue)
			}
		}
	}
	
	/// Sets the `availableToMeet` property.
	func setAvailableToMeet(newValue: Bool, completion: Result<Void, NSError> -> Void) {
		guard availableToMeet != newValue else {
			completion(.Success())
			return
		}
		let oldValue = availableToMeet
		availableToMeet = newValue
		if !availableToMeet {
			dynamicSpot?.deleteSpot(userTokens: oauth) {
				result in
				switch result {
				case .Success:
					completion(.Success())
				case .Failure(let error):
					self.availableToMeet = oldValue
					completion(.Failure(error))
				}
			}
			dynamicSpot = nil
			return
		}
		// Sets priest as available to meet (ie, live tracking).
		locationDidBecomeAvailable {
			userLocation in
			self.createDynamicSpotAtLocation(userLocation) {
				result in
				switch result {
				case .Success(let dynamicSpot):
					self.dynamicSpot = dynamicSpot
					completion(.Success())
				case .Failure(let error):
					self.availableToMeet = oldValue
					completion(.Failure(error))
				}
			}
		}
	}
	
	/// This priest dynamic spot, if previously created and currently active.
	/// 
	/// **Specs**. *Update coordinates if user went to 100 meters from 
	/// previous spot update but not less than every 10 minutes.*
	private(set) var dynamicSpot: Spot? {
		didSet {
			preconditionIsMainQueue()
			if dynamicSpot != nil {
				assert(availableToMeet)
				scheduleNextDynamicSpotUpdate()
			} else {
				assert(!availableToMeet)
				cancelNextDynamicSpotUpdate()
			}
			reloadNearbySpotsCache()
		}
	}
	
	private var nextDynamicSpotUpdateTimer: Timer?
	
	private static var liveTrackingMaxUpdateInterval: NSTimeInterval {
		let key = "Priest Live Tracking Max Update Interval (minutes)"
		let minutes = (App.properties[key]! as! NSNumber).doubleValue
		assert(minutes > 0)
		return minutes * 60
	}

	private static var liveTrackingMaxDistanceFromLastUpdate: Double {
		let key = "User Spots Max Radius (km)"
		let distance = (App.properties[key]! as! NSNumber).doubleValue
		assert(distance > 0)
		return distance
	}

	private func scheduleNextDynamicSpotUpdate(seconds: NSTimeInterval! = nil) {
		preconditionIsMainQueue()
		cancelNextDynamicSpotUpdate()
		
		let interval = seconds ?? Priest.liveTrackingMaxUpdateInterval
		nextDynamicSpotUpdateTimer = Timer.scheduledTimerWithTimeInterval(interval) {
			preconditionIsMainQueue()
			assert(self.nextDynamicSpotUpdateTimer != nil)
			
			guard let dynamicSpot = self.dynamicSpot else { preconditionFailure() }
			guard let priestLocation = self.location else { preconditionFailure() }
			
			self.logDynamicSpotLocationUpdate(priestLocation, "scheduled refresh")
			dynamicSpot.setLocation(priestLocation) {
				result in
				switch result {
				case .Success:
					self.scheduleNextDynamicSpotUpdate()
				case .Failure:
					// Lets try again in a few seconds.
					self.scheduleNextDynamicSpotUpdate(randomDoubleInRange(4...10))
				}
			}
		}
	}
	
	private func cancelNextDynamicSpotUpdate() {
		preconditionIsMainQueue()
		guard nextDynamicSpotUpdateTimer != nil else { return }
		nextDynamicSpotUpdateTimer!.dispose()
		nextDynamicSpotUpdateTimer = nil
	}
	
	private func logDynamicSpotLocationUpdate(location: CLLocation, _ why: String) {
		let timeFormatter = NSDateFormatter()
		timeFormatter.dateFormat = "HH:mm:ss"
		let now = timeFormatter.stringFromDate(NSDate())
		log("Updating dynamic spot location to " +
			"\(location.coordinate) (\(now), \(why))")
	}
	
	override func locationManager(manager: CLLocationManager,
	                              didUpdateLocations locations: [CLLocation]) {
		super.locationManager(manager, didUpdateLocations: locations)
		preconditionIsMainQueue()
		guard let dynamicSpot = dynamicSpot else { return }
		
		let mostRecentLocation = locations.last!
		let distance = mostRecentLocation.distanceFromLocation(dynamicSpot.location)
		if distance >= Priest.liveTrackingMaxDistanceFromLastUpdate {
			logDynamicSpotLocationUpdate(mostRecentLocation, "distance from last")
			dynamicSpot.setLocation(mostRecentLocation) {
				result in
				switch result {
				case .Success:
					self.scheduleNextDynamicSpotUpdate()
				case .Failure:
					// Lets try again in a few seconds.
					self.scheduleNextDynamicSpotUpdate(10)
				}
			}
		}
	}
	
	private func createDynamicSpotAtLocation(spotLocation: CLLocation,
	                                         completion: Result<Spot, NSError> -> Void) {
		let dynamicSpot = Spot(
			name: name,
			activityType: .Dynamic,
			location: spotLocation,
			priest: PriestInfo(from: self)
		)
		dynamicSpot.createSpot {
			result in
			switch result {
			case .Success(let dynamicSpot):
				completion(.Success(dynamicSpot))
			case .Failure(let error):
				completion(.Failure(error))
			}
		}
	}
	
	/// Disables live tracking during logout.
	override func logoutInBackground(completion: Result<Void, NSError> -> Void) {
		setAvailableToMeet(false) {
			result in
			switch result {
			case .Success, .Failure:
				super.logoutInBackground(completion)
			}
		}
	}
	
	// MARK: Priest Observers
	
	private func notifyPriestObservers(notify: (PriestObserver) -> Void) {
		notifyUserObservers {
			userObserver in
			if let priestObserver = userObserver as? PriestObserver {
				notify(priestObserver)
			}
		}
	}
}

// MARK: - Priest Observer

/// Priest model events.
protocol PriestObserver: UserObserver {
	
	func priest(priest: Priest, didSetAvailableToMeet availableToMeet: Bool)
}

// MARK: - Utility Functions

/// Returns all spots for the specified priest.
private func getMySpots(oauth: OAuthTokens,
                        completion: (Result<JSON, NSError>) -> Void) {
	// The corresponding API is documented here:
	// https://geoconfess.herokuapp.com/apidoc/V1/spots.html
	let mySpotsURL = "\(App.serverAPI)/me/spots"
	let parameters = [
		"access_token": oauth.accessToken
	]
	Alamofire.request(.GET, mySpotsURL, parameters: parameters).responseJSON {
		response in
		switch response.result {
		case .Success(let value):
			completion(.Success(JSON(value)))
		case .Failure(let error):
			completion(.Failure(error))
		}
	}
}
