//
//  SideMenuController.swift
//  SideMenuController
//
//  Created by Teodor Patras on 07.03.15.
//  Copyright (c) 2015 Teodor Patras. All rights reserved.
//

import UIKit

let CenterSegue = "CenterContainment"
let SideSegue = "SideContainment"

enum SideMenuControllerPresentationStyle {
    case UnderCenterPanelLeft
    case UnderCenterPanelRight
    case AboveCenterPanelLeft
    case AboveCenterPanelRight
}

enum ContainmentSegueType{
    case Center
    case Side
}

class SideMenuController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK:- Constants -
    
    let revealAnimationDuration : NSTimeInterval = 0.3
    let hideAnimationDuration   : NSTimeInterval = 0.2
    
    var screenSize = UIScreen.mainScreen().bounds.size
    let StatusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
    
    // MARK: - Customizable properties -
    
    private struct PrefsStruct {
        static var percentage: CGFloat = 0.7
        static var sideStyle : SideMenuControllerPresentationStyle = .UnderCenterPanelLeft
        static var shadow: Bool = true
        static var panning : Bool = true
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
    private var style                   : SideMenuControllerPresentationStyle!
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
        
        
        // reposition navigation bar
        self.navigationBar.frame = CGRectMake(0, 0, screenSize.width, self.StatusBarHeight)
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
    }
    
    // iOS 8 and later
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        self.screenSize = size
        
        coordinator.animateAlongsideTransition({ _ -> Void in
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
            
            }, completion: nil)
    }
    
    // MARK: - Configurations -
    
    private func configure(){
        
        style = SideMenuController.presentationStyle
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
        
        if style == .UnderCenterPanelLeft || style == .UnderCenterPanelRight {
            
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
            
            if style == .AboveCenterPanelLeft {
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
    
    func addNewController(controller : UIViewController, forSegueType type:ContainmentSegueType){
        
        if type == .Center{
            self.addCenterController(controller)
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
    
    private func addCenterController(controller : UIViewController){
        
        self.prepareCenterControllerForContainment(controller)
        centerPanel.addSubview(controller.view)
        
        if (centerViewController == nil) {
            centerViewController = controller
            self.addChildViewController(centerViewController)
            centerViewController.didMoveToParentViewController(self)
        }else{
            
            centerViewController.willMoveToParentViewController(nil)
            self.addChildViewController(controller)
            
            CATransaction.begin()
            CATransaction.setCompletionBlock({ () -> Void in
                self.centerViewController.view.removeFromSuperview()
                self.centerViewController.removeFromParentViewController()
                controller.didMoveToParentViewController(self)
                self.centerViewController = controller
            })
            
            var circleDiameter : CGFloat = 50.0
            var circleFrame = CGRectMake((screenSize.width - circleDiameter) / 2, (screenSize.height - circleDiameter) / 2, circleDiameter, circleDiameter)
            var circleCenter = CGPointMake(circleFrame.origin.x + circleDiameter / 2, circleFrame.origin.y + circleDiameter / 2)
            
            var circleMaskPathInitial = UIBezierPath(ovalInRect: circleFrame)
            var extremePoint = CGPoint(x: circleCenter.x, y: circleCenter.y - screenSize.height)
            var radius = sqrt((extremePoint.x * extremePoint.x) + (extremePoint.y * extremePoint.y))
            var circleMaskPathFinal = UIBezierPath(ovalInRect: CGRectInset(circleFrame, -radius, -radius))
            
            var maskLayer = CAShapeLayer()
            maskLayer.path = circleMaskPathFinal.CGPath
            controller.view.layer.mask = maskLayer
            
            var maskLayerAnimation = CABasicAnimation(keyPath: "path")
            maskLayerAnimation.fromValue = circleMaskPathInitial.CGPath
            maskLayerAnimation.toValue = circleMaskPathFinal.CGPath
            maskLayerAnimation.duration = 0.5
            maskLayer.addAnimation(maskLayerAnimation, forKey: "path")
            
            CATransaction.commit()
            
            
            if (self.sidePanelVisible){
                animateToReveal(false)
            }
        }
    }
    
    private func prepareCenterControllerForContainment (controller : UIViewController){
        addMenuButtonToController(controller)
        
        var frame = CGRectMake(0, StatusBarHeight, CGRectGetWidth(self.centerPanel.frame), CGRectGetHeight(self.centerPanel.frame) - StatusBarHeight)
        
        controller.view.frame = frame
    }
    
    
    private func addMenuButtonToController (controller : UIViewController) {
        
        if !(controller is UINavigationController) || controller.childViewControllers.count == 0 {
            return
        }
        
        var shouldPlaceOnLeftSide = self.style == .UnderCenterPanelLeft || self.style == .AboveCenterPanelLeft
        
        var button = UIButton(frame: CGRectMake(0, 0, 40, 40))
        
        if SideMenuController.menuButtonImage != nil {
            button.setImage(SideMenuController.menuButtonImage, forState: UIControlState.Normal)
        }else{
            button.backgroundColor = UIColor.purpleColor()
        }
        
        button.addTarget(self, action: "toggleSideController", forControlEvents: UIControlEvents.TouchUpInside)
        
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
        if self.style == .AboveCenterPanelLeft || self.style == .AboveCenterPanelRight {
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
    
    func toggleSideController () {
        
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
            
            if self.style == .AboveCenterPanelLeft || self.style == .AboveCenterPanelRight {
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
            if self.style == .AboveCenterPanelLeft || self.style == .AboveCenterPanelRight {
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
            if self.style == .UnderCenterPanelLeft {
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
            var xPoint : CGFloat = self.centerPanel.center.x + translation + ((self.style == .UnderCenterPanelLeft) ? -1  : 1 ) * CGRectGetWidth(self.centerPanel.frame) / 2
            
            
            if xPoint < CGRectGetMinX(self.sidePanel.frame) || xPoint > CGRectGetMaxX(self.sidePanel.frame){
                return
            }
            
            if !landscapeOrientation {
                if style == .UnderCenterPanelLeft {
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
                
                if self.style == .UnderCenterPanelLeft {
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
            var xPoint : CGFloat = self.sidePanel.center.x + translation + (self.style == .AboveCenterPanelLeft ? 1 : -1) * sidePanelWidth / 2
            var alpha : CGFloat
            
            if self.style == .AboveCenterPanelLeft {
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
            
            var shouldClose = self.style == .AboveCenterPanelLeft ? !leftToRight && CGRectGetMaxX(self.sidePanel.frame) < sidePanelWidth : leftToRight && CGRectGetMinX(self.sidePanel.frame) >  (screenSize.width - sidePanelWidth)
            
            self.animateToReveal(!shouldClose)
            
        }
    }
    
    private func setAboveSidePanelHidden(hidden: Bool, completion : ((Void) -> Void)?){
        
        var leftSidePositioned = self.style == .AboveCenterPanelLeft
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
        if self.style == .AboveCenterPanelLeft {
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
        if self.style == .AboveCenterPanelLeft {
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
        
        if (style == .UnderCenterPanelLeft || style == .UnderCenterPanelRight) && sidePanelVisible {
            
            let sidePanelWidth = percentage * min(screenSize.width, screenSize.height)
            
            return CGRectMake(style == .UnderCenterPanelLeft ? sidePanelWidth : -sidePanelWidth, 0, screenSize.width, screenSize.height)
        } else {
            return CGRectMake(0, 0, screenSize.width, screenSize.height)
        }
    }
    
    private func sidePanelFrame() -> CGRect {
        var sidePanelFrame : CGRect
        
        let panelWidth = percentage * min(screenSize.width, screenSize.height)
        
        if style == .UnderCenterPanelLeft || style == .UnderCenterPanelRight {
            sidePanelFrame = CGRectMake(self.style == .UnderCenterPanelLeft ? 0 :
                screenSize.width - panelWidth, 0, panelWidth, screenSize.height)
        } else {
            if sidePanelVisible {

                sidePanelFrame = CGRectMake(self.style == .AboveCenterPanelLeft ? 0 : screenSize.width - panelWidth, 0, panelWidth, screenSize.height)
            } else {
                sidePanelFrame = CGRectMake(self.style == .AboveCenterPanelLeft ? -panelWidth : screenSize.width, 0, panelWidth, screenSize.height)
            }
        }
        
        return sidePanelFrame
    }
}

// MARK:- Custom segue  -
@objc(ContainmentSegue)
class ContainmentSegue : UIStoryboardSegue{
    
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
        
        if self.sourceViewController is SideMenuController
        {
            (self.sourceViewController as! SideMenuController).addNewController(self.destinationViewController as! UIViewController, forSegueType: self.type)
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
        if controller is SideMenuController {
            return (controller as! SideMenuController)
        }
        
        if controller.parentViewController != nil {
            return sideMenuControllerForViewController(controller.parentViewController!)
        }else{
            return nil
        }
    }
}

