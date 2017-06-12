//
//  FavoritePriestsViewController.swift
//  GeoConfess
//
//  Created by Christian Dimitrov on 5/1/16.
//  Copyright © 2016 Andrei Costache. All rights reserved.
//

import UIKit
import SESlideTableViewCell

final class FavoritePriestsViewController: AppViewControllerWithToolbar,
	UITableViewDataSource, UITableViewDelegate, SESlideTableViewCellDelegate {
	
	@IBOutlet weak private var favoritesPriestsTable: UITableView!
	
	class func instantiateViewController() -> FavoritePriestsViewController {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		return storyboard.instantiateViewControllerWithIdentifier(
			"FavoritePriestsViewController") as! FavoritePriestsViewController
	}
	
	/// This is the *model* for this controller.
	private var favoritePriests: [FavoritePriest]! {
		didSet {
			favoritesPriestsTable.reloadData()
		}
	}
	
	override func viewDidLoad(){
		super.viewDidLoad()
		
		favoritesPriestsTable.delegate = self
		favoritesPriestsTable.dataSource = self
		
		favoritesPriestsTable.tableFooterView = UIView()
		favoritesPriestsTable.backgroundColor = UIColor.whiteColor()
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		showProgressHUD()
		FavoritePriest.getAllForCurrentUser {
			(favoritePriests: [FavoritePriest]?, error: NSError?) in
			self.dismissProgressHUD()
			guard let favoritePriests = favoritePriests else {
				logError("Getting favorites failed: \(error!)")
				self.showAlertForServerError(error!)
				return
			}
			self.favoritePriests = favoritePriests
		}
	}
	
	// MARK: - Table View Methods
	
	func tableView(tableView: UITableView,
	               heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 70
	}
	
	func tableView(tableView: UITableView,
	               numberOfRowsInSection section: Int) -> Int {
		return favoritePriests?.count ?? 0
	}
	
	func tableView(tableView: UITableView,
	               cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

		let cell = tableView.dequeueReusableCellWithIdentifier(
			"FavoritePriestCell",
			forIndexPath: indexPath) as! FavoritePriestCell
		
		cell.delegate = self
		cell.addRightButtonWithText(
			"Supprimer", textColor: UIColor.whiteColor(),
			backgroundColor: FavoritePriestCell.selectionColor
		)
		
		cell.favoritePriest = favoritePriests[indexPath.row]
		cell.showsLeftSlideIndicator  = true
		cell.showsRightSlideIndicator = true
		
		return cell
	}
	
	func tableView(tableView: UITableView,
	               didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		let cell = tableView.cellForRowAtIndexPath(indexPath) as! FavoritePriestCell
		showSelectedPriest(cell.favoritePriest)
	}
	
	// MARK: - SESlideTableViewCell
	
	func slideTableViewCell(
		cell: SESlideTableViewCell!,
		canSlideToState slideState: SESlideTableViewCellSlideState) -> Bool {
		
		switch slideState {
		case .Left:
			return cell.showsLeftSlideIndicator
		case .Right:
			return cell.showsRightSlideIndicator
		default:
			preconditionFailure("unexpected state: \(slideState)")
		}
		return true
	}
	
	func slideTableViewCell(
		cell: SESlideTableViewCell!,
		willSlideToState slideState: SESlideTableViewCellSlideState) {
		
		if let _ = favoritesPriestsTable.indexPathForCell(cell) {
			cell.setSelected(false, animated: true)
		}
	}
	
	func slideTableViewCell(
		cell: SESlideTableViewCell!,
		didSlideToState slideState: SESlideTableViewCellSlideState) {
		
		if let _ = favoritesPriestsTable.indexPathForCell(cell) {
			/* empty */
		}
	}
	
	func slideTableViewCell(
		cell: SESlideTableViewCell!,
		didTriggerRightButton buttonIndex: Int) {
		
		let indexPath = favoritesPriestsTable.indexPathForCell(cell)!
		let favoritePriest = favoritePriests[indexPath.row]
		favoritePriest.delete {
			error in
			guard error == nil else {
				logError("Deleting favorite failed: \(error)")
				self.showAlertForServerError(error!)
				return
			}
			self.favoritePriests.removeAtIndex(indexPath.row)
		}
	}
	
	// TODO: Part of this code should be moved to the booking workflow.
	private func showSelectedPriest(favoritePriest: FavoritePriest) {
		/*
		guard let priestLocation = favoritePriest.priest.location else {
			preconditionFailure("Priest location is nil")
		}
		let priest: NSDictionary = [
			"id": String(favoritePriest.priest.id),
			"name": favoritePriest.priest.name!,
			"surname": favoritePriest.priest.surname!
		]
		let spot: NSDictionary = [
			"activity_type": "dynamic",
			"priest": priest,
			"latitude":  priestLocation.latitude,
			"longitude": priestLocation.longitude
		]
		BookingRequestViewController.startBookingWorkflowForSpot(spot, from: self)
		*/
	}
}
