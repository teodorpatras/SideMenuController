//
//  CacheableViewController.swift
//  Example
//
//  Created by Teodor Patras on 15/07/16.
//  Copyright © 2016 teodorpatras. All rights reserved.
//

import UIKit

class CacheableViewController: UIViewController {
    
    class var cacheIdentifier: String {
        fatalError("To be overriden")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(type(of: self).cacheIdentifier + " : " + #function + " <\(self)>")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print(type(of: self).cacheIdentifier + " : " + #function + " <\(self)>")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(type(of: self).cacheIdentifier + " : " + #function + " <\(self)>")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print(type(of: self).cacheIdentifier + " : " + #function + " <\(self)>")
    }
}
