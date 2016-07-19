//
//  TCViewController.swift
//  Example
//
//  Created by Teodor Patras on 15/07/16.
//  Copyright © 2016 teodorpatras. All rights reserved.
//

import UIKit

class TCViewController: CacheableViewController {
    
    override class var cacheIdentifier: String {
        return "TCViewController"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Third"
        view.backgroundColor = UIColor(hue:0.01, saturation:0.79, brightness:0.89, alpha:1.00)
    }
}
