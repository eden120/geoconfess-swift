//
//  FavoritePriest.swift
//  GeoConfess
//
//  Created by Christian Dimitrov on 5/2/16.
//  Copyright © 2016 Andrei Costache. All rights reserved.
//

import Alamofire
import SwiftyJSON

/// Stores a favorite priest.
/// See [docs](https://geoconfess.herokuapp.com/apidoc/V1/favorites.html)
final class FavoritePriest {
	
	/// Unique identifier for this favorite object.
	let id: UInt64
	
	/// Priest has location if he is active right *now*.
	let priest: PriestInfo
	
	private init(fromJSON json: [String: JSON]) {
		self.id = json["id"]!.uInt64!
		self.priest = PriestInfo(fromJSON: json["priest"]!.dictionary!)
		precondition(priest.name != nil && priest.surname != nil)
	}
	
	// MARK: - Backend Operations
	
	/// Returns all favorites of current user.
	/// No internal caching is performed.
	static func getAllForCurrentUser(
		completion: (favoritePriests: [FavoritePriest]?, error: NSError?) -> Void) {
		
		// The corresponding API is documented here:
		// https://geoconfess.herokuapp.com/apidoc/V1/favorites.html
		let url = "\(App.serverAPI)/favorites";
		let parameters: [String : AnyObject] = [
			"access_token": User.current.oauth.accessToken
		]
		Alamofire.request(.GET, url, parameters: parameters).responseJSON {
			response in
			switch response.result {
			case .Success(let value):
				let favoritesJSON: [JSON] = JSON(value).array!
				var favorites = [FavoritePriest]()
				for favoriteJSON in favoritesJSON {
					favorites.append(FavoritePriest(fromJSON: favoriteJSON.dictionary!))
				}
				completion(favoritePriests: favorites, error: nil)
			case .Failure(let error):
				logError("Favorites error: \(error)")
				completion(favoritePriests: nil, error: error)
			}
		}
	}
	
	/// Deletes this favorite priest entry.
	func delete(completion: (error: NSError?) -> Void) {
		// The corresponding API is documented here:
		// https://geoconfess.herokuapp.com/apidoc/V1/favorites/destroy.html
		let url = "\(App.serverAPI)/favorites/\(id)";
		let parameters: [String : AnyObject] = [
			"access_token": User.current.oauth.accessToken
		]
		Alamofire.request(.DELETE, url, parameters: parameters).responseJSON {
			response in
			switch response.result {
			case .Success:
				completion(error: nil)
			case .Failure(let error):
				logError("Delete favorite error: \(error)")
				completion(error: error)
			}
		}
	}
}
