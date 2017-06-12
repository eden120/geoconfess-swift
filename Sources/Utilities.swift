/*
The MIT License (MIT)

Copyright (c) 2014-2016 Paulo Mattos, Antoine Berton

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall
be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

//
//  Utilities.swift
//  GeoConfess
//

import Foundation
import GoogleMaps
import SwiftyJSON

// MARK: - Strings

private let whitespaces = NSCharacterSet.whitespaceAndNewlineCharacterSet()

extension String {

	/// Removes whitespaces from both ends of the string.
	func trimWhitespaces() -> String {
		return self.stringByTrimmingCharactersInSet(whitespaces)
	}
}

// MARK: - Files & Directories

extension String {
	
	/// A new string made by deleting the extension
	/// (if any, and only the last) from the receiver.
	var stringByDeletingPathExtension: String {
		let string: NSString = self
		return string.stringByDeletingPathExtension
	}
	
	/// The last path component.
	/// This property contains the last path component. For example:
	///
	/// 	 /tmp/scratch.tiff ➞ scratch.tiff
	/// 	 /tmp/scratch ➞ scratch
	/// 	 /tmp/ ➞ tmp
	///
	var lastPathComponent: String {
		let string: NSString = self
		return string.lastPathComponent
	}
	
	/// The file-system path components of the receiver.
	/// For example:
	///
	/// 	 tmp/scratch.tiff ➞ ["tmp", "scratch.tiff"]
	/// 	 /tmp/scratch.tiff ➞ ["/", "tmp", "scratch.tiff"]
	///
	var pathComponents: [String] {
		let string: NSString = self
		return string.pathComponents
	}
	
	/// A new string made by standardizing path components from the receiver.
	var stringByStandardizingPath: String {
		let string: NSString = self
		return string.stringByStandardizingPath
	}
	
	/// A new string made by shrinking *extraneous* path components from the receiver.
	var stringByShrinkingPath: String {
		var path = self.stringByStandardizingPath.pathComponents
		
		// Use short form "~" for home dir.
		if path[0...1] == ["/", "Users"] {
			path.removeRange(0...2)
			path = ["~"] + path
		}
		
		// Shortens large components (ie ≥ 20 chars) to only 9 chars.
		// For instance, "399A7349-B28BZCH-AE2F5E56B" would be "399...56B"
		for (i, item) in path.enumerate() {
			guard item.characters.count >= 20 else { continue }
			let startIndex = item.startIndex
			let endIndex = item.endIndex
			let prefix = startIndex..<startIndex.advancedBy(3)
			let suffix = endIndex.advancedBy(-3)..<endIndex
			let shorten = item[prefix] + "..." + item[suffix]
			assert(shorten.characters.count == 9)
			path[i] = shorten
		}
		
		return NSString.pathWithComponents(path)
	}
}

// MARK: - Regular Expressions

/// *Regex* creation syntax sugar (with no error handling).
///
/// For a quick guide, see:
/// * [NSRegularExpression Cheat Sheet and Quick Reference](http://goo.gl/5QzdhX)
public func regex(pattern: String, options: NSRegularExpressionOptions = [ ])
-> NSRegularExpression {
	let regex = try! NSRegularExpression(pattern: pattern, options: options)
	return regex
}

/// Useful extensions for NSRegularExpression objects.
public extension NSRegularExpression {
	
	/// Returns `true` if the specified string is fully matched by this regex.
	public func matchesString(string: String) -> Bool {
		// Ranges are based on the UTF-16 *encoding*.
		let length = string.utf16.count
		precondition(length == (string as NSString).length)
		
		let wholeString = NSRange(location: 0, length: length)
		let matches = numberOfMatchesInString(string, options: [ ], range: wholeString)
		return matches == 1
	}
}

// MARK: - The Bare Bones Logging API ™

public func log(message: String, file: String = #file, line: UInt = #line) {
	let fileName = file.lastPathComponent.stringByDeletingPathExtension
	NSLog("[\(fileName):\(line)] \(message)")
	//print("ℹ️ [\(fileName):\(line)] \(message)")
}

public func logError(message: String, file: String = #file, line: UInt = #line) {
	let fileName = file.lastPathComponent.stringByDeletingPathExtension
	NSLog("[\(fileName):\(line)] ERROR: \(message)")
	//print("💀 [\(fileName):\(line)] \(message)")
}

// MARK: - Core Graphics

public func rect(x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat)
	-> CGRect {
	return CGRectMake(x, y, width, height)
}

// MARK: - UIKit

/// iPhone 6 height in *points*.
/// Yes, this is used for hacks!
private let iPhone6Height = CGFloat(667)

extension UIViewController {

	func convertVerticalConstantFromiPhone6(constraint: NSLayoutConstraint) {
		let screenHeight = UIScreen.mainScreen().bounds.height
		let height = constraint.constant
		constraint.constant = screenHeight * height/iPhone6Height
	}
}

/// Supoirt for common operations (eg, **alerts**, **popups**, etc).
extension UIViewController {

	/// Shows alert popup with only 1 button.
	func showAlert(title title: String? = nil, message: String,
				   ok: (() -> Void)? = nil) {
		let alert = UIAlertController(
			title: title, message: message, preferredStyle: .Alert)
		let okAction = UIAlertAction(title: "OK", style: .Default) {
			(action: UIAlertAction) -> Void in
			ok?()
		}
		alert.addAction(okAction)
		presentViewController(alert, animated: true, completion: nil)
	}

	/// Use this if you are not really sure what to show the user.
	func showAlertForServerError(error: NSError, ok: (() -> Void)? = nil) {
		// TODO: Handle error code -1003 as below?
		/*
		if error.code == -1003 {
			showAlert(title: "Error",
			          message: "Your internet does not seem to be working.")
		*/
		
		// TODO: Show property `error.localizedDescription` if available.
		
		showAlert(
			title: nil,
			message: "Erreur interne du serveur. Veuillez réessayer plus tard.",
			ok: ok
		)
	}
	
	// TODO: Review both methods below: `showProgressHUD` and `hideProgressHUD`.
	// There might be a better API design.

	/// Creates a new HUD, adds it to this view controller view and shows it. 
	/// The counterpart to this method is `hideProgressHUD`.
	func showProgressHUD(animated: Bool = true) {
		MBProgressHUD.showHUDAddedTo(self.view, animated: animated)
	}
	
	/// Finds all the HUD subviews and hides them.
	func dismissProgressHUD(animated: Bool = true) {
		MBProgressHUD.hideAllHUDsForView(self.view, animated: animated)
	}
}

extension UIColor {
	
	/// Creates a opaque color object using the specified RGB component values.
	convenience init(red: CGFloat, green: CGFloat, blue: CGFloat) {
		self.init(red: red, green: green, blue: blue, alpha: 1.0)
	}
	
	/// Compares this color with the specified components in the RGB color space.
	func equalsRed(red: CGFloat, green: CGFloat, blue: CGFloat) -> Bool {
		var r = CGFloat(0)
		var g = CGFloat(0)
		var b = CGFloat(0)
		let converted = self.getRed(&r, green: &g, blue: &b, alpha: nil)
		precondition(converted, "color space not compatible with RGB")
		
		return r == red && g == green && b == blue
	}
}

extension UIGestureRecognizerState: CustomStringConvertible {
	
	public var description: String {
		switch self {
		case .Possible:  return "Possible"
		case .Began:     return "Began"
		case .Changed:   return "Changed"
		case .Ended:     return "Ended"
		case .Cancelled: return "Cancelled"
		case .Failed:    return "Failed"
		}
	}
}

// MARK: - AutoLayout

/// This constraint requires the item's attribute
/// to be exactly **equal** to the specified value
func equalsConstraint(
	item item: AnyObject, attribute attrib1: NSLayoutAttribute, value: CGFloat)
	-> NSLayoutConstraint {
		
	return layoutConstraint(
		item: item, attribute: attrib1,
		relatedBy: .Equal,
		toItem: nil, attribute: .NotAnAttribute, constant: value)
}

/// This constraint requires the first attribute
/// to be exactly *equal* to the second attribute.
func equalsConstraint(
	item item: AnyObject, attribute attrib1: NSLayoutAttribute,
	     toItem: AnyObject?, attribute attrib2: NSLayoutAttribute,
	     multiplier: CGFloat = 1.0, constant: CGFloat = 0.0)
	-> NSLayoutConstraint {
	
	return layoutConstraint(
		item: item, attribute: attrib1,
		relatedBy: .Equal,
		toItem: toItem, attribute: attrib2,
		multiplier: multiplier, constant: constant)
}

/// Syntax sugar for `NSLayoutConstraint` init.
func layoutConstraint(
	item item: AnyObject, attribute attrib1: NSLayoutAttribute,
	     relatedBy: NSLayoutRelation,
	     toItem: AnyObject?, attribute attrib2: NSLayoutAttribute,
	     multiplier: CGFloat = 1.0, constant: CGFloat = 0.0)
	-> NSLayoutConstraint {
	
	return NSLayoutConstraint(
		item: item, attribute: attrib1,
		relatedBy: relatedBy,
		toItem: toItem, attribute: attrib2,
		multiplier: multiplier, constant: constant)
}

// MARK: - Preconditions Functions

/// Checks if we are running on the **main dispatch queue**
/// -- the one returned by `dispatch_get_main_queue()`.
func preconditionIsMainQueue(file: StaticString = #file, line: UInt = #line) {
	precondition(NSThread.isMainThread(),
	             "Code isn't running on the main dispatch queue",
	             file: file, line: line)
}

// MARK: - Timer Class

/// A simple timer class based on the `NSTimer` class.
/// As the `NSTimer`, this also fires if the app in on the background.
final class Timer {
	
	// MARK: Private Stuff
	
	private let callback: Callback
	private var timer: NSTimer?
	
	private init(seconds: NSTimeInterval, repeats: Bool, _ callback: Callback) {
		precondition(seconds >= 0)
		self.callback = callback
		self.timer = NSTimer.scheduledTimerWithTimeInterval(
			NSTimeInterval(seconds),
			target: self, selector: #selector(self.timerDidFire),
			userInfo: nil, repeats: repeats)
	}
	
	deinit {
		dispose()
	}
	
	@objc private func timerDidFire() {
		assert(NSThread.isMainThread())
		assert(timer != nil)
		callback()
	}
	
	// MARK: Timer API
	
	typealias Callback = () -> Void
	
	/// Schedules timer and returns it. 
	/// If `repeats` is true a periodic timer is created.
	class func scheduledTimerWithTimeInterval(interval: NSTimeInterval,
	                                          repeats: Bool = false,
	                                          callback: Callback) -> Timer {
		return Timer(seconds: interval, repeats: repeats, callback)
	}
	
	/// Cancels timer.
	func dispose() {
		timer?.invalidate()
		timer = nil
	}
}

// MARK: - Core Location

extension CLLocation {

	convenience init(at location: CLLocationCoordinate2D) {
		self.init(latitude: location.latitude, longitude: location.longitude)
	}
}

extension CLLocationCoordinate2D {
	
	/// Inits location from `"latitude"` and `"longitude"` JSON encoded entries.
	init?(fromJSON json: [String: JSON]) {
		guard let latitude  = json["latitude"]?.double  else { return nil }
		guard let longitude = json["longitude"]?.double else { return nil }
		self.init(latitude: latitude, longitude: longitude)
	}
}

extension CLLocationCoordinate2D: CustomStringConvertible {
	
	public var description: String {
		return String(format: "latitude: %.4f, longitude: %.4f", latitude, longitude)
	}
	
	var shortDescription: String {
		return String(format: "%.4f, %.4f", latitude, longitude)
	}
}

extension CLLocationCoordinate2D: Equatable, Hashable {
	
	public var hashValue: Int {
		return Int(latitude*100) + Int(longitude*100)*10_000
	}
}

public func ==(x: CLLocationCoordinate2D, y: CLLocationCoordinate2D) -> Bool {
	return x.latitude == y.latitude && x.longitude == y.longitude
}

extension CLAuthorizationStatus: CustomStringConvertible {
	
	public var description: String {
		switch self {
		case NotDetermined:
			return "NotDetermined"
		case Restricted:
			return "Restricted"
		case Denied:
			return "Denied"
		case AuthorizedAlways:
			return "AuthorizedAlways"
		case AuthorizedWhenInUse:
			return "AuthorizedWhenInUse"
		}
	}
}

// MARK: - Google Maps

extension GMSCameraPosition {
	
	/// Creates a `GMSCameraPosition` instance with default zoom level.
	convenience init(at location: CLLocationCoordinate2D, zoom: Float = 12.0) {
		self.init(target: location, zoom: zoom, bearing: 0, viewingAngle: 0)
	}
}

// MARK: - Pseudo Random Numbers

/// Returns randomized `Double` value in the `0.0`m 1.0` range.
/// Based on `random()` function from stdlib. 
/// Seed can be controlled via via `srandom()`.
func randomDouble() -> Double {
	let rand = Double(random()) / Double(Int32.max)
	assert(rand >= 0.0 && rand < 1.0)
	return rand
}

/// Returns randomized `Double` value in the specified range.
/// Based on `random()` function from stdlib.
/// Seed can be controlled via via `srandom()`.
func randomDoubleInRange(range: ClosedInterval<Double>) -> Double {
	let rand = range.start + randomDouble() * (range.end - range.start)
	assert(range.contains(rand))
	return rand
}

// MARK: - Observers

/// A facility for observers of single events (ie, one time events).
/// The registered `completion` function will be called *once* at most.
final class SingleEventObservers<Callback> {
	// TODO: Still looking for the correct design here.
}

// MARK: - Weak References

/// Wrapper for *weak references*.
/// Useful for storing weak references in collections, for instance.
///
/// ♨️ **Android Hint**. This struct is very similar
/// to the **[java.lang.ref.WeakReference<T>](https://goo.gl/WQd8Je)** class.
struct Weak<T: AnyObject>: Equatable, Hashable, CustomStringConvertible {
	
	private weak var objectRef: T?
	private let stableAndFastHashValue: Int
	
	init(_ object: T) {
		self.objectRef = object
		self.stableAndFastHashValue = unsafeAddressOf(object).hashValue
	}
	
	var object : T? {
		return objectRef
	}
	
	var hashValue: Int {
		// It is not a good design to have a non-constant hashcode.
  		// For instance, this enables this struct to be safely used as dictionary keys.
		return stableAndFastHashValue
	}
	
	var description: String {
		let objectDesc: String
		if let object = objectRef {
			objectDesc = String(object)
		} else {
			objectDesc = "nil"
		}
		return "Weak(\(objectDesc))"
	}
}

/// `Equatable` protocol.
func ==<T: AnyObject>(lhs: Weak<T>, rhs: Weak<T>) -> Bool {
	return lhs.object === rhs.object
}
