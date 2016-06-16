//
//  SideContainmentSegue.swift
//  SideMenuController
//
//  Created by Teodor Patras on 16/06/16.
//  Copyright © 2016 teodorpatras. All rights reserved.
//

import Foundation

public class SideContainmentSegue: UIStoryboardSegue{
    
    override public func perform() {
        if let sideController = self.sourceViewController as? SideMenuController {
            sideController.addSideController(destinationViewController)
        } else {
            fatalError("This type of segue must only be used from a SideMenuController")
        }
    }
}