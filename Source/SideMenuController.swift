//
//  SideMenuController.swift
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

import UIKit

public protocol SideMenuControllerDelegate: class {
    func sideMenuControllerDidHide(_ sideMenuController: SideMenuController)
    func sideMenuControllerDidReveal(_ sideMenuController: SideMenuController)
}

// MARK: - Public methods -

public extension SideMenuController {
    
    /**
     Toggles the side pannel visible or not.
     */
    public func toggle() {
        
        if !transitionInProgress {
            if !sidePanelVisible {
                prepare(sidePanelForDisplay: true)
            }
            
            animate(toReveal: !sidePanelVisible)
        }
    }
    
    /**
     Returns a view controller for the specified cache identifier
     
     - parameter identifier: cache identifier
     
     - returns: Cached UIViewController or nil
     */
    public func viewController(forCacheIdentifier identifier: String) -> UIViewController? {
        return controllersCache[identifier]
    }
    
    /**
     Embeds a new side controller
     
     - parameter sideViewController: controller to be embedded
     */
    public func embed(sideViewController controller: UIViewController) {
        if sideViewController == nil {
            
            sideViewController = controller
            sideViewController.view.frame = sidePanel.bounds
            
            sidePanel.addSubview(sideViewController.view)
            
            addChildViewController(sideViewController)
            sideViewController.didMove(toParentViewController: self)
            
            sidePanel.isHidden = true
        }
    }

    /**
     Embeds a new center controller.
     
     - parameter centerViewController: controller to be embedded
     - parameter cacheIdentifier: identifier for the view controllers cache
     */
    public func embed(centerViewController controller: UIViewController, cacheIdentifier: String? = nil) {
        
        if let id = cacheIdentifier {
            controllersCache[id] = controller
        }
        
        addChildViewController(controller)
        if let controller = controller as? UINavigationController {
            prepare(centerControllerForContainment: controller)
        }
        centerPanel.addSubview(controller.view)
        
        if centerViewController == nil {
            centerViewController = controller
            centerViewController.didMove(toParentViewController: self)
        } else {
            centerViewController.willMove(toParentViewController: nil)
            
            let completion: () -> () = {
                self.centerViewController.view.removeFromSuperview()
                self.centerViewController.removeFromParentViewController()
                controller.didMove(toParentViewController: self)
                self.centerViewController = controller
            }
            
            if let animator = _preferences.animating.transitionAnimator {
                animator.performTransition(forView: controller.view, completion: completion)
            } else {
                completion()
            }
            
            if sidePanelVisible {
                animate(toReveal: false)
            }
        }
    }
}

open class SideMenuController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK: - Instance variables -
    
    // MARK: Public
    
    open weak var delegate: SideMenuControllerDelegate?
    open static var preferences: Preferences = Preferences()
    internal(set) open var sidePanelVisible = false
    
    // MARK: Internal
    
    lazy var controllersCache = [String : UIViewController]()
    lazy var _preferences: Preferences = {
        return type(of: self).preferences
    }()
    
    fileprivate(set) open var centerViewController: UIViewController!
    fileprivate(set) open var sideViewController: UIViewController!
    var centerNavController: UINavigationController? {
        return centerViewController as? UINavigationController
    }
    var statusBarUnderlay: UIView!
    var centerPanel: UIView!
    var sidePanel: UIView!
    var centerPanelOverlay: UIView!
    var centerPanelSShot: UIView?

    var transitionInProgress = false
    var flickVelocity: CGFloat = 0
    
    lazy var screenSize: CGSize = {
        return UIScreen.main.bounds.size
    }()
    
    lazy var sidePanelPosition: SidePanelPosition = {
        return self._preferences.drawing.sidePanelPosition
    }()
    
    // MARK:- View lifecycle -

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpViewHierarchy()
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setUpViewHierarchy()
    }
    
    func setUpViewHierarchy() {
        view = UIView(frame: UIScreen.main.bounds)
        configureViews()
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if sidePanelVisible {
            toggle()
        }
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        screenSize = size
        
        coordinator.animate(alongsideTransition: { _ in
            // reposition center panel
            self.centerPanel.frame = self.centerPanelFrame
            // reposition side panel
            self.sidePanel.frame = self.sidePanelFrame
            
            // hide or show the view under the status bar
            self.set(statusUnderlayAlpha: self.sidePanelVisible ? 1 : 0)
            
            // reposition the center shadow view
            if let overlay = self.centerPanelOverlay {
                overlay.frame = self.centerPanelFrame
            }
            
            self.view.layoutIfNeeded()
            
        }, completion: nil)
        
        if sidePanelVisible {
            toggle()
        }
    }
    
    // MARK: - Configurations -
    
    func configureViews(){
        
        centerPanel = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        view.addSubview(centerPanel)
        
        statusBarUnderlay = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: statusBarHeight))
        view.addSubview(statusBarUnderlay)
        statusBarUnderlay.alpha = 0
        
        sidePanel = UIView(frame: sidePanelFrame)
        view.addSubview(sidePanel)
        sidePanel.clipsToBounds = true
        
        if sidePanelPosition.isPositionedUnder {
            view.sendSubview(toBack: sidePanel)
        } else {
            centerPanelOverlay = UIView(frame: centerPanel.frame)
            centerPanelOverlay.backgroundColor = _preferences.drawing.centerPanelOverlayColor
            view.bringSubview(toFront: sidePanel)
        }
        
        configureGestureRecognizers()
        view.bringSubview(toFront: statusBarUnderlay)
    }
    
    func configureGestureRecognizers() {
        if sidePanelPosition.isPositionedUnder {
            configureGestureRecognizersForPositionUnder()
        } else {
            configureGestureRecognizersForPositionOver()
        }
    }
    
    func set(statusBarHidden hidden: Bool, animated: Bool = true) {
        
        guard hidesStatusBar else {
            return
        }
        
        sbw?.set(hidden, withBehaviour: _preferences.animating.statusBarBehaviour)
        
        if _preferences.animating.statusBarBehaviour == StatusBarBehaviour.horizontalPan {
            if !hidden {
                centerPanelSShot?.removeFromSuperview()
                centerPanelSShot = nil
            } else if centerPanelSShot == nil {
                centerPanelSShot = UIScreen.main.snapshotView(afterScreenUpdates: false)
                centerPanel.addSubview(centerPanelSShot!)
            }
        }
    }
    
    // MARK:- Containment -

    func prepare(centerControllerForContainment controller: UINavigationController){
        controller.addSideMenuButton()
        controller.view.frame = centerPanel.bounds
    }
    
    func prepare(sidePanelForDisplay display: Bool){
        
        sidePanel.isHidden = !display
        
        if !sidePanelPosition.isPositionedUnder {
            if display && centerPanelOverlay.superview == nil {
                centerPanelOverlay.alpha = 0
                view.insertSubview(self.centerPanelOverlay, belowSubview: self.sidePanel)
            }else if !display {
                centerPanelOverlay.removeFromSuperview()
            }
        } else {
            setSideShadow(hidden: !display)
        }
    }
    
    // MARK: - Interaction -
    
    func animate(toReveal reveal: Bool){
        
        transitionInProgress = true
        sidePanelVisible = reveal
        
        if reveal {
            set(statusBarHidden: reveal)
        }
        
        let setFunction = sidePanelPosition.isPositionedUnder ? setUnderSidePanel : setAboveSidePanel
        setFunction(!reveal) { updated in
            if !reveal {
                self.prepare(sidePanelForDisplay: false)
                self.set(statusBarHidden: reveal)
            }
            self.transitionInProgress = false
            self.centerViewController.view.isUserInteractionEnabled = !reveal
            if updated {
                let delegateMethod = reveal ? self.delegate?.sideMenuControllerDidReveal : self.delegate?.sideMenuControllerDidHide
                delegateMethod?(self)
            }
        }
    }
    
    func set(statusUnderlayAlpha alpha: CGFloat) {
        guard showsStatusUnderlay else {
            return
        }
        
        if let color = centerNavController?.navigationBar.barTintColor , statusBarUnderlay.backgroundColor != color {
            statusBarUnderlay.backgroundColor = color
        }
        
        statusBarUnderlay.alpha = alpha
    }
    
    func handleTap() {
        animate(toReveal: false)
    }
    
    // MARK:- UIGestureRecognizerDelegate -
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        switch gestureRecognizer {
        case is UIScreenEdgePanGestureRecognizer:
            if _preferences.interaction.panningEnabled {
                if _preferences.drawing.sidePanelPosition.isPositionedLeft {
                    if (gestureRecognizer as? UIScreenEdgePanGestureRecognizer)?.edges == .right {
                        return sidePanelVisible
                    }
                    return true
                } else {
                    if (gestureRecognizer as? UIScreenEdgePanGestureRecognizer)?.edges == .left {
                        return sidePanelVisible
                    }
                    return true
                }
            } else {
                return false
            }
        case is UITapGestureRecognizer:
            return sidePanelVisible
        case is UISwipeGestureRecognizer:
            return _preferences.interaction.swipingEnabled
        default:
            return true
        }
    }
    
    // MARK: - Computed variables -
    
    fileprivate var sbw: UIWindow? {
        
        let s = "status"
        let b = "Bar"
        let w = "Window"
        
        return UIApplication.shared.value(forKey: s+b+w) as? UIWindow
    }
    
    fileprivate var showsStatusUnderlay: Bool {
        
        guard _preferences.animating.statusBarBehaviour == .showUnderlay else {
            return false
        }
        
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            return true
        }
        
        return screenSize.width < screenSize.height
    }
    
    var canDisplaySideController: Bool {
        return sideViewController != nil
    }
    
    fileprivate var statusBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.size.height > 0 ? UIApplication.shared.statusBarFrame.size.height : 20
    }
    
    fileprivate var hidesStatusBar: Bool {
        return [.slideAnimation, .fadeAnimation, .horizontalPan].contains(_preferences.animating.statusBarBehaviour)
    }
    
    fileprivate var centerPanelFrame: CGRect {
        
        if sidePanelPosition.isPositionedUnder && sidePanelVisible {
            
            let sidePanelWidth = _preferences.drawing.sidePanelWidth
            return CGRect(x: sidePanelPosition.isPositionedLeft ? sidePanelWidth : -sidePanelWidth, y: 0, width: screenSize.width, height: screenSize.height)
            
        } else {
            return CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
        }
    }
    
    fileprivate var sidePanelFrame: CGRect {
        var sidePanelFrame: CGRect
        
        let panelWidth = _preferences.drawing.sidePanelWidth
        
        if sidePanelPosition.isPositionedUnder {
            sidePanelFrame = CGRect(x: sidePanelPosition.isPositionedLeft ? 0 :
                screenSize.width - panelWidth, y: 0, width: panelWidth, height: screenSize.height)
        } else {
            if sidePanelVisible {
                sidePanelFrame = CGRect(x: sidePanelPosition.isPositionedLeft ? 0 : screenSize.width - panelWidth, y: 0, width: panelWidth, height: screenSize.height)
            } else {
                sidePanelFrame = CGRect(x: sidePanelPosition.isPositionedLeft ? -panelWidth : screenSize.width, y: 0, width: panelWidth, height: screenSize.height)
            }
        }
        
        return sidePanelFrame
    }
}
