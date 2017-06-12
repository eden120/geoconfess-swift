//
//  ChoiceViewController.swift
//  GeoConfess
//
//  Created  by Матвей Кравцов on March 3, 2016.
//  Reviewed by Paulo Mattos on May 24, 2016.
//  Copyright © 2016 KTO. All rights reserved.
//

import UIKit

/// Controls the scene about choosing between **priest** or **user** sign up.
final class ChoiceViewController: AppViewController {

	@IBOutlet private weak var titleVerticalSpace: NSLayoutConstraint!
	@IBOutlet private weak var priestButtonVerticalSpace: NSLayoutConstraint!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		convertVerticalConstantFromiPhone6(titleVerticalSpace)
		convertVerticalConstantFromiPhone6(priestButtonVerticalSpace)
    }
}
