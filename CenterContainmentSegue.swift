//
//  CenterContainmentSegue.swift
//  SideMenuController
//
//  Created by Teodor Patras on 16/06/16.
//  Copyright © 2016 teodorpatras. All rights reserved.
//

import Foundation

public class CenterContainmentSegue: UIStoryboardSegue{
    
    override public func perform() {
        if let sideController = self.sourceViewController as? SideMenuController {
            guard let destinationController = destinationViewController as? UINavigationController else {
                fatalError("Destination controller needs to be an instance of UINavigationController")
            }
            sideController.embedCenterController(destinationController)
        } else {
            fatalError("This type of segue must only be used from a SideMenuController")
        }
    }
}
