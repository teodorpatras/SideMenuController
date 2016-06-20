//
//  RootViewController.swift
//  Example
//
//  Created by Teodor Patras on 20/06/16.
//  Copyright © 2016 teodorpatras. All rights reserved.
//

import UIKit
import SideMenuController

class RootViewController: UIViewController {
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if motion == .MotionShake {
            dismissViewControllerAnimated(true, completion: { 
                if self.presentedViewController != nil {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            })
        }
    }
    
    @IBAction func programmaticAction() {
        
        let sideMenuViewController = SideMenuController()
        
        let viewController1 = UIViewController()
        viewController1.view.backgroundColor = UIColor.redColor()
        viewController1.title = "first"
        let nc1 = UINavigationController(rootViewController: viewController1)
        
        let viewController2 = UIViewController()
        viewController2.view.backgroundColor = UIColor.yellowColor()
        viewController2.title = "second"
        let nc2 = UINavigationController(rootViewController: viewController2)
        
        let viewController3 = UIViewController()
        viewController3.view.backgroundColor = UIColor.blueColor()
        viewController3.title = "third"
        let nc3 = UINavigationController(rootViewController: viewController3)
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [nc1, nc2, nc3]
        let nav = UINavigationController(rootViewController: tabBarController)
        
        let left = UITableViewController()
        
        
        sideMenuViewController.embedSideController(left)
        sideMenuViewController.embedCenterController(nav)
        
        showViewController(sideMenuViewController, sender: nil)
    }
}
