//
//  BookingRequestViewController.swift
//  GeoConfess
//
//  Created  by Christian Dimitrov on April 15, 2016.
//  Reviewed by Paulo Mattos on May 5, 2016.
//  Copyright © 2016 KTO. All rights reserved.
//

import UIKit

final class BookingRequestViewController: AppViewControllerWithToolbar {
	
    @IBOutlet weak private var priestNameLabel: UILabel!
    @IBOutlet weak private var priestDistanceLabel: UILabel!
    @IBOutlet weak private var bookButton: UIButton!
    @IBOutlet weak private var favoriteButton: UIButton!
	
	private var thisSpotData: Spot!
	
	private static let userBookingStoryboard = UIStoryboard(
		name: "UserBooking", bundle: nil)
	
	static func startBookingWorkflowForSpot(spot: Spot, from sender: AppViewController) {
		switch spot.activityType {
		case .Static:
			let vc = userBookingStoryboard.instantiateViewControllerWithIdentifier(
				"BookingStaticSpotViewController") as! BookingStaticSpotViewController
			vc.setUp(staticSpot: spot)
			sender.navigationController.pushViewController(vc, animated: true)
		case .Dynamic:
			preconditionFailure("TODO")
		}
		
		
		/*
		switch spot["activity_type"] as! String {
		case "dynamic":
			var params = [String : AnyObject]()
			params["access_token"] = User.current.oauth.accessToken
			params["party_id"] = spot["priest"]!["id"]
			
			APICalls.sharedInstance.allRequestsOfCurrentUser(params) {
				(response, error) in
				// Getting request information against this priest.
				guard error == nil else {
					logError("Showing request failed!")
					source.showAlertForServerError(error!)
					return
				}
				print(response)
				
				let initialViewController: String
				if response!.count == 0 {
					// If there is no pending, accepted
					// or refused request to this priest.
					initialViewController = "BookingRequestViewController"
				} else {
					let dict = response!.objectAtIndex(0) as! NSDictionary
					switch dict["status"] as! String {
					case "pending", "refused":
						initialViewController = "BookingRequestPendingPriestVC"
					case "accepted":
						initialViewController = "BookingAcceptedPriestVC"
					default:
						preconditionFailure("unexpected status")
					}
				}
				let storyboard = UIStoryboard(name: "UserBooking", bundle: nil)
				let nextVC = storyboard
					.instantiateViewControllerWithIdentifier(initialViewController)
					as! BookingViewController
				//nextVC.thisSpotData = spot
				source.navigationController.pushViewController(nextVC, animated: true)
			}
		case "static":
			let nextVC = BookingStaticSpotViewController.instantiateViewController()
			//nextVC.thisSpotData = spot
			source.navigationController.pushViewController(nextVC, animated: true)
		default:
			preconditionFailure("unknown type")
		}
		*/
	}

    override func viewDidLoad() {
		NSUserDefaults.standardUserDefaults().objectForKey("requestsForUser")
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // Set Up a back button...
        let button = UIButton(type: .Custom)
        button.setImage(UIImage(named: "Back Button"), forState: .Normal)
        button.frame = CGRectMake(0, 0, 30, 30)
        button.addTarget(self, action: #selector(self.onBack),
                         forControlEvents: .TouchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
        
        // Set string values...
        self.priestNameLabel.text = self.thisSpotData.priest.surname
        self.priestDistanceLabel.text = String(format: "à %.0f mètres", calculateDistance())
    }
    
    func onBack() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    // Calculate distance from user to priest...
    func calculateDistance() -> CLLocationDistance {
        let from = User.current.location!
        let to   = CLLocation(latitude:  thisSpotData.location.coordinate.latitude,
                              longitude: thisSpotData.location.coordinate.longitude)
		return to.distanceFromLocation(from)
    }
    
    /// Send request to a priest.
    @IBAction func sendRequest(sender: UIButton) {
        // Get information of the request against a priest.
        var request = [String: AnyObject]()
        request["latitude"]  = User.current.location!.coordinate.latitude
        request["longitude"] = User.current.location!.coordinate.longitude
        request["priest_id"] = thisSpotData.priest.id as? AnyObject
		
        // Make parameters.
        var params = [String : AnyObject]()
        params["access_token"] = User.current.oauth.accessToken
        params["request"] = request
		
        print("Prameters of sendRequest api call:\(params)")
        
        //Call createReqest API
        APICalls.sharedInstance.createRequest(params) { (response, error) in
			guard error == nil else {
				logError("Creating request failed!")
				self.showAlert(message: "Creating request failed!")
				return
			}
			log("Created request successfully!")
			let nextViewController = self.storyboard!
				.instantiateViewControllerWithIdentifier("BookingRequestPendingPriestVC")
				as! BookingRequestPendingPriestVC
			nextViewController.thisSpotData = self.thisSpotData
			self.navigationController?.pushViewController(nextViewController,
			                                              animated: true)
        }
    }
    
    /// Add a priest to favorite.
    @IBAction func addToFavorite(sender: UIButton) {
        // Create a favorite about a priest.
        var favorite = [String: AnyObject]()
        favorite["priest_id"] = self.thisSpotData.priest.id as? AnyObject
        
        // Make Parameters.
        var params = [String: AnyObject]()
        params["access_token"] = User.current.oauth.accessToken
        params["favorite"] = favorite
        
        print("Prameters of createFavorite api call:\(params)")
        
        //Call createFavorite API.
        APICalls.sharedInstance.createFavorite(params) { (response, error) in
			guard error == nil else {
				logError("Creating favorite failed!")
				self.showAlert(message: "Creating favorite failed!")
				return
			}
			log("Created favorite successfully!")
			print("SpotData:\(self.thisSpotData)")
			self.showAlert(
				message: "\(self.thisSpotData.name) has been added to favorite!")
			self.favoriteButton.enabled = false
        }
    }
}
