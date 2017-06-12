//
//  MainViewController.swift
//  GeoConfess
//
//  Created  by Матвей Кравцов on 3/1/2016.
//  Reviewed by Paulo Mattos on 5/11/2016.
//  Copyright © 2016 Andrei Costache. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SideMenu
import GoogleMaps

/// Controls the app's main screen (aka, homepage).
final class HomePageViewController: AppViewControllerWithToolbar,
	GMSMapViewDelegate, UIPopoverPresentationControllerDelegate {
	
	// MARK: - View Controller Lifecyle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let user = User.current!
		
        print("User Info : \(user.oauth)");
		// Creates left menu.
		createMenu()
		
		// Map settings.
		map.myLocationEnabled = true
		map.settings.myLocationButton = false
		map.delegate = self

		// Updates map when user location is available.
		myLocationButton.alpha = 0.0
		myLocationButton.enabled = false
		user.locationDidBecomeAvailable {
			location in
			let userCamera = GMSCameraPosition(at: location.coordinate)
			self.map.animateToCameraPosition(userCamera)
			UIView.animateWithDuration(0.5,
				animations: {
					self.myLocationButton.alpha = 1.0
				},
				completion: {
					animationFinished in
					self.myLocationButton.enabled = true
				}
			)
		}
    }
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		let user = User.current!
		
		user.addObserver(self)
		mapRenderingDone = false
		scheduleSpotMarkersUpdate(user.nearbySpots)
		presentMenuIfRequested()
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
	}

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		
		// Kills observer if user still exits.
		User.current?.removeObserver(self)
	}

	// MARK: - User Geolocation
	
	@IBOutlet weak private var map: GMSMapView!
	@IBOutlet weak private var myLocationButton: UIButton!
	
	@IBAction func myLocationButtonTapped(sender: UIButton) {
		guard let location = User.current.location else { return }
		log("User location: \(location.coordinate)")
		map.animateToCameraPosition(GMSCameraPosition(at: location.coordinate))
	}
	
	override func user(user: User, didUpdateLocation location: CLLocation) {
		super.user(user, didUpdateLocation: location)
	}
	
	func mapView(mapView: GMSMapView,
	             didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
		#if DEBUG
			guard let userLocation = User.current.location else { return }
			let location = CLLocation(at: coordinate)
			let distance = userLocation.distanceFromLocation(location)
			let meters = String(format: "%.1f meters", distance)
			print("Tap at: \(coordinate) (\(meters))")
		#endif
	}
	
	// MARK: - Map Spots
	
	/// Each spot has its own marker.
	/// One of these days I'm gonna frame this and send it up to Bulgaria. 🤔
	private var spotMarkers = [Spot: GMSMarker]()

	/// Only adds the markers when the map is done loading.
	/// Not required at all, but provides a better UX.
	private func scheduleSpotMarkersUpdate(currentSpots: Set<Spot>) {
		preconditionIsMainQueue()
		Timer.scheduledTimerWithTimeInterval(1.25) {
			User.current.locationDidBecomeAvailable {
				location in
				self.runWhenMapIsReady = {
					self.updateSpotMarkers(currentSpots)
				}
				if self.mapRenderingDone {
					self.runWhenMapIsReady!()
					self.runWhenMapIsReady = nil
				}
			}
		}
	}
	
	private var runWhenMapIsReady: (() -> Void)?
	private var mapRenderingDone = false

	/// Called when map is stable (tiles loaded, labels rendered, camera idle)
	/// and overlay objects have been rendered.
	func mapViewSnapshotReady(mapView: GMSMapView) {
		preconditionIsMainQueue()
		runWhenMapIsReady?()
		runWhenMapIsReady = nil
		mapRenderingDone = true
		//print("--- mapViewSnapshotReady ---")
	}
	
	/// Update spot's markers incrementally.
	private func updateSpotMarkers(currentSpots: Set<Spot>) {
		let oldSpots = Set(spotMarkers.keys)
		for removedSpot in oldSpots.subtract(currentSpots) {
			spotMarkers[removedSpot]!.map = nil
			spotMarkers[removedSpot] = nil
		}
		var addedCount = 0
		for addedSpot in currentSpots.subtract(oldSpots) {
			let marker = GMSMarker(position: addedSpot.location.coordinate)
			marker.appearAnimation = kGMSMarkerAnimationPop
			marker.tappable  = true
			marker.draggable = false
			marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
			marker.userData = addedSpot
			marker.iconView = iconForSpotType(addedSpot.activityType)
			marker.opacity = 0.75
			marker.tracksViewChanges = false
			marker.map = self.map
			spotMarkers[addedSpot] = marker
			addedCount += 1
		}
		if addedCount > 0 { log("Drawing \(addedCount) new spots") }
		assert(spotMarkers.count == currentSpots.count)
		assert(Set(spotMarkers.keys) == currentSpots)
	}
	
	private func iconForSpotType(activityType: Spot.ActivityType) -> UIImageView {
		let iconImage: UIImage
		switch activityType {
		case .Static:
			iconImage = UIImage(named: "Static Spot Marker")!
		case .Dynamic:
			iconImage = UIImage(named: "Dynamic Spot Marker")!
		}
		let iconView = UIImageView(image: iconImage)
		let aspectRatio = iconImage.size.height / iconImage.size.width
		iconView.frame.size = CGSize(width: 45, height: 45 * aspectRatio)
		return iconView
	}
	
	override func user(user: User, didUpdateNearbySpots spots: Set<Spot>) {
		super.user(user, didUpdateNearbySpots: spots)
		scheduleSpotMarkersUpdate(spots)
	}
	
	private let userBookingStoryboard = UIStoryboard(name: "UserBooking", bundle: nil)
	
	func mapView(mapView: GMSMapView, didTapMarker marker: GMSMarker) -> Bool {
		let spot = marker.userData as! Spot
		BookingRequestViewController.startBookingWorkflowForSpot(spot, from: self)
		return true
	}
	
	// MARK: - Left Menu
	
	private var menuButton: UIBarButtonItem!
	private var sideMenuController: UISideMenuNavigationController!
	
	static var openMenuOnNextPresentation = false
	
	private func createMenu() {
		menuButton = navigationController.navigationBar.highlightedBarButtonWithImage(
			UIImage(named: "Menu Button")!,
			width: 33, hightlightIntensity: 0.3)
		menuButton.buttonView.addTarget(
			self,
			action: #selector(self.menuButtonTapped(_:)),
			forControlEvents: UIControlEvents.TouchUpInside
		)
		menuButton.enabled = true

		navigationItem.leftBarButtonItems = [menuButton]
		MenuViewController.createFor(homePageController: self)
	}
	
	private func presentMenuIfRequested() {
		guard HomePageViewController.openMenuOnNextPresentation else { return }
		HomePageViewController.openMenuOnNextPresentation = false
		presentViewController(SideMenuManager.menuLeftNavigationController!,
		                      animated: true, completion: nil)
	}
	
	@objc private func menuButtonTapped(sender: UIButton) {
		assert(sender === menuButton.buttonView)
		presentViewController(SideMenuManager.menuLeftNavigationController!,
		                      animated: true, completion: nil)
    }
}
