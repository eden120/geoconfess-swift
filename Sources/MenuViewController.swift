//
//  MenuViewController.swift
//  GeoConfess
//
//  Created by Paulo Mattos on April 5, 2016.
//  Copyright © 2016 KTO. All rights reserved.
//

import UIKit
import SideMenu

/// Controls the side menu available at `MainViewController`.
final class MenuViewController: UITableViewController {
	
	@IBOutlet private var testView: UIView!
	@IBOutlet private var bottomImage: UIImageView!
	@IBOutlet private weak var bottomImageWidth: NSLayoutConstraint!
	@IBOutlet private weak var bottomImageHeight: NSLayoutConstraint!
	
	private let itemHeight = CGFloat(45)
	
	private var homePageController: HomePageViewController!

	private static let storyboard = UIStoryboard(name: "Menu", bundle: nil)
	
	static func createFor(homePageController homePageController: HomePageViewController)
		-> UISideMenuNavigationController {
		let menuNavController = storyboard.instantiateInitialViewController()
			as! UISideMenuNavigationController
		assert(menuNavController.leftSide)
		
		let menuController = menuNavController.viewControllers[0] as! MenuViewController
		menuController.homePageController = homePageController
			
		SideMenuManager.menuPresentMode = .MenuSlideIn
		SideMenuManager.menuAnimationFadeStrength = 0.45
		SideMenuManager.menuFadeStatusBar = false
		SideMenuManager.menuAnimationPresentDuration = 0.35
		SideMenuManager.menuAnimationDismissDuration = 0.20
		SideMenuManager.menuWidth = UIScreen.mainScreen().bounds.width * 0.70
		SideMenuManager.menuLeftNavigationController = menuNavController

		/*
		SideMenuManager.menuAddScreenEdgePanGesturesToPresent(
			toView: homePageController.navigationController.view)
		*/
			
		return menuNavController
	}
    
	// MARK: - View Controller Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationController!.navigationBarHidden = true
		tableView.scrollEnabled = false
		
		/*
		//let menuHeight =
		//	menuTitleHeight.constant + CGFloat(MenuItem.members.count) * itemHeight
		
		//let imageAspectRatio: CGFloat = 750 / 457
		//bottomImage.translatesAutoresizingMaskIntoConstraints = false
		//bottomImageWidth.constant  = SideMenuManager.menuWidth
		bottomImageHeight.constant = SideMenuManager.menuWidth / imageAspectRatio
		bottomImage.sizeToFit()
		//tableView.tableFooterView = bottomImage

		
		//bottomImageWidth.constant = SideMenuManager.menuWidth
		//bottomImage.layoutIfNeeded()
		//bottomImage.layoutIfNeeded()
		//bottomImage.frame.size.height = UIScreen.mainScreen().bounds.height - menuHeight
		//bottomImage.frame.size.height = 100
		//print("image: \(bottomImage.frame.width) X \(bottomImage.frame.height)")
		
		testView.frame.size.width  = SideMenuManager.menuWidth
		testView.frame.size.height = UIScreen.mainScreen().bounds.height - menuHeight - 0
		tableView.tableFooterView  = testView
		*/
	}
	
	override func viewDidLayoutSubviews() {
		//bottomImage.frame.size.width  = SideMenuManager.menuWidth
		//bottomImage.frame.size.height = SideMenuManager.menuWidth / imageAspectRatio
		
		//print("image: \(bottomImage.frame.width) X \(bottomImage.frame.height)")
		//print("image: \(bottomImage.frame.origin)")
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Slide)
		
		setMenuTitle()
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .Slide)
	}
	
	// MARK: - TableView Data Source
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView,
	                        numberOfRowsInSection section: Int) -> Int {
		assert(section == 0)
		return MenuItem.members.count
	}
	
	override func tableView(tableView: UITableView,
		cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		let item = MenuItem(rowIndex: indexPath.row)!
		let itemCell = tableView.dequeueReusableCellWithIdentifier(
			item.cellIdentifier, forIndexPath: indexPath) as! MenuItemCell
		
		itemCell.itemName.text = item.localizedName
		itemCell.itemName.preferredMaxLayoutWidth = SideMenuManager.menuWidth * 0.85
		itemCell.itemName.sizeToFit()
		return itemCell
	}

	// MARK: - TableView Delegate

	override func tableView(tableView: UITableView,
	                        heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return itemHeight
	}
	
	override func tableView(tableView: UITableView,
	                        didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		homePageController.dismissViewControllerAnimated(true, completion: nil)
		func performSegueWithIdentifier(id: String, keepMenu: Bool) {
			HomePageViewController.openMenuOnNextPresentation = keepMenu
			homePageController.performSegueWithIdentifier(id, sender: self)
		}
		
		switch MenuItem(rowIndex: indexPath.row)! {
		case .ConfessionFAQ:
			performSegueWithIdentifier("readConfessionFAQ", keepMenu: true)
		case .MakeDonation:
			let app = UIApplication.sharedApplication()
			app.openURL(NSURL(string: "https://donner.ktotv.com/a/mon-don")!)
		case .ConfessionNotes:
			performSegueWithIdentifier("readConfessionFAQ", keepMenu: true)
		case .Notes:
			performSegueWithIdentifier("editNotes", keepMenu: true)
		/*
		case .Favorites:
			performSegueWithIdentifier("listFavoritePriests", keepMenu: true)
		*/
		case .Share:
			performSegueWithIdentifier("browseContacts", keepMenu: true)
		case .Settings:
			performSegueWithIdentifier("editProfile", keepMenu: true)
		case .Help:
			break
		case .Logout:
			User.current.logoutInBackground {
				error in
                switch error {
                case .Success:
                    performSegueWithIdentifier("login", keepMenu: false)
                case .Failure(let error):
                    //logError(error.description)
                    self.homePageController.showAlert(message: "Impossible de se connecter à internet.")
                    //self.loginButton.enabled = true
                }
			}
		}
    }

	// MARK: - Menu Title

	@IBOutlet private var menuTitle: UIView!
	@IBOutlet private weak var menuTitleHeight: NSLayoutConstraint!
	
	@IBOutlet private weak var userNameLabel: UILabel!
	@IBOutlet private weak var userSurNameLabel: UILabel!
	
	private func setMenuTitle() {
		let user = User.current!
		userNameLabel.text = user.name
		userSurNameLabel.text = user.surname
	}
}
