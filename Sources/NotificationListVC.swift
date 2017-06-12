//
//  File.swift
//  GeoConfess
//
//  Created by Christian Dimitrov on 4/19/16.
//  Copyright © 2016 Andrei Costache. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

private let cellID = "NotificationCell"

final class NotificationListVC: AppViewControllerWithToolbar {//, UITableViewDataSource, UITableViewDelegate {
	
	static func instantiateViewController() -> NotificationListVC {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		return storyboard.instantiateViewControllerWithIdentifier(
			"NotificationListVC") as! NotificationListVC
	}
	
	/*
    @IBOutlet weak private var tblNotificationList: UITableView!
    
    private var arrayNotifications = [Notification]()
	
    override func viewDidLoad(){
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        makeInterface()
    }
 
    func makeInterface() {
        tblNotificationList.delegate = self
        tblNotificationList.dataSource = self
        tblNotificationList.tableFooterView = UIView()
        tblNotificationList.backgroundColor = UIColor.whiteColor()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        getNotifications()
    }
    
	func getNotifications() {
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        NotificationManager.sharedInstance.getAllNotifications({(notifications: Array<Notification>?, success: Bool?, error: NSError?) -> Void in
            guard error == nil else {
                logError("Getting notifications failed!")
                self.showAlert(message: "Getting notifications failed!")
                return
            }
            
            log("Getting notifications successfully!")
            self.arrayNotifications = notifications!

            MBProgressHUD.hideHUDForView(self.view, animated: true)

            self.tblNotificationList.reloadData()
            
        })
    }
    
    // MARK: - Table View Methods
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 61
    }
	
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayNotifications.count
    }
	
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
        let cell = tableView.dequeueReusableCellWithIdentifier(cellID, forIndexPath: indexPath) as! NotificationCell

        let notification: Notification = arrayNotifications[indexPath.row]
        
        cell.isViewed = !notification.unread
        
        cell.setNotificationInfo(notification)
        
        if notification.unread == true {
            NotificationManager.sharedInstance.markNotificationAsRead(notification.id, completion: {(success, error) -> Void in
                //success process
            })
        }
        
        cell.selectionStyle = .None
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let notification: Notification = arrayNotifications[indexPath.row]

		switch User.current.role {
		case .Priest:
			if (notification.content as! MeetRequestNotification).status == "pending" {
				//user lands on screen - booking request
			}
			else if (notification.content as! MeetRequestNotification).status == "refused" {
				//remove from notification
			} else {
				//user lands on chat
			}
		case .Penitent, .Admin:
            if (notification.content as! MeetRequestNotification).status == "pending" {
                //user lands on priest page for pending request
            } else if (notification.content as! MeetRequestNotification).status == "refused" {
                //user lands on priest page for refused request
            } else {
                //user lands on chat
            }
        }
	
        print(notification)
        
    }
	*/
}
