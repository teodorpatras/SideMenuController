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
    class func panelAnimation(_ duration : TimeInterval, animations : @escaping (()->()), completion : (()->())? = nil) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: animations) { _ in
            completion?()
        }
    }
}

public extension UINavigationController {
    public func addSideMenuButton(completion: ((UIButton) -> ())? = nil) {
        guard let image = SideMenuController.preferences.drawing.menuButtonImage else {
            return
        }
        
        guard let sideMenuController = self.sideMenuController else {
            return
        }
        
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        button.accessibilityIdentifier = SideMenuController.preferences.interaction.menuButtonAccessibilityIdentifier
        button.setImage(image, for: .normal)
        button.addTarget(sideMenuController, action: #selector(SideMenuController.toggle), for: UIControlEvents.touchUpInside)
        
        let item:UIBarButtonItem = UIBarButtonItem()
        item.customView = button
        
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        spacer.width = -10
        
        if SideMenuController.preferences.drawing.sidePanelPosition.isPositionedLeft {
            self.topViewController?.navigationItem.leftBarButtonItems = [spacer, item]
        }else{
            self.topViewController?.navigationItem.rightBarButtonItems = [spacer, item]
        }
        
        completion?(button)
    }
}

extension UIWindow {
    func set(_ hidden: Bool, withBehaviour behaviour: SideMenuController.StatusBarBehaviour) {
        let animations: () -> ()
        
        switch behaviour {
        case .fadeAnimation, .horizontalPan:
            animations = {
                self.alpha = hidden ? 0 : 1
            }
        case .slideAnimation:
            animations = {
                self.transform = hidden ? CGAffineTransform(translationX: 0, y: -20) : CGAffineTransform.identity
            }
        default:
            return
        }
        
        if behaviour == .horizontalPan {
            animations()
        } else {
            UIView.animate(withDuration: 0.25, animations: animations)
        }
    }
}

public extension UIViewController {
    
    public var sideMenuController: SideMenuController? {
        return sideMenuControllerForViewController(self)
    }
    
    fileprivate func sideMenuControllerForViewController(_ controller : UIViewController) -> SideMenuController?
    {
        if let sideController = controller as? SideMenuController {
            return sideController
        }
        
        if let parent = controller.parent {
            return sideMenuControllerForViewController(parent)
        } else {
            return nil
        }
    }
}
