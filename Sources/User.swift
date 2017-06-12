//
//  User.swift
//  GeoConfess
//
//  Created  by Матвей Кравцов on 2/2/2016.
//  Reviewed by Paulo Mattos on 5/10/2016.
//  Copyright © 2016 Матвей Кравцов. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import CoreLocation

// MARK: - User Class

/// Stores information about a given **user** (ie, **priest** or **penitent**).
/// An instance is available after a successful login.
class User: NSObject, Observable, CLLocationManagerDelegate, AppObserver {
    
	// MARK: User Properties

	let id: ResourceID
	let name: String
	let surname: String
	let email: String
	let role: Role
    let active: UInt
	/// The phone number is *optional*.
	let phoneNumber: String?
	
	/// Sensitive information -- extra care in the future.
	let oauth: OAuthTokens
	
	/// The specific user role within the app.
	enum Role: String {
		case Penitent = "user"
		case Priest   = "priest"
		case Admin    = "admin"
	}
	
	/// Loads additional data required for initializing `User` subclass.
	class func loadSubclassData(oauth: OAuthTokens, completion: (JSON?) -> Void) {
		completion(nil)
	}

	// MARK: Creating Users

	required init(oauth: OAuthTokens, userData: JSON, subclassData: JSON?) throws {
		assert(subclassData == nil)
		// Checks all *required* fields.
        print(userData.string)
		guard let id = userData["id"].uInt64 else {
			throw userData["id"].error!
		}
		guard let name = userData["name"].string else {
			throw userData["name"].error!
		}
		guard let surName = userData["surname"].string else {
			throw userData["surname"].error!
		}
		guard let email = userData["email"].string else {
			throw userData["email"].error!
		}
		guard let role = userData["role"].string else {
			throw userData["role"].error!
		}
        guard let active = userData["active"].uInt else {
            throw userData["active"].error!
        }
		assert(User.isValidEmail(email))
		
		self.id          = id
		self.name        = name
		self.surname     = surName
		self.phoneNumber = userData["phone"].string
		self.email       = email
		self.role        = User.Role(rawValue: role)!
		self.oauth       = oauth
        self.active      = active;
		self.locationTracker = CLLocationManager()
		super.init()
		
		App.addObserver(self)
		initLocationTracking()
		initNearbySpotsCache()
	}
	
	deinit {
		tearDownUser()
	}
	
	private func tearDownUser() {
		App.removeObserver(self)
		locationTracker.stopUpdatingLocation()
		cancelNearbySpotsRefresh()
	}
	
	func appDidUpdateConfiguration(config: App.Configuration) {
		reloadNearbySpotsCache()
	}
	
	// MARK: Current User
	
	// TODO: Is it a security clusterfuck?
	static let lastUserKey = "GeoConfessLastUser"
	static let lastUserPasswordKey = "GeoConfessLastUserPassword"
	
	/// The currently logged in user.
	/// Returns `nil` if no user available.
	static var current: User! {
		didSet {
			let defaults = NSUserDefaults.standardUserDefaults()
			if current != nil {
				defaults.setObject(current.email,
				                   forKey: User.lastUserKey)
				defaults.setObject(current.oauth.password,
				                   forKey: User.lastUserPasswordKey)
			} else {
				defaults.removeObjectForKey(User.lastUserKey)
				defaults.removeObjectForKey(User.lastUserPasswordKey)
			}
		}
	}

	/// The currently logged in *priest*.
	/// Returns `nil` if there is no user logged in *or*
	/// the current is not a priest.
	static var currentPriest: Priest! {
		guard let user = User.current else { return nil }
		guard let priest = user as? Priest else { return nil }
		assert(priest.role == .Priest)
		return priest
	}

	// MARK: Validating User Properties
	
	/// Email regulax expression.
	/// Solution based on this answer: http://stackoverflow.com/a/25471164/819340
	private static let emailRegex = regex(
		"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
	
	/// Is the *email* format valid?
	static func isValidEmail(email: String) -> Bool {
		return emailRegex.matchesString(email)
	}
	
	/// Is the *password* format valid?
	static func isValidPassword(password: String) -> Bool {
		return password.characters.count >= 6
	}
	
	/// Is the *phone number* format valid?
    static func isValidPhoneNumber(phone: String) -> Bool {
       	let phoneDetector = try! NSDataDetector(
			types: NSTextCheckingType.PhoneNumber.rawValue)
		
		let fullRange = NSMakeRange(0, phone.characters.count)
		let matches = phoneDetector.matchesInString(phone, options: [], range: fullRange)
		if let res = matches.first {
			return res.resultType == .PhoneNumber && NSEqualRanges(res.range, fullRange)
		} else {
			return false
		}
    }
	
	// MARK: Login Workflow

	/// Logins the specified user *asynchronously* in the background.
	/// This methods calls `/oauth/token` and then `/api/v1/me`.
	static func loginInBackground(username username: String, password: String,
								  completion: (Result<User, NSError>) -> Void) {
		
		log("Authenticating user \(username)...")
		requestOAuthTokens(username: username, password: password) {
			result in
			assert(NSThread.isMainThread())
			switch result {
			case .Success(let oauthTokens):
				log("Authenticating xuser \(username)... OK")
				log("Access token: \(oauthTokens.accessToken)")
				requestUserData(oauthTokens) {
					result -> Void in
					assert(NSThread.isMainThread())
					switch result {
					case .Success(let user):
						User.current = user
						completion(.Success(user))
					case .Failure(let error):
						logError("Get user error: \(error)")
						completion(.Failure(error))
					}
				}
			case .Failure(let error):
				logError("Auth user error: \(error)")
				completion(.Failure(error))
			}
		}
	}
	
	/// Logouts this user *asynchronously* in the background.
	func logoutInBackground(completion: (Result<Void, NSError>) -> Void) {
		preconditionIsMainQueue()
		tearDownUser()
		revokeOAuth(oauth) {
			error in
			if error == nil {
				User.current = nil
				log("User logout: OK (access token: \(self.oauth.accessToken))")
				#if DEBUG
					// Is this user actually logged out? 
					// Let's find out -- better be safe than sorry :-)
					checkIfOAuthAccessTokenIsValid(self.oauth) {
						validToken in
						assert(validToken == false)
					}
				#endif
				completion(.Success())
			} else {
				logError("Logout error: \(error)")
				completion(.Failure(error!))
			}
		}
	}

	// MARK: User Observers
	
	/// Observers list. The actual type is `ObserverSet<UserObserver>`.
	private var userObservers = ObserverSet()
	
	func addObserver(observer: UserObserver) {
		userObservers.addObserver(observer)
	}
	
	func removeObserver(observer: UserObserver) {
		userObservers.removeObserver(observer)
	}

	/// Method designed for subclasses.
	func notifyUserObservers(notify: (UserObserver) -> Void) {
		userObservers.notifyObservers {
			notify($0 as! UserObserver)
		}
	}

	// MARK: Location Tracking
	
	/// Tracks user's GPS related information.
	let locationTracker: CLLocationManager
	
	/// User current location.
	/// The value of this property is `nil` if
	/// no location data has ever been retrieved.
	var location: CLLocation? {
		return locationTracker.location
	}
	
	typealias LocationCallback = (CLLocation) -> Void
	private var locationCallbacks = [LocationCallback]()
	
	/// Registers the specified function to be called
	/// once the `location` property becomes available.
	/// The `completion` function will only be called *once* at most.
	func locationDidBecomeAvailable(completion: LocationCallback) {
		locationCallbacks.append(completion)
		if let location = location {
			notifyLocationIsAvailable(location)
		}
	}
	
	private func notifyLocationIsAvailable(location: CLLocation) {
		dispatch_async(dispatch_get_main_queue()) {
			for callback in self.locationCallbacks {
				callback(location)
			}
			self.locationCallbacks.removeAll()
		}
	}
	
	private func initLocationTracking() {
		locationTracker.delegate = self
		locationTracker.startUpdatingLocation()
		precondition(CLLocationManager.locationServicesEnabled())
		log("Core Location enabled: \(CLLocationManager.authorizationStatus())")
	}
	
	func locationManager(manager: CLLocationManager,
	                     didUpdateLocations locations: [CLLocation]) {
		preconditionIsMainQueue()
		let mostRecentLocation = locations.last!
		notifyUserObservers { $0.user(self, didUpdateLocation: mostRecentLocation) }
		notifyLocationIsAvailable(mostRecentLocation)
	}
	
	func locationManager(manager: CLLocationManager,
	                     didFailWithError error: NSError) {
		preconditionIsMainQueue()
		logError("Core Location: \(error)")
	}
	
	// MARK: Caching Nearby Spots
	
	/// All *active* spots *near* this user.
	/// Updates sent via `UserObserver` protocol.
	var nearbySpots: Set<Spot> = [ ] {
		didSet {
			if nearbySpots != oldValue {
				notifyUserObservers {
					$0.user(self, didUpdateNearbySpots: self.nearbySpots)
				}
			}
		}
	}
	
	private var spotsRefreshTimer: Timer?
	
	private func initNearbySpotsCache() {
		reloadNearbySpotsCache()
	}

	func reloadNearbySpotsCache() {
		cancelNearbySpotsRefresh()
		locationDidBecomeAvailable {
			location in
			self.updateNearbySpotsCacheAt(location)
		}
	}

	private func cancelNearbySpotsRefresh() {
		spotsRefreshTimer?.dispose()
		spotsRefreshTimer = nil
	}

	private func updateNearbySpotsCacheAt(location: CLLocation) {
		preconditionIsMainQueue()
		let running = "Updating spots near \(location.coordinate.shortDescription)"
		log("\(running)...")
		
		let coordinate = location.coordinate
		let radius = User.spotsMaxRadius
		let active = User.showOnlyActiveSpots
		Spot.getSpotsNearLocation(coordinate, distance: radius, onlyActive: active) {
			result in
			preconditionIsMainQueue()
			switch result {
			case .Success(let spots):
				log("\(running)... OK (\(spots.count) spots)")
				let rate = User.spotsRefreshRate
				self.spotsRefreshTimer = Timer.scheduledTimerWithTimeInterval(rate) {
					self.updateNearbySpotsCacheAt(self.location!)
				}
				self.nearbySpots = Set(spots)
			case .Failure(let error):
				logError("\(running)... FAILED. Will try again...\n\(error)")
				self.spotsRefreshTimer = Timer.scheduledTimerWithTimeInterval(5) {
					self.updateNearbySpotsCacheAt(self.location!)
				}
			}
		}
	}

	private static var spotsRefreshRate: NSTimeInterval {
		let key = "User Spots Refresh Rate (minutes)"
		let refresh = (App.properties[key]! as! NSNumber).doubleValue
		assert(refresh > 0)
		return refresh * 60
	}

	private static var spotsMaxRadius: Double {
		let key = "User Spots Max Radius (km)"
		let radius = (App.properties[key]! as! NSNumber).doubleValue
		assert(radius > 0)
		return radius * 1_000
	}
	
	private static var showOnlyActiveSpots: Bool {
		let key = "Show Only Active Spots on the Map"
		let value = (App.properties[key]! as! NSNumber).boolValue
		return value
	}
}

// MARK: - User Observer Protocol

/// User model events.
protocol UserObserver: class, Observer {
	
	/// Property `location` was updated.
	func user(user: User, didUpdateLocation location: CLLocation)
	
	/// Property `nearbySpots` was updated.
	func user(user: User, didUpdateNearbySpots spots: Set<Spot>)
}

// MARK: - OAuthTokens Struct

/// Stores OAuth tokens returned from a successful authentication.
struct OAuthTokens {
	let accessToken: String
	let refreshToken: String
	let tokenType: String
	let createdAt: Double

	/// Sensitive information -- extra care in the future.
	let password: String

	init(oauthResponse: JSON, password: String) throws {
		assert(User.isValidPassword(password))
		guard let accessToken = oauthResponse["access_token"].string else {
			throw oauthResponse["access_token"].error!
		}
		guard let refreshToken = oauthResponse["refresh_token"].string else {
			throw oauthResponse["refresh_token"].error!
		}
		guard let tokenType = oauthResponse["token_type"].string else {
			throw oauthResponse["token_type"].error!
		}
		guard let createdAt = oauthResponse["created_at"].double else {
			throw oauthResponse["created_at"].error!
		}
		self.accessToken  = accessToken
		self.refreshToken = refreshToken
		self.tokenType    = tokenType
		self.createdAt    = createdAt
		self.password     = password
	}
}

// MARK: -

/// Requests OAuth authorization (aka, *login*)..
private func requestOAuthTokens(username username: String,
								password: String,
								completion: Result<OAuthTokens, NSError> -> Void) {
	precondition(User.isValidEmail(username))
	precondition(User.isValidPassword(password))
	
	// The corresponding API is documented here:
	// http://geoconfess.herokuapp.com/apidoc/V1/credentials/show.html
	let oauthURL = "\(App.serverURL)/oauth/token"
	let parameters = [
		"grant_type": "password",
		"username":    username,
		"password":    password,
		"os": 		  "ios",
        "push_token": "3kjh123iu42i314g123"
	]
	
	Alamofire.request(.POST, oauthURL, parameters: parameters).responseJSON {
		response in
		switch response.result {
		case .Success(let value):
			do {
				let tokens = try OAuthTokens(oauthResponse: JSON(value),
					password: password)
				completion(.Success(tokens))
			} catch let error as NSError {
				completion(.Failure(error))
			}
		case .Failure(let error):
			completion(.Failure(error))
		}
	}
}

/// Revokes OAuth authorization (aka, *logout*).
private func revokeOAuth(oauthTokens: OAuthTokens,
                         completion: (error: NSError?) -> Void) {
	
	// Following advice given by Oleg Sulyanov.
	let oathURL = "\(App.serverURL)/oauth/revoke"
	let headers = [
		"Authorization": "\(oauthTokens.tokenType) \(oauthTokens.accessToken)"]
	let params = ["token": oauthTokens.accessToken]
	Alamofire.request(.POST, oathURL, parameters: params, headers: headers).responseJSON {
		response in
		switch response.result {
		case .Success:
			completion(error: nil)
		case .Failure(let error):
			completion(error: error)
		}
	}
}

/// Requests user information.
private func requestUserData(oauthTokens: OAuthTokens,
                             completion: (Result<User, NSError>) -> Void) {
	
	// The corresponding API is documented here:
	// http://geoconfess.herokuapp.com/apidoc/V1/credentials/show.html
	let meURL = "\(App.serverAPI)/me"
	let params = ["access_token": oauthTokens.accessToken]
	
	log("Getting user data...")
	Alamofire.request(.GET, meURL, parameters: params).responseJSON {
		response in
		switch response.result {
		case .Success(let value):
            print(value)
			let userData = JSON(value)
			let id   = userData["id"].uInt64!
			let role = User.Role(rawValue: userData["role"].string!)!
			log("Getting user data... OK (id: \(id), role: \(role))")
			
			let userClass: User.Type
			switch role {
			case .Penitent:	userClass = Penitent.self
			case .Priest:   userClass = Priest.self
			case .Admin:    userClass = User.self
			}
			userClass.loadSubclassData(oauthTokens) {
				subclassData in
				do {
					let user = try userClass.init(
						oauth: oauthTokens,
						userData: userData,
						subclassData: subclassData)
					completion(.Success(user))
				} catch let error as NSError {
					completion(.Failure(error))
				}
			}
		case .Failure(let error):
			completion(.Failure(error))
		}
	}
}

/// Just for testing purposes.
private func checkIfOAuthAccessTokenIsValid(oauthTokens: OAuthTokens,
                                            validToken: Bool -> Void) {
	requestUserData(oauthTokens) {
		result -> Void in
		switch result {
		case .Success:
			log("The access token \(oauthTokens.accessToken) is valid")
			validToken(true)
		case .Failure:
			log("The access token \(oauthTokens.accessToken) has been revoked")
			validToken(false)
		}
	}
}
