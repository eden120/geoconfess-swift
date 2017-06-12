//
//  SpotsTableViewController.swift
//  GeoConfess
//
//  Created by MobileGod on 4/6/16.
//  Copyright © 2016 Andrei Costache. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import MapKit

/// Controls the **spots list** of the current **priest**.
final class SpotsTableViewController: AppViewControllerWithToolbar,
	UITableViewDelegate, UITableViewDataSource,
	GetPirestSpotDelegate, DeleteSpotDelegate {

    @IBOutlet weak private var tableView: UITableView!
    
    private var spots = [Spot]()
	
	private let arrWeekDays = [
		"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
	
	private let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	
    override func viewDidLoad() {
        super.viewDidLoad()

		// Inits UITableView.
        tableView.delegate = self
        tableView.registerNib(UINib(nibName: "SpotsTableViewCell", bundle: nil),
                              forCellReuseIdentifier: "SpotsTableViewCell")
		
		// Initiailze delegates.
        Networking.getPirestSpotDelegate = self
        Networking.deleteSpotDelegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
		
		// TODO: We should review this design in the future.
		// Initiailze delegate.
		Networking.getPirestSpotDelegate = self
		Networking.deleteSpotDelegate = self
		loadSpots()
    }
    
    // MARK: - Load Spots
		
	/// Load Spots and reload table.
    private func loadSpots() {
		showProgressHUD()
		spots = []
		//Networking.loadPirestSpot()
    }
    
    // MARK: - getPirestSpotDelegate Mothods
    
    func getPirestSpotDidSucceed(data: JSON) {
		
		/*
		dismissProgressHUD()
		
        let arrData: [JSON] = data.array!
        
        for spotInData in arrData{
            
            var spot: Spot!
//            if spotInData["activity_type"].stringValue == "static" {
//            
//                let priestInData = spotInData["priest"]
//                let priest = Priest(id: priestInData["id"].int64Value,
//                                    name: priestInData["name"].stringValue,
//									surname: priestInData["surname"].stringValue)
//                
//                spot = Spot(id: spotInData["id"].int64Value, name: spotInData["name"].stringValue, activity_type: "static", latitude: spotInData["latitude"].double, longitude:  spotInData["longitude"].double, street: spotInData["street"].string, postcode: spotInData["postcode"].string, city: spotInData["city"].string, state: spotInData["state"].string, country: spotInData["country"].string, priest: priest, recurrences: spotInData["recurrences"].arrayValue)
//				
//				
//				
//                spots.append(spot)
//            } else {
//                
//                // spot = Spot(id: spotInData["id"].int64Value, name: spotInData["name"].stringValue, church: nil, activity_type: "dynamic", latitude: spotInData["latitude"].double, longitude: spotInData["longitude"].double)
//            }
			
			var location = CLLocationCoordinate2D()
			location.latitude =  spotInData["latitude"].doubleValue
			location.longitude =  spotInData["longitude"].doubleValue
			
			let priestInData = spotInData["priest"]
			let priest = Priest(id: priestInData["id"].uInt64!,
			                    name: priestInData["name"].stringValue,
			                    surname: priestInData["surname"].stringValue)
			
			switch spotInData["activity_type"].stringValue{
			case "dynamic":
				spot = Spot(id: spotInData["id"].uInt64!,
				                    name: spotInData["name"].stringValue,
				                    activityType: .Dynamic,
				                    location: location,
				                    priest: priest)
				break
			case "static":
				let address:Address = Address(street: spotInData["street"].stringValue,
				                              postCode: spotInData["postcode"].stringValue,
				                              city: spotInData["city"].stringValue,
				                              state: spotInData["state"].stringValue,
				                              country: spotInData["country"].stringValue)
				
				let recurrences_dic = spotInData["recurrences"].array!
				var recurrences = [Recurrence]()
				for element in recurrences_dic {
					let recurrence:Recurrence = Recurrence(
						id: element["id"].uInt64!,
						spot_id: element["spot_id"].uInt64!,
						start_at: element["start_at"].string!,
						stop_at: element["stop_at"].string!,
						date: element["date"].string!,
						week_days: element["week_days"].array!.map { $0.string! }
					)
					recurrences.append(recurrence)
				}
				
				spot = Spot(id: spotInData["id"].uInt64!,
				                    name: spotInData["name"].stringValue,
				                    activityType: .Static(address, recurrences),
				                    location: location,
				                    priest: priest)
				break
			default:
				preconditionFailure()
			}
			spots.append(spot)
        }
        print(spots)
        tableView.reloadData()
		*/
    }
    
    func getPirestSpotDidFail(error: NSError) {
        dismissProgressHUD()
		showAlertForServerError(error)
    }
    
    // MARK: - TableView
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return spots.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(
			"SpotsTableViewCell", forIndexPath: indexPath) as! SpotsTableViewCell
        
        cell.lblSpotName.text  = spots[indexPath.row].name
        // TODO: cell.lblDetail.text = spots[indexPath.row].getInfo()
        cell.btnTrash.tag = Int(spots[indexPath.row].id)
        cell.btnEdit.tag = indexPath.row
        
        if indexPath.row % 2 == 0 {
            cell.contentView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            cell.lblSpotName.textColor = UIColor.darkGrayColor()
            cell.lblDetail.textColor = UIColor.darkGrayColor()
            cell.btnEdit.setImage(UIImage(named: "Pen"), forState: .Normal)
            cell.btnTrash.setImage(UIImage(named: "Trash"), forState: .Normal)
        } else {
            cell.contentView.backgroundColor = UIColor(red: 200.0/255.0, green: 70.0/255.0, blue: 83.0/255.0, alpha: 1.0)
            cell.lblSpotName.textColor = UIColor.whiteColor()
            cell.lblDetail.textColor = UIColor.whiteColor()
            cell.btnEdit.setImage(UIImage(named: "Alpha Pen"), forState: .Normal)
            cell.btnTrash.setImage(UIImage(named: "Alpha Trash"), forState: .Normal)
        }
        
        cell.btnTrash.addTarget(
			self, action: #selector(self.onDeleteSpot),
			forControlEvents: UIControlEvents.TouchUpInside)
        cell.btnEdit.addTarget(
			self, action: #selector(self.onEditSpot(_:)),
			forControlEvents: .TouchUpInside)
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath)
		-> CGFloat {
        return 80.0
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int)
		-> CGFloat {
        return 0.1
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int)
		-> CGFloat {
        return 0.1
    }
    
    // MARK: - Click TrashButton
	
    func onDeleteSpot(sender: UIButton) {
        let alertVC = UIAlertController(title: "Delete a Spot?", message: "", preferredStyle: .Alert)
        let yesAction = UIAlertAction(title: "Yes", style: .Default) {
			yesAction in
			self.dismissProgressHUD()
            Networking.deleteSpot(Int64(sender.tag))
        }
        let noAction = UIAlertAction(title: "No", style: .Cancel, handler: nil)
        alertVC.addAction(yesAction)
        alertVC.addAction(noAction)
        presentViewController(alertVC, animated: true, completion: nil)
    }
    
    // MARK: - Click EditButton
    
    func onEditSpot(sender: UIButton) {
		
		/*
		let spot:[Recurrence]
		switch spots[sender.tag].activityType{
		case .Dynamic:
			break
		case .Static( _, let recurrences):
			spot = recurrences
			if spot.count == 0 {
				appDelegate.isCreatePage = true
				appDelegate.date = ""
				appDelegate.spotID = spots[sender.tag].id
				appDelegate.recurrenceID = nil
			} else {
				
				appDelegate.isCreatePage = false
				
				let recurrence = spot.first!
				appDelegate.recurrenceID = recurrence.id
				appDelegate.startHour = (recurrence.start_at as NSString).substringToIndex(2)
				appDelegate.startMins = (recurrence.start_at as NSString).substringFromIndex(3)
				appDelegate.stopHour = (recurrence.stop_at as NSString).substringToIndex(2)
				appDelegate.stopMins = (recurrence.stop_at as NSString).substringFromIndex(3)
				
				if recurrence.date != "" {
					
					appDelegate.date = recurrence.date!
					appDelegate.arrChecks = [false, false, false, false, false, false, false]
				} else {
					appDelegate.date = ""
					let arrWeekDaysJSON = recurrence.week_days
					for weekDay in arrWeekDaysJSON! {
						appDelegate.arrChecks[arrWeekDays.indexOf(weekDay)!] = true
					}
				}
			}
			performSegueWithIdentifier("gotoEditRecurrence", sender: self)
		}
		*/
    }
	
    // MARK: - DeleteSpotDelegate Methods
	
    func deleteSpotDidSucceed(data: JSON) {
        dismissProgressHUD()
        loadSpots()
    }
	
    func deleteSpotDidFail(error: NSError) {
        dismissProgressHUD()
		showAlertForServerError(error)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "gotoEditRecurrence" {
            let vc = segue.destinationViewController
				as! CreateRecurrenceWithDateViewController
            
            if appDelegate.isCreatePage {
                vc.spotID = appDelegate.spotID
            } else {
                vc.recurrenceID = appDelegate.recurrenceID
            }
        } else if segue.identifier == "gotoCreateSpot" {
            appDelegate.isCreatePage = true
        }
    }
}
