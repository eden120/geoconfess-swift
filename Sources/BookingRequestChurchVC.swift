//
//  BookingRequestChurchVC.swift
//  GeoConfess
//
//  Created by Christian Dimitrov on 4/16/16.
//  Copyright © 2016 Andrei Costache. All rights reserved.
//

import UIKit

final class BookingStaticSpotViewController: AppViewControllerWithToolbar {
	
    @IBOutlet weak private var spotNameLabel: UILabel!
    @IBOutlet weak private var spotAddressLabel: UILabel!
    @IBOutlet weak private var recurrencesLabel: UILabel!

    @IBOutlet weak private var routeButton: UIButton!
	
	private var staticSpot: Spot!
	
	func setUp(staticSpot staticSpot: Spot) {
		self.staticSpot = staticSpot
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		guard case .Static(let spotAddress, let spotRecurrences)
			= staticSpot.activityType else {
			preconditionFailure("Static spot expected")
		}
		
		spotNameLabel.text = staticSpot.name
		
		var address = [String]()
		if let street   = spotAddress.street   { address.append(street)	  }
		if let postCode = spotAddress.postCode { address.append(postCode) }
		if let city     = spotAddress.city     { address.append(city)     }
		spotAddressLabel.text = address.joinWithSeparator(", ")
		
		if let recurrence = spotRecurrences.first {
			recurrencesLabel.text = recurrence.displayDescription
		}
    }
    
	@IBAction func routeButtonTapped(sender: AnyObject) {
		showAlert(message:"Ce temporairement indisponible. " +
			"Sera fixé sur la prochaine version.")
		/*
		let nextViewController = self.storyboard!
			.instantiateViewControllerWithIdentifier("AppleMapVC")
			as! AppleMapVC
		//nextViewController.data = self.thisSpotData!
		self.navigationController?.pushViewController(nextViewController,
		                                              animated: true)
		*/
	}
}