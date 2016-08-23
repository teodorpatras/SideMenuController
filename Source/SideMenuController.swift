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
    func sideMenuControllerDidHide(sideMenuController: SideMenuController)
    func sideMenuControllerDidReveal(sideMenuController: SideMenuController)
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
            sideViewController.didMoveToParentViewController(self)
            
            sidePanel.hidden = true
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
            centerViewController.didMoveToParentViewController(self)
        } else {
            centerViewController.willMoveToParentViewController(nil)
            
            let completion: () -> () = {
                self.centerViewController.view.removeFromSuperview()
                self.centerViewController.removeFromParentViewController()
                controller.didMoveToParentViewController(self)
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

public class SideMenuController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK: - Instance variables -
    
    // MARK: Public
    
    public weak var delegate: SideMenuControllerDelegate?
    public static var preferences: Preferences = Preferences()
    internal(set) public var sidePanelVisible = false
    
    // MARK: Internal
    
    lazy var controllersCache = [String : UIViewController]()
    lazy var _preferences: Preferences = {
        return self.dynamicType.preferences
    }()
    
    var centerViewController: UIViewController!
    var centerNavController: UINavigationController? {
        return centerViewController as? UINavigationController
    }
    var sideViewController: UIViewController!
    var statusBarUnderlay: UIView!
    var centerPanel: UIView!
    var sidePanel: UIView!
    var centerPanelOverlay: UIView!
    var centerPanelSShot: UIView?

    var transitionInProgress = false
    var flickVelocity: CGFloat = 0
    
    lazy var screenSize: CGSize = {
        return UIScreen.mainScreen().bounds.size
    }()
    
    lazy var sidePanelPosition: SidePanelPosition = {
        return self._preferences.drawing.sidePanelPosition
    }()
    
    // MARK:- View lifecycle -

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpViewHierarchy()
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setUpViewHierarchy()
    }
    
    func setUpViewHierarchy() {
        view = UIView(frame: UIScreen.mainScreen().bounds)
        configureViews()
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if sidePanelVisible {
            toggle()
        }
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        screenSize = size
        
        coordinator.animateAlongsideTransition({ _ in
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
        
        centerPanel = UIView(frame: CGRectMake(0, 0, screenSize.width, screenSize.height))
        view.addSubview(centerPanel)
        
        statusBarUnderlay = UIView(frame: CGRectMake(0, 0, screenSize.width, statusBarHeight))
        view.addSubview(statusBarUnderlay)
        statusBarUnderlay.alpha = 0
        
        sidePanel = UIView(frame: sidePanelFrame)
        view.addSubview(sidePanel)
        sidePanel.clipsToBounds = true
        
        if sidePanelPosition.isPositionedUnder {
            view.sendSubviewToBack(sidePanel)
        } else {
            centerPanelOverlay = UIView(frame: centerPanel.frame)
            centerPanelOverlay.backgroundColor = _preferences.drawing.centerPanelOverlayColor
            view.bringSubviewToFront(sidePanel)
        }
        
        configureGestureRecognizers()
        view.bringSubviewToFront(statusBarUnderlay)
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
        
        if _preferences.animating.statusBarBehaviour == StatusBarBehaviour.HorizontalPan {
            if !hidden {
                centerPanelSShot?.removeFromSuperview()
                centerPanelSShot = nil
            } else if centerPanelSShot == nil {
                centerPanelSShot = UIScreen.mainScreen().snapshotViewAfterScreenUpdates(false)
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
        
        sidePanel.hidden = !display
        
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
        setFunction(hidden: !reveal) { updated in
            if !reveal {
                self.prepare(sidePanelForDisplay: false)
                self.set(statusBarHidden: reveal)
            }
            self.transitionInProgress = false
            self.centerViewController.view.userInteractionEnabled = !reveal
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
        
        if let color = centerNavController?.navigationBar.barTintColor where statusBarUnderlay.backgroundColor != color {
            statusBarUnderlay.backgroundColor = color
        }
        
        statusBarUnderlay.alpha = alpha
    }
    
    func handleTap() {
        animate(toReveal: false)
    }
    
    // MARK:- UIGestureRecognizerDelegate -
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        
        switch gestureRecognizer {
        case is UIScreenEdgePanGestureRecognizer:
            if _preferences.interaction.panningEnabled {
                if _preferences.drawing.sidePanelPosition.isPositionedLeft {
                    if (gestureRecognizer as? UIScreenEdgePanGestureRecognizer)?.edges == .Right {
                        return sidePanelVisible
                    }
                    return true
                } else {
                    if (gestureRecognizer as? UIScreenEdgePanGestureRecognizer)?.edges == .Left {
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
    
    private var sbw: UIWindow? {
        
        let s = "status"
        let b = "Bar"
        let w = "Window"
        
        return UIApplication.sharedApplication().valueForKey(s+b+w) as? UIWindow
    }
    
    private var showsStatusUnderlay: Bool {
        
        guard _preferences.animating.statusBarBehaviour == .ShowUnderlay else {
            return false
        }
        
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
            return true
        }
        
        return screenSize.width < screenSize.height
    }
    
    var canDisplaySideController: Bool {
        return sideViewController != nil
    }
    
    private var statusBarHeight: CGFloat {
        return UIApplication.sharedApplication().statusBarFrame.size.height > 0 ? UIApplication.sharedApplication().statusBarFrame.size.height : 20
    }
    
    private var hidesStatusBar: Bool {
        return [.SlideAnimation, .FadeAnimation, .HorizontalPan].contains(_preferences.animating.statusBarBehaviour)
    }
    
    private var centerPanelFrame: CGRect {
        
        if sidePanelPosition.isPositionedUnder && sidePanelVisible {
            
            let sidePanelWidth = _preferences.drawing.sidePanelWidth
            return CGRectMake(sidePanelPosition.isPositionedLeft ? sidePanelWidth : -sidePanelWidth, 0, screenSize.width, screenSize.height)
            
        } else {
            return CGRectMake(0, 0, screenSize.width, screenSize.height)
        }
    }
    
    private var sidePanelFrame: CGRect {
        var sidePanelFrame: CGRect
        
        let panelWidth = _preferences.drawing.sidePanelWidth
        
        if sidePanelPosition.isPositionedUnder {
            sidePanelFrame = CGRectMake(sidePanelPosition.isPositionedLeft ? 0 :
                screenSize.width - panelWidth, 0, panelWidth, screenSize.height)
        } else {
            if sidePanelVisible {
                sidePanelFrame = CGRectMake(sidePanelPosition.isPositionedLeft ? 0 : screenSize.width - panelWidth, 0, panelWidth, screenSize.height)
            } else {
                sidePanelFrame = CGRectMake(sidePanelPosition.isPositionedLeft ? -panelWidth : screenSize.width, 0, panelWidth, screenSize.height)
            }
        }
        
        return sidePanelFrame
    }
}