//
//  FCViewController.swift
//  Example
//
//  Created by Teodor Patras on 15/07/16.
//  Copyright © 2016 teodorpatras. All rights reserved.
//

import UIKit

class FCViewController: CacheableViewController {
    
    override class var cacheIdentifier: String {
        return "FCViewController"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "First"
        view.backgroundColor = UIColor(hue:0.57, saturation:0.90, brightness:0.53, alpha:1.00)
    }
}
 
