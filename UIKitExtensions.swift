//
//  UIKitExtensions.swift
//  SideMenuController
//
//  Created by Teodor Patras on 16/06/16.
//  Copyright © 2016 teodorpatras. All rights reserved.
//

import Foundation

extension UIView {
    class func panelAnimation(duration : NSTimeInterval, animations : (()->()), completion : (()->())? = nil) {
        UIView.animateWithDuration(duration, animations: animations) { _ -> Void in
            completion?()
        }
    }
}

public extension UIViewController {
    var sideMenuController: SideMenuController? {
        return sideMenuControllerForViewController(self)
    }
    
    private func sideMenuControllerForViewController(controller : UIViewController) -> SideMenuController?
    {
        if let sideController = controller as? SideMenuController {
            return sideController
        }
        
        if let parent = controller.parentViewController {
            return sideMenuControllerForViewController(parent)
        }else{
            return nil
        }
    }
}
