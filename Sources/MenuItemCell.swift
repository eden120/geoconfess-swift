//
//  MenuItemCell.swift
//  GeoConfess
//
//  Created by Paulo Mattos on 05/04/16.
//  Copyright © 2016 Andrei Costache. All rights reserved.
//

import UIKit
import SideMenu

/// A cell in the table controlled by `LeftMenuViewController`.
final class MenuItemCell: UITableViewVibrantCell {

	@IBOutlet weak var itemName: UILabel!
	@IBOutlet weak var arrow: UIImageView!
	
	/// Initialization code.
	override func awakeFromNib() {
		super.awakeFromNib()
	}
	
	/// Configure the view for the selected state.
	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
}

/// Menu item identifier.
enum MenuItem: UInt {
	
	case ConfessionFAQ   = 0
	//case MakeDonation    = 1
	case ConfessionNotes = 1
	case Notes           = 2
	//case Favorites       = 4
	case Share           = 3
	case Settings        = 4
	case Help            = 5
    case MakeDonation    = 6
	case Logout          = 7
	
	static let members = [
		ConfessionFAQ, ConfessionNotes,
		Notes, /*Favorites,*/ Share,
		Settings, Help, MakeDonation, Logout]
	
	init!(rowIndex rawValue: Int) {
		self.init(rawValue: UInt(rawValue))
	}
	
	var rowIndex: Int {
		return Int(rawValue)
	}
	
	var cellIdentifier: String {
		return "MenuItemCell"
	}
	
	var localizedName: String {
		switch self {
		case .ConfessionFAQ:
			return "Qu’est-ce que la confession"
		case .MakeDonation:
			return "Faire un don"
		case .ConfessionNotes:
			return "Préparer sa confession"
		case .Notes:
			return "Notes"
		/*
		case .Favorites:
			return "Favoris"
		*/
		case .Share:
			return "Partager"
		case .Settings:
			return "Modifications du compte"
		case .Help:
			return "Aide"
		case .Logout:
			return "Se déconnecter"
		}
	}
}

