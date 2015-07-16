//
//  SideMenuController.swift
//  SideMenuController
//
//  Created by Teodor Patras on 07.03.15.
//  Copyright (c) 2015 Teodor Patras. All rights reserved.
//

import UIKit

let CenterSegue = "CenterContainment"
let SideSegue   = "SideContainment"

class SideMenuController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK:- Custom types -
    
    enum SideMenuControllerPresentationStyle {
        case UnderCenterPanelLeft
        case UnderCenterPanelRight
        case AboveCenterPanelLeft
        case AboveCenterPanelRight
    }
    
    enum CenterContainmentAnimationStyle {
        case CircleMaskAnimation
        case FadeAnimation
    }
    
    // MARK:- Constants -
    
    private let revealAnimationDuration : NSTimeInterval = 0.3
    private let hideAnimationDuration   : NSTimeInterval = 0.2
    
    private var screenSize = UIScreen.mainScreen().bounds.size
    /** 
    If the SideMenuController is the root controller of the app and the
    project target has the "Hide status bar" option enabled, the StatusBarHeight
    constant will be 0. Therefore there is no other way of getting the height except
    hardcoding it.
    **/
    private let StatusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height > 0 ? UIApplication.sharedApplication().statusBarFrame.size.height : 20
    
    // MARK: - Customizable properties -
    
    private struct PrefsStruct {
        static var percentage: CGFloat  = 0.7
        static var sideStyle            = SideMenuControllerPresentationStyle.UnderCenterPanelLeft
        static var shadow: Bool         = true
        static var panning : Bool       = true
        static var animationStyle       = CenterContainmentAnimationStyle.CircleMaskAnimation
        static var menuButtonImage : UIImage?
        
    }
    
    class var menuButtonImage : UIImage? {
        get { return PrefsStruct.menuButtonImage }
        set { PrefsStruct.menuButtonImage = newValue }
    }
    
    class var panningEnabled : Bool {
        get { return PrefsStruct.panning }
        set { PrefsStruct.panning = newValue }
    }
    
    class var presentationStyle : SideMenuControllerPresentationStyle {
        get { return PrefsStruct.sideStyle }
        set { PrefsStruct.sideStyle = newValue }
    }
    
    class var animationStyle : CenterContainmentAnimationStyle
    {
        get { return PrefsStruct.animationStyle }
        set { PrefsStruct.animationStyle = newValue }
    }
    
    class var useShadow: Bool
        {
        get { return PrefsStruct.shadow }
        set { PrefsStruct.shadow = newValue }
    }
    
    /*
    Side Controller Width = sidePercentage * Screen Width
    */
    
    class var sidePercentage: CGFloat
        {
        get { return PrefsStruct.percentage }
        set { PrefsStruct.percentage = newValue }
    }
    
    
    // MARK: -      Private properties -
    
    private var navigationBar           : UINavigationBar!
    private var presentationStyle       : SideMenuControllerPresentationStyle!
    private var animationStyle          : CenterContainmentAnimationStyle!
    private var percentage              : CGFloat!
    private var flickVelocity           : CGFloat = 0
    
    private var centerViewController    : UIViewController!
    private var sideViewController      : UIViewController!
    private var statusBarView           : UIView!
    private var centerPanel             : UIView!
    private var sidePanel               : UIView!
    private var centerShadowView        : UIView!
    
    private var sidePanelVisible        : Bool     = false
    private var transitionInProgress    : Bool     = false
    private var landscapeOrientation    : Bool {
        return screenSize.width > screenSize.height
    }
    
    private var leftSwipeRecognizer     : UISwipeGestureRecognizer!
    private var rightSwipeGesture       : UISwipeGestureRecognizer!
    private var panRecognizer           : UIPanGestureRecognizer!
    private var tapRecognizer           : UITapGestureRecognizer!
    
    private var canDisplaySideController : Bool{
        get {
            return sideViewController != nil
        }
    }
    
    // MARK:- View lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        /*
        Because custom segue attributes cannot be edited in the Interface Builder,
        the two initial segues from this controller need to have their ids set as
        "CenterContainmentSegue" and "SideContainmentSegue".
        
        After that, the segues from this controller do not require an id anymore, unless you want
        to change the side controller.
        */
        
        self.configure()
        
        self.performSegueWithIdentifier(CenterSegue, sender: nil)
        self.performSegueWithIdentifier(SideSegue, sender: nil)
    }
    
    // MARK:- Orientation changes -
    
    // pre iOS 8
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        
        if toInterfaceOrientation == .Portrait || toInterfaceOrientation == .PortraitUpsideDown {
            screenSize = UIScreen.mainScreen().bounds.size
        } else {
            screenSize = CGSizeMake(screenSize.height, screenSize.width)
        }
        
        UIView.animateWithDuration(duration, animations: { () -> Void in
            // reposition navigation bar
            self.navigationBar.frame = CGRectMake(0, 0, self.screenSize.width, self.StatusBarHeight)
            // reposition center panel
            self.centerPanel.frame = self.centerPanelFrame()
            // reposition side panel
            self.sidePanel.frame = self.sidePanelFrame()
            
            // hide or show the view under the status bar
            if self.sidePanelVisible {
                self.statusBarView.alpha = self.landscapeOrientation ? 0 : 1
            }
            
            // reposition the center shadow view
            if let shadow = self.centerShadowView {
                shadow.frame = self.centerPanelFrame()
            }
            
            self.view.layoutIfNeeded()
        })

    }
    
    //  iOS 8 and later
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        self.screenSize = size
        
        coordinator.animateAlongsideTransition({ _ in
            // reposition navigation bar
            self.navigationBar.frame = CGRectMake(0, 0, size.width, self.StatusBarHeight)
            // reposition center panel
            self.centerPanel.frame = self.centerPanelFrame()
            // reposition side panel
            self.sidePanel.frame = self.sidePanelFrame()
            
            // hide or show the view under the status bar
            if self.sidePanelVisible {
                self.statusBarView.alpha = self.landscapeOrientation ? 0 : 1
            }
            
            // reposition the center shadow view
            if let shadow = self.centerShadowView {
                shadow.frame = self.centerPanelFrame()
            }
            
            self.view.layoutIfNeeded()
            
            }, completion: nil)
    }
    
    // MARK: - Configurations -
    
    private func configure(){
        
        presentationStyle = SideMenuController.presentationStyle
        animationStyle = SideMenuController.animationStyle
        percentage = SideMenuController.sidePercentage
        
        centerPanel = UIView(frame: CGRectMake(0, 0, screenSize.width, screenSize.height))
        self.view.addSubview(centerPanel)
        
        navigationBar = UINavigationBar(frame: CGRectMake(0, 0, screenSize.width, StatusBarHeight))
        self.centerPanel.addSubview(navigationBar)
        
        statusBarView = UIView(frame: CGRectMake(0, 0, screenSize.width, StatusBarHeight))
        self.view.addSubview(statusBarView)
        statusBarView.backgroundColor = UIApplication.sharedApplication().statusBarStyle == UIStatusBarStyle.LightContent ? UIColor.blackColor() : UIColor.whiteColor()
        statusBarView.alpha = 0
        
        sidePanel = UIView(frame: self.sidePanelFrame())
        self.view.addSubview(sidePanel)
        sidePanel.clipsToBounds = true
        
        tapRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        tapRecognizer.delegate = self
        
        if presentationStyle == .UnderCenterPanelLeft || presentationStyle == .UnderCenterPanelRight {
            
            panRecognizer = UIPanGestureRecognizer(target: self, action: "handleCenterPanelPan:")
            panRecognizer.delegate = self
            centerPanel.addGestureRecognizer(panRecognizer)
            
            self.view.sendSubviewToBack(sidePanel)
            self.centerPanel.addGestureRecognizer(tapRecognizer)
            
        } else {
            
            centerShadowView = UIView(frame: UIScreen.mainScreen().bounds)
            centerShadowView.backgroundColor = UIColor(hue:0, saturation:0, brightness:0.02, alpha:0.8)
            
            panRecognizer = UIPanGestureRecognizer(target: self, action: "handleSidePanelPan:")
            panRecognizer.delegate = self
            self.sidePanel.addGestureRecognizer(panRecognizer)
            self.view.bringSubviewToFront(sidePanel)
            
            leftSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: "handleLeftSwipe:")
            leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirection.Left
            
            rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: "handleRightSwipe:")
            rightSwipeGesture.direction = UISwipeGestureRecognizerDirection.Right
            
            self.centerShadowView.addGestureRecognizer(tapRecognizer)
            
            if presentationStyle == .AboveCenterPanelLeft {
                self.centerPanel.addGestureRecognizer(rightSwipeGesture)
                self.centerShadowView.addGestureRecognizer(leftSwipeRecognizer)
            }else{
                self.centerPanel.addGestureRecognizer(leftSwipeRecognizer)
                self.centerShadowView.addGestureRecognizer(rightSwipeGesture)
            }
        }
        
        self.view.bringSubviewToFront(self.statusBarView)
    }
    
    // MARK:- Containment -
    
    func addNewController(controller : UIViewController, forSegueType type:ContainmentSegue.ContainmentSegueType){
        
        if type == .Center{
            
            if let navController = controller as? UINavigationController{
                self.addCenterController(navController)
            } else {
                fatalError("The center view controller must be a navigation controller!")
            }
        }else{
            self.addSideController(controller)
        }
    }
    
    private func addSideController(controller : UIViewController){
        if (sideViewController == nil) {
            sideViewController = controller
            
            sideViewController.view.frame = self.sidePanel.bounds
            
            self.sidePanel.addSubview(sideViewController.view)
            
            self.addChildViewController(sideViewController)
            sideViewController.didMoveToParentViewController(self)
            
            self.sidePanel.hidden = true
        }
    }
    
    private func addCenterController(controller : UINavigationController){
        
        self.prepareCenterControllerForContainment(controller)
        centerPanel.addSubview(controller.view)
        
        if (centerViewController == nil) {
            centerViewController = controller
            self.addChildViewController(centerViewController)
            centerViewController.didMoveToParentViewController(self)
        }else{
            
            centerViewController.willMoveToParentViewController(nil)
            self.addChildViewController(controller)
            
            let completion : () -> () = {
                self.centerViewController.view.removeFromSuperview()
                self.centerViewController.removeFromParentViewController()
                controller.didMoveToParentViewController(self)
                self.centerViewController = controller
            }
            
            var transitionMethod = self.triggerMaskAnimationForNewCenterController
            
            if self.animationStyle == .FadeAnimation {
                transitionMethod = self.triggerFadeAnimationForNewCenterController
            }
            
            transitionMethod(controller, completion: completion)
            
            if (self.sidePanelVisible){
                animateToReveal(false)
            }
        }
    }
    
    private func triggerFadeAnimationForNewCenterController(controller : UINavigationController, completion: (()->())) {
        
        CATransaction.begin()
        CATransaction.setCompletionBlock (completion)
        
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.duration = 0.7
        fadeAnimation.fromValue = 0
        fadeAnimation.toValue = 1
        
        fadeAnimation.fillMode = kCAFillModeBoth
        fadeAnimation.removedOnCompletion = true
        
        controller.view.layer.addAnimation(fadeAnimation, forKey: "fadeInAnimation")
        
        CATransaction.commit()
    }
    
    private func triggerMaskAnimationForNewCenterController(controller : UINavigationController, completion: (()->())) {
       
        
        
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        
        let dim = max(screenSize.width, screenSize.height)
        let circleDiameter : CGFloat = 50.0
        let circleFrame = CGRectMake((screenSize.width - circleDiameter) / 2, (screenSize.height - circleDiameter) / 2, circleDiameter, circleDiameter)
        let circleCenter = CGPointMake(circleFrame.origin.x + circleDiameter / 2, circleFrame.origin.y + circleDiameter / 2)
        
        let circleMaskPathInitial = UIBezierPath(ovalInRect: circleFrame)
        let extremePoint = CGPoint(x: circleCenter.x - dim, y: circleCenter.y - dim)
        let radius = sqrt((extremePoint.x * extremePoint.x) + (extremePoint.y * extremePoint.y))
        let circleMaskPathFinal = UIBezierPath(ovalInRect: CGRectInset(circleFrame, -radius, -radius))
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = circleMaskPathFinal.CGPath
        controller.view.layer.mask = maskLayer
        
        let maskLayerAnimation = CABasicAnimation(keyPath: "path")
        maskLayerAnimation.fromValue = circleMaskPathInitial.CGPath
        maskLayerAnimation.toValue = circleMaskPathFinal.CGPath
        maskLayerAnimation.duration = 0.75
        maskLayer.addAnimation(maskLayerAnimation, forKey: "path")
        
        CATransaction.commit()
    }
    
    private func prepareCenterControllerForContainment (controller : UINavigationController){
        addMenuButtonToController(controller)
        
        var frame = CGRectMake(0, StatusBarHeight, CGRectGetWidth(self.centerPanel.frame), CGRectGetHeight(self.centerPanel.frame) - StatusBarHeight)
        
        controller.view.frame = frame
    }
    
    
    private func addMenuButtonToController (controller : UINavigationController) {
        
        if controller.viewControllers.count == 0 {
            return
        }
        
        var shouldPlaceOnLeftSide = presentationStyle == .UnderCenterPanelLeft || presentationStyle == .AboveCenterPanelLeft
        
        var button = UIButton(frame: CGRectMake(0, 0, 40, 40))
        
        if SideMenuController.menuButtonImage != nil {
            button.setImage(SideMenuController.menuButtonImage, forState: UIControlState.Normal)
        }else{
            button.backgroundColor = UIColor.purpleColor()
        }
        
        button.addTarget(self, action: "toggleSidePanel", forControlEvents: UIControlEvents.TouchUpInside)
        
        var item:UIBarButtonItem = UIBarButtonItem()
        item.customView = button
        
        var spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        spacer.width = -10
        
        if shouldPlaceOnLeftSide {
            controller.childViewControllers[0].navigationItem.leftBarButtonItems = [spacer, item]
        }else{
            controller.childViewControllers[0].navigationItem.rightBarButtonItems = [spacer, item]
        }
    }
    
    private func prepareSidePanelForDisplay(display: Bool){
        self.sidePanel.hidden = !display
        if presentationStyle == .AboveCenterPanelLeft || presentationStyle == .AboveCenterPanelRight {
            if display {
                if (self.centerShadowView.superview == nil){
                    self.centerShadowView.alpha = 0
                    self.view.insertSubview(self.centerShadowView, belowSubview: self.sidePanel)
                }
            }else{
                self.centerShadowView.removeFromSuperview()
            }
        }else{
            showShadowForCenterPanel(true)
        }
    }
    
    func toggleSidePanel () {
        
        if !transitionInProgress {
            if !sidePanelVisible {
                prepareSidePanelForDisplay(true)
            }
            
            self.animateToReveal(!self.sidePanelVisible)
        }
    }
    
    private func animateToReveal(reveal : Bool){
        
        transitionInProgress = true
        
        self.sidePanelVisible = reveal
        
        if (reveal) {
            
            if presentationStyle == .AboveCenterPanelLeft || presentationStyle == .AboveCenterPanelRight {
                self.setAboveSidePanelHidden(false, completion: { () -> Void in
                    self.transitionInProgress = false
                    self.centerViewController.view.userInteractionEnabled = false
                })
            }else{
                
                self.setUnderSidePanelHidden(false, completion: { () -> () in
                    self.transitionInProgress = false
                    self.centerViewController.view.userInteractionEnabled = false
                })
            }
        } else {
            if presentationStyle == .AboveCenterPanelLeft || presentationStyle == .AboveCenterPanelRight {
                self.setAboveSidePanelHidden(true, completion: { () -> Void in
                    self.prepareSidePanelForDisplay(false)
                    self.transitionInProgress = false
                    self.centerViewController.view.userInteractionEnabled = true
                })
            }else{
                
                self.setUnderSidePanelHidden(true, completion: { () -> () in
                    self.prepareSidePanelForDisplay(false)
                    self.transitionInProgress = false
                    self.centerViewController.view.userInteractionEnabled = true
                })
            }
            
        }
    }
    
    func handleTap(gesture : UITapGestureRecognizer) {
        self.animateToReveal(false)
    }
    
    // MARK:- .UnderCenterPanelLeft & Right -
    
    private func showShadowForCenterPanel(shouldShowShadow: Bool) {
        if (shouldShowShadow) {
            centerPanel.layer.shadowOpacity = 0.8
        } else {
            centerPanel.layer.shadowOpacity = 0.0
        }
    }
    
    private func setUnderSidePanelHidden (hidden : Bool, completion : (() -> ())?) {
        var centerPanelFrame = self.centerPanel.frame
        if !hidden {
            if presentationStyle == .UnderCenterPanelLeft {
                centerPanelFrame.origin.x = CGRectGetMaxX(self.sidePanel.frame)
            }else{
                centerPanelFrame.origin.x = CGRectGetMinX(self.sidePanel.frame) - CGRectGetWidth(self.centerPanel.frame)
            }
        } else {
            centerPanelFrame.origin = CGPointZero
        }
        
        var duration = hidden ? hideAnimationDuration : revealAnimationDuration
        
        if abs(flickVelocity) > 0 {
            let newDuration = NSTimeInterval (self.sidePanel.frame.size.width / abs(flickVelocity))
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
        
        if !self.canDisplaySideController {
            return
        }
        
        self.flickVelocity = recognizer.velocityInView(recognizer.view).x
        let leftToRight = self.flickVelocity > 0
        
        switch(recognizer.state) {
        case .Began:
            if (!sidePanelVisible) {
                sidePanelVisible = true
                prepareSidePanelForDisplay(true)
                showShadowForCenterPanel(true)
            }
        case .Changed:
            
            var translation = recognizer.translationInView(view).x
            
            // origin.x or origin.x + width
            var xPoint : CGFloat = self.centerPanel.center.x + translation + ((presentationStyle == .UnderCenterPanelLeft) ? -1  : 1 ) * CGRectGetWidth(self.centerPanel.frame) / 2
            
            
            if xPoint < CGRectGetMinX(self.sidePanel.frame) || xPoint > CGRectGetMaxX(self.sidePanel.frame){
                return
            }
            
            if !landscapeOrientation {
                if presentationStyle == .UnderCenterPanelLeft {
                    self.statusBarView.alpha = xPoint / CGRectGetWidth(self.sidePanel.frame)
                }else{
                    self.statusBarView.alpha =  1 - (xPoint - CGRectGetMinX(self.sidePanel.frame)) / CGRectGetWidth(self.sidePanel.frame)
                }
            }
            centerPanel.center.x = self.centerPanel.center.x + translation
            recognizer.setTranslation(CGPointZero, inView: view)
        default:
            if (sidePanelVisible) {
                
                var shouldOpen = true
                
                if presentationStyle == .UnderCenterPanelLeft {
                    if leftToRight {
                        // opening
                        shouldOpen = CGRectGetMinX(self.centerPanel.frame) > CGRectGetWidth(self.sidePanel.frame) * 0.2
                    } else{
                        // closing
                        shouldOpen = CGRectGetMinX(self.centerPanel.frame) > CGRectGetWidth(self.sidePanel.frame) * 0.8
                    }
                }else{
                    if leftToRight {
                        //closing
                        shouldOpen = CGRectGetMaxX(self.centerPanel.frame) < CGRectGetMinX(self.sidePanel.frame) + 0.2 * CGRectGetWidth(self.sidePanel.frame)
                    }else{
                        // opening
                        shouldOpen = CGRectGetMaxX(self.centerPanel.frame) < CGRectGetMinX(self.sidePanel.frame) + 0.8 * CGRectGetWidth(self.sidePanel.frame)
                    }
                }
                
                
                animateToReveal(shouldOpen)
            }
        }
    }
    
    // MARK:- .AboveCenterPanelLeft & Right -
    
    func handleSidePanelPan(recognizer : UIPanGestureRecognizer){
        
        if !self.canDisplaySideController {
            return
        }
        
        self.flickVelocity = recognizer.velocityInView(recognizer.view).x
        
        let leftToRight = self.flickVelocity > 0
        let sidePanelWidth = CGRectGetWidth(self.sidePanel.frame)
        
        switch recognizer.state {
        case .Began:
            
            self.prepareSidePanelForDisplay(true)
            
            break
            
        case .Changed:
            
            var translation = recognizer.translationInView(view).x
            var xPoint : CGFloat = self.sidePanel.center.x + translation + (presentationStyle == .AboveCenterPanelLeft ? 1 : -1) * sidePanelWidth / 2
            var alpha : CGFloat
            
            if presentationStyle == .AboveCenterPanelLeft {
                if xPoint <= 0 || xPoint > CGRectGetWidth(self.sidePanel.frame) {
                    return
                }
                alpha = xPoint / CGRectGetWidth(self.sidePanel.frame)
            }else{
                if xPoint <= screenSize.width - sidePanelWidth || xPoint >= screenSize.width
                {
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
            
            var shouldClose = presentationStyle == .AboveCenterPanelLeft ? !leftToRight && CGRectGetMaxX(self.sidePanel.frame) < sidePanelWidth : leftToRight && CGRectGetMinX(self.sidePanel.frame) >  (screenSize.width - sidePanelWidth)
            
            self.animateToReveal(!shouldClose)
            
        }
    }
    
    private func setAboveSidePanelHidden(hidden: Bool, completion : ((Void) -> Void)?){
        
        var leftSidePositioned = presentationStyle == .AboveCenterPanelLeft
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
        
        var duration = hidden ? hideAnimationDuration : revealAnimationDuration
        
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
        if presentationStyle == .AboveCenterPanelLeft {
            if self.sidePanelVisible{
                self.animateToReveal(false)
            }
        }else{
            if !self.sidePanelVisible {
                self.prepareSidePanelForDisplay(true)
                self.animateToReveal(true)
            }
        }
    }
    
    func handleRightSwipe(recognizer : UIGestureRecognizer){
        if presentationStyle == .AboveCenterPanelLeft {
            if !self.sidePanelVisible {
                self.prepareSidePanelForDisplay(true)
                self.animateToReveal(true)
            }
        }else{
            if sidePanelVisible {
                self.animateToReveal(false)
            }
        }
    }
    
    // MARK:- UIGestureRecognizerDelegate -
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if gestureRecognizer == self.panRecognizer {
            return SideMenuController.panningEnabled
        }else if gestureRecognizer == self.tapRecognizer{
            return self.sidePanelVisible
        } else {
            return true
        }
    }
    
    // MARK:- Helper methods -
    
    private func centerPanelFrame() -> CGRect {
        
        if (presentationStyle == .UnderCenterPanelLeft || presentationStyle == .UnderCenterPanelRight) && sidePanelVisible {
            
            let sidePanelWidth = percentage * min(screenSize.width, screenSize.height)
            
            return CGRectMake(presentationStyle == .UnderCenterPanelLeft ? sidePanelWidth : -sidePanelWidth, 0, screenSize.width, screenSize.height)
        } else {
            return CGRectMake(0, 0, screenSize.width, screenSize.height)
        }
    }
    
    private func sidePanelFrame() -> CGRect {
        var sidePanelFrame : CGRect
        
        let panelWidth = percentage * min(screenSize.width, screenSize.height)
        
        if presentationStyle == .UnderCenterPanelLeft || presentationStyle == .UnderCenterPanelRight {
            sidePanelFrame = CGRectMake(presentationStyle == .UnderCenterPanelLeft ? 0 :
                screenSize.width - panelWidth, 0, panelWidth, screenSize.height)
        } else {
            if sidePanelVisible {

                sidePanelFrame = CGRectMake(presentationStyle == .AboveCenterPanelLeft ? 0 : screenSize.width - panelWidth, 0, panelWidth, screenSize.height)
            } else {
                sidePanelFrame = CGRectMake(presentationStyle == .AboveCenterPanelLeft ? -panelWidth : screenSize.width, 0, panelWidth, screenSize.height)
            }
        }
        
        return sidePanelFrame
    }
}

// MARK:- Custom segue  -
@objc(ContainmentSegue)
class ContainmentSegue : UIStoryboardSegue{
    
    enum ContainmentSegueType{
        case Center
        case Side
    }
    
    private var type: ContainmentSegueType {
        get {
            if let id = self.identifier {
                if id == SideSegue {
                    return .Side
                }else{
                    return .Center
                }
            }else{
                return .Center
            }
        }
    }
    
    override func perform() {
        
        if let sideController = self.sourceViewController as? SideMenuController {
            sideController.addNewController(self.destinationViewController as! UIViewController, forSegueType: self.type)
        } else {
            fatalError("This type of segue must only be used from a MenuViewController")
        }
    }
}

// MARK:-  Extensions -

extension UIView {
    class func panelAnimation(duration : NSTimeInterval, animations : (()->()), completion : (()->())?) {
        UIView.animateWithDuration(duration, animations: animations) { _ -> Void in
            if completion != nil {
                completion!()
            }
        }
    }
}

extension UIViewController {
    func sideMenuController() -> SideMenuController? {
        return sideMenuControllerForViewController(self)
    }
    
    private func sideMenuControllerForViewController(controller : UIViewController) -> SideMenuController?
    {
        if let sideController = controller as? SideMenuController {
            return sideController
        }
        
        if controller.parentViewController != nil {
            return sideMenuControllerForViewController(controller.parentViewController!)
        }else{
            return nil
        }
    }
}

