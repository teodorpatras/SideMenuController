//
//  SCViewController.swift
//  Example
//
//  Created by Teodor Patras on 15/07/16.
//  Copyright © 2016 teodorpatras. All rights reserved.
//

import UIKit

class SCViewController: CacheableViewController {

    override class var cacheIdentifier: String {
        return "SCViewController"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Second"
        view.backgroundColor = UIColor(hue:0.08, saturation:0.47, brightness:1.00, alpha:1.00)
    }
}
