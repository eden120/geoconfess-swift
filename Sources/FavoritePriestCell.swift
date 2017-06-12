//
//  FavorisCell.swift
//  GeoConfess
//
//  Created by Christian Dimitrov on 5/2/16.
//  Copyright © 2016 Andrei Costache. All rights reserved.
//

import UIKit
import SESlideTableViewCell

/// Table cell in the favorite priests table.
final class FavoritePriestCell: SESlideTableViewCell {
	
	@IBOutlet weak private var priestIcon: UIImageView!
	@IBOutlet weak private var priestNameLabel: UILabel!
	@IBOutlet weak private var requestStatusLabel: UILabel!
	@IBOutlet weak private var distanceLabel: UILabel!
	@IBOutlet weak private var viewPriestCard: UIImageView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		priestIcon.image = UIImage(named: "logo-couleur-liste");
		viewPriestCard.image  = UIImage(named: "lblNext")
		backgroundColor  = UIColor.whiteColor()
	}

	var favoritePriest: FavoritePriest! {
		didSet {
			priestNameLabel.text = favoritePriest.priest.name
			requestStatusLabel.text = "CONFESSEUR"
			if let location = favoritePriest.priest.location {
				let myLocation = User.current.location!
				let priestLocation = CLLocation(at: location)
				let distance = priestLocation.distanceFromLocation(myLocation)
				distanceLabel.text = String(format: "à %.0f mètres", distance)
			} else {
				distanceLabel.text = ""
			}
		}
	}
	
	static let selectionColor = UIColor(
		colorLiteralRed: 237.0/255.0,
		green: 95.0/255.0,
		blue: 102.0/255.0,
		alpha: 1.0)

	/// Configure the view for the selected state.
	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		if selected {
			priestNameLabel.textColor = UIColor.whiteColor()
			requestStatusLabel.textColor     = UIColor.whiteColor()
			distanceLabel.textColor   = UIColor.whiteColor()
			priestIcon.image = UIImage(named: "logo-blanc-liste");
			viewPriestCard.image  = UIImage(named: "selectedLblNext")
			
			contentView.backgroundColor = FavoritePriestCell.selectionColor
		} else {
			priestNameLabel.textColor = UIColor.grayColor()
			requestStatusLabel.textColor     = UIColor.grayColor()
			distanceLabel.textColor   = UIColor.grayColor()
			priestIcon.image = UIImage(named: "logo-couleur-liste");
			viewPriestCard.image  = UIImage(named: "lblNext")
			
			contentView.backgroundColor = UIColor.whiteColor()
		}
	}
}