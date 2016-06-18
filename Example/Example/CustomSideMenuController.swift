//
//  CustomSideMenuController.swift
//  Example
//
//  Created by Teodor Patras on 16/06/16.
//  Copyright © 2016 teodorpatras. All rights reserved.
//

import Foundation
import SideMenuController

class CustomSideMenuController: SideMenuController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        performSegueWithIdentifier("showCenterController1", sender: nil)
        performSegueWithIdentifier("containSideMenu", sender: nil)
    }
}