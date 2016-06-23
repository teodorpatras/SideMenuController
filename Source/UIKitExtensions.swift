//
//  UIKitExtensions.swift
//
//  Copyright (c) 2015 Teodor Patraş
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

extension UIView {
    class func panelAnimation(duration : NSTimeInterval, animations : (()->()), completion : (()->())? = nil) {
        UIView.animateWithDuration(duration, animations: animations) { _ -> Void in
            completion?()
        }
    }
}

public extension UINavigationController {
    public func addSideMenuButton() {
        guard let image = SideMenuController.preferences.drawing.menuButtonImage else {
            return
        }
        
        guard let sideMenuController = self.sideMenuController else {
            return
        }
        
        let button = UIButton(frame: CGRectMake(0, 0, 40, 40))
        button.accessibilityIdentifier = SideMenuController.preferences.interaction.menuButtonAccessibilityIdentifier
        button.setImage(image, forState: UIControlState.Normal)
        button.addTarget(sideMenuController, action: #selector(SideMenuController.toggle), forControlEvents: UIControlEvents.TouchUpInside)
        
        let item:UIBarButtonItem = UIBarButtonItem()
        item.customView = button
        
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        spacer.width = -10
        
        if SideMenuController.preferences.drawing.sidePanelPosition.isPositionedLeft {
            self.topViewController?.navigationItem.leftBarButtonItems = [spacer, item]
        }else{
            self.topViewController?.navigationItem.rightBarButtonItems = [spacer, item]
        }
    }
}

public extension UIViewController {
    
    public var sideMenuController: SideMenuController? {
        return sideMenuControllerForViewController(self)
    }
    
    private func sideMenuControllerForViewController(controller : UIViewController) -> SideMenuController?
    {
        if let sideController = controller as? SideMenuController {
            return sideController
        }
        
        if let parent = controller.parentViewController {
            return sideMenuControllerForViewController(parent)
        } else {
            return nil
        }
    }
}
