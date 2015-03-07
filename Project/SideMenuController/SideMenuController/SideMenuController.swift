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

let ScreenSize = UIScreen.mainScreen().bounds.size
let StatusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height

enum SideMenuControllerPresentationStyle {
    case BehindCenterController
    case AboveCenterController
}

enum ContainmentSegueType{
    case Center
    case Side
}

class SideMenuController: UIViewController, UIGestureRecognizerDelegate {
    
    
    // MARK:- Properties -
    
    private struct PrefsStruct {
        static var percentage: CGFloat = 0.7
        static var sideStyle : SideMenuControllerPresentationStyle = .BehindCenterController
        static var shadow: Bool = true
        static var panning : Bool = true
        static var menuButtonImage : UIImage?
        
    }
    
    class var menuButtonImage : UIImage? {
        get { return PrefsStruct.menuButtonImage}
        set {PrefsStruct.menuButtonImage = newValue}
    }
    
    class var panningEnabled : Bool {
        get { return PrefsStruct.panning}
        set {PrefsStruct.panning = newValue}
    }
    
    class var sideControllerPresentationStyle : SideMenuControllerPresentationStyle {
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
    
    var navigationBar : UINavigationBar!
    
    private var centerViewController : UIViewController!
    private var sideViewController : UIViewController!
    private var statusBarView : UIView!
    private var centerPanel : UIView!
    
    private var sideControllerVisible : Bool = false
    private var transitionInPorgress : Bool = false
    
    private var leftSwipeRecognizer : UISwipeGestureRecognizer?
    private var rightSwipeGesture   : UISwipeGestureRecognizer?
    private var panRecognizer : UIPanGestureRecognizer?
    
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
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return UIInterfaceOrientation.Portrait.rawValue
    }
    
    // MARK: - Configurations -
    
    private func configure(){
        
        centerPanel = UIView(frame: CGRectMake(0, 0, ScreenSize.width, ScreenSize.height))
        self.view.addSubview(centerPanel)
        
        navigationBar = UINavigationBar(frame: CGRectMake(0, 0, ScreenSize.width, StatusBarHeight))
        self.centerPanel.addSubview(navigationBar)
        
        statusBarView = UIView(frame: CGRectMake(0, 0, ScreenSize.width, 20))
        self.view.insertSubview(statusBarView, aboveSubview: centerPanel)
        statusBarView.backgroundColor = UIColor.whiteColor()
        statusBarView.alpha = 0
        
        if SideMenuController.sideControllerPresentationStyle == .BehindCenterController && SideMenuController.panningEnabled {
            panRecognizer = UIPanGestureRecognizer(target: self, action: "handlePan:")
            panRecognizer?.delegate = self
            centerPanel.addGestureRecognizer(panRecognizer!)
        }
    }
    
    private func showShadowForCenterPanel(shouldShowShadow: Bool) {
        if (shouldShowShadow) {
            centerPanel.layer.shadowOpacity = 0.8
        } else {
            centerPanel.layer.shadowOpacity = 0.0
        }
    }
    
    // MARK:- Containment -
    
    func addNewController(controller : UIViewController, forSegueType type:ContainmentSegueType){
        
        if self.transitionInPorgress{
            return
        }
        
        if type == .Center{
            self.addCenterController(controller)
        }else{
            self.addSideController(controller)
        }
    }
    
    private func addSideController(controller : UIViewController){
        if (sideViewController == nil) {
            sideViewController = controller
            
            
            var frame = CGRectMake(0, 0.0, SideMenuController.sidePercentage * ScreenSize.width, ScreenSize.height)
            
            sideViewController.view.frame = frame
            sideViewController.view.hidden = true
            
            
            self.view.addSubview(sideViewController.view)
            self.view.sendSubviewToBack(sideViewController.view)
            
            self.addChildViewController(sideViewController)
            sideViewController?.didMoveToParentViewController(self)
        }
    }
    
    private func addCenterController(controller : UIViewController){
        
        self.prepareCenterControllerForContainment(controller)
        centerPanel.addSubview(controller.view)
        
        if (centerViewController == nil) {
            centerViewController = controller
            self.addChildViewController(centerViewController)
            centerViewController?.didMoveToParentViewController(self)
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
            var circleFrame = CGRectMake((ScreenSize.width - circleDiameter) / 2, (ScreenSize.height - circleDiameter) / 2, circleDiameter, circleDiameter)
            var circleCenter = CGPointMake(circleFrame.origin.x + circleDiameter / 2, circleFrame.origin.y + circleDiameter / 2)
            
            var circleMaskPathInitial = UIBezierPath(ovalInRect: circleFrame)
            var extremePoint = CGPoint(x: circleCenter.x, y: circleCenter.y - ScreenSize.height)
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
            
            
            if (self.sideControllerVisible){
                self.animateToOpen(false)
            }
        }
    }
    
    private func prepareCenterControllerForContainment (controller : UIViewController){
        addMenuButtonToController(controller)

        var frame = CGRectMake(0, StatusBarHeight, CGRectGetWidth(self.centerPanel.frame), CGRectGetHeight(self.centerPanel.frame) - StatusBarHeight)
        
        controller.view.frame = frame
    }
    
    
    private func addMenuButtonToController (controller : UIViewController) {
        
        if controller.childViewControllers.count == 0 {
            return
        }
        
        var button = UIButton(frame: CGRectMake(0, 0, 45, 45))
        
        if SideMenuController.menuButtonImage != nil {
            button.setImage(SideMenuController.menuButtonImage, forState: UIControlState.Normal)
        }else{
            button.backgroundColor = UIColor.purpleColor()
        }
        
        button.addTarget(self, action: "toggleSideController", forControlEvents: UIControlEvents.TouchUpInside)
        
        var leftItem:UIBarButtonItem = UIBarButtonItem()
        leftItem.customView = button
        
        var negativeSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        negativeSpacer.width = -17
        
        controller.childViewControllers[0].navigationItem.leftBarButtonItems = [negativeSpacer, leftItem]
    }
    
    private func prepareSideControllerForDisplay(display: Bool){
        self.sideViewController?.view.hidden = !display
    }
    
    // MARK:- Position Handling -
    
    func toggleSideController () {
        animateToOpen(!sideControllerVisible)
    }
    
    private func revealSideController (completion: ((success:Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.centerPanel.frame.origin.x = UIScreen.mainScreen().bounds.size.width * SideMenuController.sidePercentage
            self.statusBarView.alpha = 1
            }, completion: completion)
    }
    
    private func hideSideController (completion: ((success: Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.centerPanel.frame.origin.x = 0
            self.statusBarView.alpha = 0
            }, completion: completion)
    }
    
    
    private func animateToOpen(open : Bool){
        
        transitionInPorgress = true
        
        if (open) {
            showShadowForCenterPanel(true)
            prepareSideControllerForDisplay(open)
            self.revealSideController(completion: { (success) -> Void in
                self.sideControllerVisible = true
                self.transitionInPorgress = false
            })
        } else {
            self.hideSideController(completion: { (success) -> Void in
                self.showShadowForCenterPanel(false)
                self.prepareSideControllerForDisplay(false)
                self.sideControllerVisible = false
                self.transitionInPorgress = false
            })
        }
    }
    
    func handlePan(recognizer : UIPanGestureRecognizer){
        
        if !self.canDisplaySideController {
            return
        }
        
        let leftToRight = (recognizer.velocityInView(view).x > 0)
        
        switch(recognizer.state) {
        case .Began:
            if (!sideControllerVisible) {
                sideControllerVisible = true
                prepareSideControllerForDisplay(true)
                showShadowForCenterPanel(true)
            }
        case .Changed:
            
            var newOrigin = recognizer.view!.center.x + recognizer.translationInView(view).x - ScreenSize.width / 2
            
            if  newOrigin > ScreenSize.width * SideMenuController.sidePercentage ||
                newOrigin < 0 {
                    return
            }
            
            self.statusBarView.alpha = newOrigin / (ScreenSize.width * SideMenuController.sidePercentage)
            
            recognizer.view!.center.x = recognizer.view!.center.x + recognizer.translationInView(view).x
            recognizer.setTranslation(CGPointZero, inView: view)
            
        case .Ended, .Cancelled, .Failed :
            if (sideControllerVisible) {
                var shouldOpen = true
                
                if leftToRight {
                    shouldOpen = recognizer.view!.frame.origin.x  > centerPanel.frame.size.width / 3
                }else{
                    shouldOpen = recognizer.view!.frame.origin.x > 2 * centerPanel.bounds.size.width / 3
                }
                
                animateToOpen(shouldOpen)
            }
        default:
            break
        }
    }
    
    
    // MARK:- UIGestureRecognizerDelegate -
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.panRecognizer {
            return SideMenuController.panningEnabled
        }else{
            return true
        }
    }
}

// MARK:-  -
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
        
        if (!self.sourceViewController.isKindOfClass(SideMenuController.classForCoder())){
            fatalError("This type of segue must only be used from a MenuViewController")
        }
        
        (self.sourceViewController as SideMenuController).addNewController(self.destinationViewController as UIViewController, forSegueType: self.type)
    }
}

// MARK:-  -

extension UIViewController {
    func sideMenuController() -> SideMenuController? {
        return sideMenuControllerForViewController(self)
    }
    
    private func sideMenuControllerForViewController(controller : UIViewController) -> SideMenuController?
    {
        if (controller.isKindOfClass(SideMenuController.classForCoder())){
            return controller as? SideMenuController
        }
        
        if controller.parentViewController != nil {
            return sideMenuControllerForViewController(controller.parentViewController!)
        }else{
            return nil
        }
    }
}

