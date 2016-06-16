//
//  SideMenuController.swift
//  SideMenuController
//
//  Created by Teodor Patras on 07.03.15.
//  Copyright (c) 2015 Teodor Patras. All rights reserved.
//

import UIKit

public extension SideMenuController {
    
    /**
     Toggles the side pannel visible or not.
     */
    public func toggleSidePanel() {
        
        if !transitionInProgress {
            if !sidePanelVisible {
                prepareSidePanel(forDisplay: true)
            }
            
            animate(toReveal: !self.sidePanelVisible)
        }
    }
    
    /**
     Embeds a new side controller
     
     - parameter controller: controller to be embedded
     */
    public func embedSideController(controller : UIViewController) {
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
     
     - parameter controller: controller to be embedded
     */
    public func embedCenterController(controller : UINavigationController) {
        
        prepareCenterControllerForContainment(controller)
        centerPanel.addSubview(controller.view)
        
        if centerViewController == nil {
            centerViewController = controller
            self.addChildViewController(centerViewController)
            centerViewController.didMoveToParentViewController(self)
            self.statusBarView.backgroundColor = controller.navigationBar.barTintColor
        }else{
            centerViewController.willMoveToParentViewController(nil)
            self.addChildViewController(controller)
            
            let completion : () -> () = {
                self.centerViewController.view.removeFromSuperview()
                self.centerViewController.removeFromParentViewController()
                controller.didMoveToParentViewController(self)
                self.centerViewController = controller
                self.statusBarView.backgroundColor = controller.navigationBar.barTintColor
            }
            
            let animator = self.dynamicType.preferences.animation.transitionAnimator
            animator.animateTransition(forViewController: controller, completion: completion)
            
            if (self.sidePanelVisible){
                animate(toReveal: false)
            }
        }
    }
}

public class SideMenuController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK:- Custom types -
    
    public enum SidePanelPosition {
        case UnderCenterPanelLeft
        case UnderCenterPanelRight
        case AboveCenterPanelLeft
        case AboveCenterPanelRight
    }
    
    public struct Preferences {
        public struct Layout {
            public var sidePanelPercentage: CGFloat = 0.4
            public var sidePanelWidth: CGFloat?
            public var menuButtonImage: UIImage?
            public var sidePanelPosition = SidePanelPosition.UnderCenterPanelLeft
            public var panningEnabled = true
            public var sideShadow = true
        }
        
        public struct Animation {
            public var reavealDuration = 0.3
            public var hideDuration = 0.2
            public var transitionAnimator: TransitionAnimatable.Type = FadeInAnimator.self
        }
        
        public var layout = Layout()
        public var animation = Animation()
        
        public init() {}
    }
    
    // MARK:- Constants -
    
    private lazy var screenSize: CGSize = {
       return UIScreen.mainScreen().bounds.size
    }()
    
    private var statusBarHeight: CGFloat {
       return UIApplication.sharedApplication().statusBarFrame.size.height > 0 ? UIApplication.sharedApplication().statusBarFrame.size.height : 20
    }
    
    // MARK: - Properties -
    
    public static var preferences: Preferences = Preferences()
    private(set) public var sidePanelVisible = false
    
    private var percentage: CGFloat {
        if let width = self.dynamicType.preferences.layout.sidePanelWidth {
            return width / screenSize.width
        }
        return self.dynamicType.preferences.layout.sidePanelPercentage
    }
    
    private var flickVelocity: CGFloat = 0
    private var sidePanelPosition: SidePanelPosition!
    private var centerViewController: UIViewController!
    private var sideViewController: UIViewController!
    private var statusBarView: UIView!
    private var centerPanel: UIView!
    private var sidePanel: UIView!
    private var centerShadowView: UIView!
    
    private var transitionInProgress = false
    private var landscapeOrientation: Bool {
        return screenSize.width > screenSize.height
    }
    
    private var leftSwipeRecognizer: UISwipeGestureRecognizer!
    private var rightSwipeGesture: UISwipeGestureRecognizer!
    private var panRecognizer: UIPanGestureRecognizer!
    private var tapRecognizer: UITapGestureRecognizer!
    
    private var canDisplaySideController: Bool {
        get {
            return sideViewController != nil
        }
    }
    
    // MARK:- View lifecycle -

    override public func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }
    
    // MARK:- Orientation changes -
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        screenSize = size
        
        coordinator.animateAlongsideTransition({ _ in
            // reposition center panel
            self.centerPanel.frame = self.centerPanelFrame
            // reposition side panel
            self.sidePanel.frame = self.sidePanelFrame
            
            // hide or show the view under the status bar
            if self.sidePanelVisible {
                self.statusBarView.alpha = self.landscapeOrientation ? 0 : 1
            }
            
            // reposition the center shadow view
            if let shadow = self.centerShadowView {
                shadow.frame = self.centerPanelFrame
            }
            
            self.view.layoutIfNeeded()
            
        }, completion: nil)
    }
    
    // MARK: - Configurations -
    
    private func configureViews(){
        
        sidePanelPosition = self.dynamicType.preferences.layout.sidePanelPosition
        
        centerPanel = UIView(frame: CGRectMake(0, 0, screenSize.width, screenSize.height))
        view.addSubview(centerPanel)
        
        statusBarView = UIView(frame: CGRectMake(0, 0, screenSize.width, statusBarHeight))
        view.addSubview(statusBarView)
        statusBarView.backgroundColor = UIApplication.sharedApplication().statusBarStyle == UIStatusBarStyle.LightContent ? UIColor.blackColor() : UIColor.whiteColor()
        statusBarView.alpha = 0
        
        sidePanel = UIView(frame: sidePanelFrame)
        view.addSubview(sidePanel)
        sidePanel.clipsToBounds = true
        
        configureGestureRecognizers()
        view.bringSubviewToFront(statusBarView)
    }
    
    private func configureGestureRecognizers() {
    
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapRecognizer.delegate = self
        
        if self.dynamicType.preferences.layout.sidePanelPosition == .UnderCenterPanelLeft ||
           self.dynamicType.preferences.layout.sidePanelPosition == .UnderCenterPanelRight {
            
            panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleCenterPanelPan))
            panRecognizer.delegate = self
            centerPanel.addGestureRecognizer(panRecognizer)
            
            view.sendSubviewToBack(sidePanel)
            centerPanel.addGestureRecognizer(tapRecognizer)
        } else {
            centerShadowView = UIView(frame: UIScreen.mainScreen().bounds)
            centerShadowView.backgroundColor = UIColor(hue:0.15, saturation:0.21, brightness:0.17, alpha:0.6)
            
            panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSidePanelPan))
            panRecognizer.delegate = self
            sidePanel.addGestureRecognizer(panRecognizer)
            view.bringSubviewToFront(sidePanel)
            
            leftSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleLeftSwipe))
            leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirection.Left
            
            rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipe))
            rightSwipeGesture.direction = UISwipeGestureRecognizerDirection.Right
            
            centerShadowView.addGestureRecognizer(tapRecognizer)
            
            if self.dynamicType.preferences.layout.sidePanelPosition == .AboveCenterPanelLeft {
                centerPanel.addGestureRecognizer(rightSwipeGesture)
                centerShadowView.addGestureRecognizer(leftSwipeRecognizer)
            }else{
                centerPanel.addGestureRecognizer(leftSwipeRecognizer)
                centerShadowView.addGestureRecognizer(rightSwipeGesture)
            }
        }
    }
    
    // MARK:- Containment -
    
    private func prepareCenterControllerForContainment (controller : UINavigationController){
        addMenuButtonToController(controller)
        let frame = CGRectMake(0, 0, CGRectGetWidth(self.centerPanel.frame), CGRectGetHeight(self.centerPanel.frame))
        controller.view.frame = frame
    }
    
    private func addMenuButtonToController(controller: UINavigationController) {
        
        guard let image = self.dynamicType.preferences.layout.menuButtonImage else {
            return
        }
        
        let shouldPlaceOnLeftSide = sidePanelPosition == .UnderCenterPanelLeft || sidePanelPosition == .AboveCenterPanelLeft
        
        let button = UIButton(frame: CGRectMake(0, 0, 40, 40))
        button.setImage(image, forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(toggleSidePanel), forControlEvents: UIControlEvents.TouchUpInside)
        
        let item:UIBarButtonItem = UIBarButtonItem()
        item.customView = button
        
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        spacer.width = -10
        
        if shouldPlaceOnLeftSide {
            controller.childViewControllers[0].navigationItem.leftBarButtonItems = [spacer, item]
        }else{
            controller.childViewControllers[0].navigationItem.rightBarButtonItems = [spacer, item]
        }
    }
    
    private func prepareSidePanel(forDisplay display: Bool){
        
        sidePanel.hidden = !display
        
        if sidePanelPosition == .AboveCenterPanelLeft || sidePanelPosition == .AboveCenterPanelRight {
            if display {
                if centerShadowView.superview == nil {
                    centerShadowView.alpha = 0
                    view.insertSubview(self.centerShadowView, belowSubview: self.sidePanel)
                }
            }else{
                centerShadowView.removeFromSuperview()
            }
        }else{
            showShadowForCenterPanel(true)
        }
    }
    
    private func animate(toReveal reveal: Bool){
        
        transitionInProgress = true
        
        self.sidePanelVisible = reveal
        let above = sidePanelPosition == .AboveCenterPanelLeft || sidePanelPosition == .AboveCenterPanelRight
        
        let hide = above ? setAboveSidePanelHidden : setUnderSidePanelHidden
        hide(!reveal) { _ in
            if !reveal {
                self.prepareSidePanel(forDisplay: false)
            }
            self.transitionInProgress = false
            self.centerViewController.view.userInteractionEnabled = !reveal
        }
    }
    
    func handleTap(gesture : UITapGestureRecognizer) {
        animate(toReveal: false)
    }
    
    // MARK:- .UnderCenterPanelLeft & Right -
    
    private func showShadowForCenterPanel(shouldShowShadow: Bool) {
        
        guard self.dynamicType.preferences.layout.sideShadow else {
            return
        }
        
        if shouldShowShadow {
            centerPanel.layer.shadowOpacity = 0.8
        } else {
            centerPanel.layer.shadowOpacity = 0.0
        }
    }
    
    private func setUnderSidePanelHidden (hidden : Bool, completion : (() -> ())?) {
        var centerPanelFrame = self.centerPanel.frame
        if !hidden {
            if sidePanelPosition == .UnderCenterPanelLeft {
                centerPanelFrame.origin.x = CGRectGetMaxX(self.sidePanel.frame)
            }else{
                centerPanelFrame.origin.x = CGRectGetMinX(self.sidePanel.frame) - CGRectGetWidth(self.centerPanel.frame)
            }
        } else {
            centerPanelFrame.origin = CGPointZero
        }
        
        var duration = hidden ? self.dynamicType.preferences.animation.hideDuration : self.dynamicType.preferences.animation.reavealDuration
        
        if abs(flickVelocity) > 0 {
            let newDuration = NSTimeInterval(self.sidePanel.frame.size.width / abs(flickVelocity))
            flickVelocity = 0
            
            if newDuration < duration {
                duration = newDuration
            }
        }
        
        
        UIView.panelAnimation( duration, animations: { () -> () in
            self.centerPanel.frame = centerPanelFrame
            if !self.landscapeOrientation {
                self.statusBarView.alpha = hidden ? 0 : 1
            }
        }) { () -> () in
            if hidden {
                self.showShadowForCenterPanel(false)
            }
            
            if (completion != nil) {
                completion!()
            }
        }
    }
    
    func handleCenterPanelPan(recognizer : UIPanGestureRecognizer){
        
        if !canDisplaySideController {
            return
        }
        
        self.flickVelocity = recognizer.velocityInView(recognizer.view).x
        let leftToRight = flickVelocity > 0
    
        switch(recognizer.state) {
        
        case .Began:
            if !sidePanelVisible {
                sidePanelVisible = true
                prepareSidePanel(forDisplay: true)
                showShadowForCenterPanel(true)
            }
            
        case .Changed:
            let translation = recognizer.translationInView(view).x
            let sidePanelFrame = sidePanel.frame
            
            // origin.x or origin.x + width
            let xPoint: CGFloat = centerPanel.center.x + translation + (sidePanelPosition == .UnderCenterPanelLeft ? -1  : 1 ) * CGRectGetWidth(centerPanel.frame) / 2
            
            
            if xPoint < CGRectGetMinX(sidePanelFrame) || xPoint > CGRectGetMaxX(sidePanelFrame){
                return
            }
            
            if !landscapeOrientation {
                if sidePanelPosition == .UnderCenterPanelLeft {
                    statusBarView.alpha = xPoint / CGRectGetWidth(sidePanelFrame)
                }else{
                    statusBarView.alpha =  1 - (xPoint - CGRectGetMinX(sidePanelFrame)) / CGRectGetWidth(sidePanelFrame)
                }
            }
            centerPanel.center.x = centerPanel.center.x + translation
            recognizer.setTranslation(CGPointZero, inView: view)
            
        default:
            if sidePanelVisible {
                
                var shouldOpen = true
                let centerFrame = centerPanel.frame
                let sideFrame = sidePanel.frame
                
                let shouldOpenPercentage = CGFloat(0.2)
                let shouldHidePercentage = CGFloat(0.8)
                
                if sidePanelPosition == .UnderCenterPanelLeft {
                    if leftToRight {
                        // opening
                        shouldOpen = CGRectGetMinX(centerFrame) > CGRectGetWidth(sideFrame) * shouldOpenPercentage
                    } else{
                        // closing
                        shouldOpen = CGRectGetMinX(centerFrame) > CGRectGetWidth(sideFrame) * shouldHidePercentage
                    }
                }else{
                    if leftToRight {
                        //closing
                        shouldOpen = CGRectGetMaxX(centerFrame) < CGRectGetMinX(sideFrame) + shouldOpenPercentage * CGRectGetWidth(sideFrame)
                    }else{
                        // opening
                        shouldOpen = CGRectGetMaxX(centerFrame) < CGRectGetMinX(sideFrame) + shouldHidePercentage * CGRectGetWidth(sideFrame)
                    }
                }
                
                animate(toReveal: shouldOpen)
            }
        }
    }
    
    // MARK:- .AboveCenterPanelLeft & Right -
    
    func handleSidePanelPan(recognizer : UIPanGestureRecognizer){
        
        if !canDisplaySideController {
            return
        }
        
        flickVelocity = recognizer.velocityInView(recognizer.view).x
        
        let leftToRight = self.flickVelocity > 0
        let sidePanelWidth = CGRectGetWidth(self.sidePanel.frame)
        
        switch recognizer.state {
        case .Began:
            prepareSidePanel(forDisplay: true)
        
        case .Changed:
            
            let translation = recognizer.translationInView(view).x
            let xPoint : CGFloat = self.sidePanel.center.x + translation + (sidePanelPosition == .AboveCenterPanelLeft ? 1 : -1) * sidePanelWidth / 2
            var alpha : CGFloat
            
            if sidePanelPosition == .AboveCenterPanelLeft {
                if xPoint <= 0 || xPoint > CGRectGetWidth(self.sidePanel.frame) {
                    return
                }
                alpha = xPoint / CGRectGetWidth(self.sidePanel.frame)
            }else{
                if xPoint <= screenSize.width - sidePanelWidth || xPoint >= screenSize.width {
                    return
                }
                alpha = 1 - (xPoint - (screenSize.width - sidePanelWidth)) / sidePanelWidth
            }
            
            if !landscapeOrientation{
                self.statusBarView.alpha = alpha
            }
            
            self.centerShadowView.alpha = alpha
            
            
            self.sidePanel.center.x = sidePanel.center.x + translation
            recognizer.setTranslation(CGPointZero, inView: view)
            
        default:
            
            let shouldClose = sidePanelPosition == .AboveCenterPanelLeft ? !leftToRight && CGRectGetMaxX(self.sidePanel.frame) < sidePanelWidth : leftToRight && CGRectGetMinX(self.sidePanel.frame) >  (screenSize.width - sidePanelWidth)
            
            animate(toReveal: !shouldClose)
            
        }
    }
    
    private func setAboveSidePanelHidden(hidden: Bool, completion : ((Void) -> Void)?){
        
        let leftSidePositioned = sidePanelPosition == .AboveCenterPanelLeft
        var destinationFrame = self.sidePanel.frame
        
        if leftSidePositioned {
            if hidden
            {
                destinationFrame.origin.x = -CGRectGetWidth(destinationFrame)
            } else {
                destinationFrame.origin.x = CGRectGetMinX(self.view.frame)
            }
        } else {
            if hidden
            {
                destinationFrame.origin.x = CGRectGetMaxX(self.view.frame)
            } else {
                destinationFrame.origin.x = CGRectGetMaxX(self.view.frame) - CGRectGetWidth(destinationFrame)
            }
        }
        
        var duration = hidden ? self.dynamicType.preferences.animation.hideDuration : self.dynamicType.preferences.animation.reavealDuration
        
        if abs(flickVelocity) > 0 {
            let newDuration = NSTimeInterval (destinationFrame.size.width / abs(flickVelocity))
            flickVelocity = 0
            
            if newDuration < duration {
                duration = newDuration
            }
        }
        
        UIView.panelAnimation(duration, animations: { () -> () in
            self.centerShadowView.alpha = hidden ? 0 : 1
            
            if !self.landscapeOrientation {
                self.statusBarView.alpha = hidden ? 0 : 1
            }
            
            self.sidePanel.frame = destinationFrame
            }, completion: completion)
    }
    
    func handleLeftSwipe(recognizer : UIGestureRecognizer){
        handleHorizontalSwipe(toLeft: true)
    }
    
    func handleRightSwipe(recognizer : UIGestureRecognizer){
        handleHorizontalSwipe(toLeft: false)
    }
    
    
    func handleHorizontalSwipe(toLeft left: Bool) {
        if (left && sidePanelPosition == .AboveCenterPanelLeft) ||
            (!left && sidePanelPosition == .AboveCenterPanelRight) {
            if sidePanelVisible {
                animate(toReveal: false)
            }
        } else {
            if !sidePanelVisible {
                prepareSidePanel(forDisplay: true)
                animate(toReveal: true)
            }
        }
    }
    
    // MARK:- UIGestureRecognizerDelegate -
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if gestureRecognizer == self.panRecognizer {
            return self.dynamicType.preferences.layout.panningEnabled
        }else if gestureRecognizer == self.tapRecognizer{
            return self.sidePanelVisible
        } else {
            return true
        }
    }
    
    // MARK:- Helpers -
    
    private var centerPanelFrame: CGRect {
        
        if (sidePanelPosition == .UnderCenterPanelLeft || sidePanelPosition == .UnderCenterPanelRight) && sidePanelVisible {
            
            let sidePanelWidth = percentage * min(screenSize.width, screenSize.height)
            
            return CGRectMake(sidePanelPosition == .UnderCenterPanelLeft ? sidePanelWidth : -sidePanelWidth, 0, screenSize.width, screenSize.height)
        } else {
            return CGRectMake(0, 0, screenSize.width, screenSize.height)
        }
    }
    
    private var sidePanelFrame: CGRect {
        var sidePanelFrame : CGRect
        
        let panelWidth = percentage * min(screenSize.width, screenSize.height)
        
        if sidePanelPosition == .UnderCenterPanelLeft || sidePanelPosition == .UnderCenterPanelRight {
            sidePanelFrame = CGRectMake(sidePanelPosition == .UnderCenterPanelLeft ? 0 :
                screenSize.width - panelWidth, 0, panelWidth, screenSize.height)
        } else {
            if sidePanelVisible {

                sidePanelFrame = CGRectMake(sidePanelPosition == .AboveCenterPanelLeft ? 0 : screenSize.width - panelWidth, 0, panelWidth, screenSize.height)
            } else {
                sidePanelFrame = CGRectMake(sidePanelPosition == .AboveCenterPanelLeft ? -panelWidth : screenSize.width, 0, panelWidth, screenSize.height)
            }
        }
        
        return sidePanelFrame
    }
}