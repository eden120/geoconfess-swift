//
//  PriestSpotsViewController.swift
//  GeoConfess
//
//  Created  by Andreas Muller on April 6, 2016.
//  Reviewed by Paulo Mattos on May 9, 2016.
//  Copyright © 2016 Andrei Costache. All rights reserved.
//

import UIKit

/// Controls the first screen of the **priest spots** workflow.
final class PriestSpotsViewController: AppViewControllerWithToolbar {
	
	private static let storyboard = UIStoryboard(name: "PriestSpots", bundle: nil)
	
	class func instantiateViewController() -> PriestSpotsViewController {
		return storyboard.instantiateViewControllerWithIdentifier(
			"PriestSpotsViewController") as! PriestSpotsViewController
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		precondition(User.currentPriest != nil)
	}

    @IBAction func iAmMobileButtonTapped(sender: UIButton) {
		let priest = User.currentPriest!
		showProgressHUD()
		priest.setAvailableToMeet(true) {
			result in
			self.dismissProgressHUD()
			switch result {
			case .Success:
				self.showAlert(message:
					"Merci d'avoir activé la géolocalisation! " +
					"Vous recevrez une notification dès qu'un " +
					"pénitent vous enverra une demande de confession.") {
						self.navigationController.popViewControllerAnimated(true)
				}
			case .Failure(let error):
				preconditionFailure("setAvailableToMeet failed: \(error)")
			}
		}
	}
	
	override func shouldPerformSegueWithIdentifier(identifier: String,
	                                               sender: AnyObject?) -> Bool {
		if identifier == "listSpots" {
			showAlert(message:"Ce temporairement indisponible. " +
				"Sera fixé sur la prochaine version.")
			return false
		}
		return true
	}
}
