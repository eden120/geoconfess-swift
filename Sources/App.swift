//
//  App.swift
//  GeoConfess
//
//  Created  by Матвей Кравцов on February 2, 2016.
//  Reviewed by Paulo Mattos on April 20, 2016.
//  Copyright © 2016 KTO. All rights reserved.
//

import Foundation

/// Global information for the **GeoConfess** app.
final class App {

	// MARK: - Server Information

	/// Our **RESTful** server/backend URL.
	static let serverURL = "https://geoconfess.herokuapp.com"
	
	/// URL for server/backend API.
	static let serverAPI = "\(App.serverURL)/api/v1"

	// AWS S3.
	static let cognitoPoolID = "eu-west-1:931c05b1-94ee-40a4-a691-6bce6b3edbb8"
	
	/// Google Maps key.
	///
	/// 	API key for bundle id `com.ktotv.geoconfess`. This key
	/// was generated using Paulo Mattos's Google Developer account
	/// (ie, paulo.rr.mattos@icloud.com).
	static let googleMapsApiKey = "AIzaSyCVCVu4E5UpoZcCfapDrJl4H7HfBNDt74c"

	// MARK: - App Configuration
	
	enum Configuration: String {
		
		/// The *official* config used in production.
		case Distribution
		
		/// The hacked/faster config used during development/tests.
		case Test
		
		var plistName: String {
			switch self {
			case .Distribution: return "GeoConfess-Dist"
			case .Test:         return "GeoConfess-Test"
			}
		}
	}
	
	private static let lastConfigKey = "GeoConfessLastConfig"
	
	static var configuration: Configuration = App.initialConfiguration() {
		didSet {
			let defaults = NSUserDefaults.standardUserDefaults()
			defaults.setObject(configuration.rawValue, forKey: lastConfigKey)
			properties = loadPropertiesFor(configuration)
			notifyObservers {
				$0.appDidUpdateConfiguration(configuration)
			}
		}
	}
	
	/// The initial configuration is based on the last one used.
	private static func initialConfiguration() -> Configuration {
		let defaults = NSUserDefaults.standardUserDefaults()
		let config: Configuration
		if let lastConfig = defaults.stringForKey(App.lastConfigKey) {
			config = Configuration(rawValue: lastConfig) ?? .Distribution
		} else {
			config = .Test
		}
		properties = loadPropertiesFor(config)
		return config
	}
	
	/// Returns the current GeoConfess's *properties list*.
	static var properties: [String: AnyObject]!

	@warn_unused_result
	private static func loadPropertiesFor(config: Configuration) -> [String: AnyObject] {
		let bundle = NSBundle.mainBundle()
		let plistPath = bundle.pathForResource(config.plistName, ofType: "plist")!
		let plist = NSDictionary(contentsOfFile: plistPath)
		return plist as! [String: AnyObject]
	}
	
	/// The actual type is `ObservableObject<AppObserver>`.
	private static let appObservers = ObserverSet()
	
	static func addObserver(observer: AppObserver) {
		App.appObservers.addObserver(observer)
	}
	
	static func removeObserver(observer: AppObserver) {
		App.appObservers.removeObserver(observer)
	}
	
	static func notifyObservers(notify: AppObserver -> Void) {
		App.appObservers.notifyObservers {
			notify($0 as! AppObserver)
		}
	}

	// MARK: - UI Colors
	
	/// This is the *main* color used across the UI.
	/// It resembles the [Carmine Pink](http://name-of-color.com/#EB4C42) color.
	static let tintColor = UIColor(red: 233/255, green: 72/255, blue: 84/255, alpha: 1)
}

// MARK: - App Observer

/// Observer for top-level app events.
protocol AppObserver: Observer {
	
	func appDidUpdateConfiguration(config: App.Configuration)
}

// MARK: - UIKit Extensions

extension UITextField {
	
	var isEmpty: Bool {
		return text == nil || text!.trimWhitespaces() == ""
	}
}

extension UIButton {
	
	static var enabledColor: UIColor {
		return UIColor(red: 237/255, green: 95/255, blue: 102/255, alpha: 1.0)
	}
	
	static var disabledColor: UIColor {
		return UIColor.lightGrayColor()
	}
}
