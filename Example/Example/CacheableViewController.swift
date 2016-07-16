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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print(self.dynamicType.cacheIdentifier + " : " + #function + " <\(self)>")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        print(self.dynamicType.cacheIdentifier + " : " + #function + " <\(self)>")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        print(self.dynamicType.cacheIdentifier + " : " + #function + " <\(self)>")
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        print(self.dynamicType.cacheIdentifier + " : " + #function + " <\(self)>")
    }
}