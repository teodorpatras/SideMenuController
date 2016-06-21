//
//  ViewController.swift
//  Example
//
//  Created by Teodor Patras on 16/06/16.
//  Copyright © 2016 teodorpatras. All rights reserved.
//

import UIKit
import SideMenuController

class ViewController: UIViewController {

    static var fromStoryboard: ViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ViewController") as! ViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "TEEEST"
    }

    @IBAction func dismissAction() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

