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

// MARK: - Public methods -

public extension SideMenuController {
    
    /**
     Toggles the side pannel visible or not.
     */
    public func toggleSidePanel() {
        
        if !transitionInProgress {
            if !sidePanelVisible {
                prepareSidePanel(forDisplay: true)
            }
            
            animate(toReveal: !sidePanelVisible)
        }
    }
    
    /**
     Embeds a new side controller
     
     - parameter controller: controller to be embedded
     */
    public func embedSideController(controller: UIViewController) {
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
    public func embedCenterController(controller: UINavigationController) {
        
        prepareCenterControllerForContainment(controller)
        centerPanel.addSubview(controller.view)
        
        if centerViewController == nil {
            centerViewController = controller
            addChildViewController(centerViewController)
            centerViewController.didMoveToParentViewController(self)
        } else {
            centerViewController.willMoveToParentViewController(nil)
            addChildViewController(controller)
            
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
                animate(toReveal: false, statusUpdateAnimated: false)
            }
        }
    }
}

public class SideMenuController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK:- Custom types -
    
    public enum SidePanelPosition {
        case UnderCenterPanelLeft
        case UnderCenterPanelRight
        case OverCenterPanelLeft
        case OverCenterPanelRight
        
        var isPositionedUnder: Bool {
            return self == UnderCenterPanelLeft || self == UnderCenterPanelRight
        }
        
        var isPositionedLeft: Bool {
            return self == UnderCenterPanelLeft || self == OverCenterPanelLeft
        }
    }
    
    public enum StatusBarBehaviour {
        case SlideAnimation
        case FadeAnimation
        case HorizontalPan
        case ShowUnderlay
        
        var statusBarAnimation: UIStatusBarAnimation {
            switch self {
            case FadeAnimation:
                return .Fade
            case .SlideAnimation:
                return .Slide
            default:
                return .None
            }
        }
    }
    
    public struct Preferences {
        public struct Drawing {
            public var menuButtonImage: UIImage?
            public var sidePanelWidth: CGFloat = 300
            public var sidePanelPosition = SidePanelPosition.UnderCenterPanelLeft
            public var centerPanelOverlayColor = UIColor(hue:0.15, saturation:0.21, brightness:0.17, alpha:0.6)
            public var panningEnabled = true
            public var swipingEnabled = true
            public var drawSideShadow = true
        }
        
        public struct Animating {
            public var statusBarBehaviour = StatusBarBehaviour.SlideAnimation
            public var reavealDuration = 0.3
            public var hideDuration = 0.2
            public var transitionAnimator: TransitionAnimatable.Type? = FadeAnimator.self
        }
        
        public var drawing = Drawing()
        public var animating = Animating()
        
        public init() {}
    }
    
    // MARK: - Properties -
    
    // MARK: Public
    
    public static var preferences: Preferences = Preferences()
    private(set) public var sidePanelVisible = false
    
    // MARK: Private
    
    private lazy var _preferences: Preferences = {
        return self.dynamicType.preferences
    }()
    
    private var centerViewController: UIViewController!
    private var sideViewController: UIViewController!
    private var statusBarUnderlay: UIView!
    private var centerPanel: UIView!
    private var sidePanel: UIView!
    private var centerPanelOverlay: UIView!
    private var leftSwipeRecognizer: UISwipeGestureRecognizer!
    private var rightSwipeGesture: UISwipeGestureRecognizer!
    private var panRecognizer: UIPanGestureRecognizer!
    private var tapRecognizer: UITapGestureRecognizer!
    
    private var transitionInProgress = false
    private var flickVelocity: CGFloat = 0
    
    private lazy var screenSize: CGSize = {
        return UIScreen.mainScreen().bounds.size
    }()
    
    private lazy var sidePanelPosition: SidePanelPosition = {
        return self._preferences.drawing.sidePanelPosition
    }()
    
    // MARK: Internal
    
    
    // MARK: Computed
    
    private var statusBarHeight: CGFloat {
        return UIApplication.sharedApplication().statusBarFrame.size.height > 0 ? UIApplication.sharedApplication().statusBarFrame.size.height : 20
    }
    
    private var hidesStatusBar: Bool {
        return [.SlideAnimation, .FadeAnimation].contains(_preferences.animating.statusBarBehaviour)
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
    
    private var canDisplaySideController: Bool {
        return sideViewController != nil
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
    
    private var statusBarWindow: UIWindow? {
        return UIApplication.sharedApplication().valueForKey("statusBarWindow") as? UIWindow
    }
    
    // MARK:- View lifecycle -

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpViewHierarchy()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setUpViewHierarchy()
    }
    
    private func setUpViewHierarchy() {
        view = UIView(frame: UIScreen.mainScreen().bounds)
        configureViews()
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        screenSize = size
        
        coordinator.animateAlongsideTransition({ _ in
            // reposition center panel
            self.updateCenterPanel(withFrame: self.centerPanelFrame)
            // reposition side panel
            self.sidePanel.frame = self.sidePanelFrame
            
            // hide or show the view under the status bar
            self.setStatusUnderlay(alpha: self.sidePanelVisible ? 1 : 0)
            
            // reposition the center shadow view
            if let overlay = self.centerPanelOverlay {
                overlay.frame = self.centerPanelFrame
            }
            
            self.view.layoutIfNeeded()
            
        }, completion: nil)
    }
    
    // MARK: - Configurations -
    
    private func configureViews(){
        
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
    
    private func configureGestureRecognizers() {
    
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapRecognizer.delegate = self
        
        if sidePanelPosition.isPositionedUnder {
            panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleCenterPanelPan))
            panRecognizer.delegate = self
            centerPanel.addGestureRecognizer(panRecognizer)
            centerPanel.addGestureRecognizer(tapRecognizer)
        } else {

            panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSidePanelPan))
            panRecognizer.delegate = self
            sidePanel.addGestureRecognizer(panRecognizer)
            
            leftSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleLeftSwipe))
            leftSwipeRecognizer.delegate = self
            leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirection.Left
            
            rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipe))
            rightSwipeGesture.delegate = self
            rightSwipeGesture.direction = UISwipeGestureRecognizerDirection.Right
            
            centerPanelOverlay.addGestureRecognizer(tapRecognizer)
            
            if sidePanelPosition.isPositionedLeft {
                centerPanel.addGestureRecognizer(rightSwipeGesture)
                centerPanelOverlay.addGestureRecognizer(leftSwipeRecognizer)
            }else{
                centerPanel.addGestureRecognizer(leftSwipeRecognizer)
                centerPanelOverlay.addGestureRecognizer(rightSwipeGesture)
            }
        }
    }
    
    private func setStatusBar(hidden hidden: Bool, animated: Bool = true) {
        
        guard hidesStatusBar else {
            return
        }
        
        let setting = _preferences.animating.statusBarBehaviour
        
        let size = UIScreen.mainScreen().applicationFrame.size
        self.view.window?.frame = CGRectMake(0, 0, size.width, size.height)
        if animated {
            UIApplication.sharedApplication().setStatusBarHidden(hidden, withAnimation: setting.statusBarAnimation)
        } else {
            UIApplication.sharedApplication().statusBarHidden = hidden
        }
        
    }
    
    private func setStatusUnderlay(alpha alpha: CGFloat) {
        guard showsStatusUnderlay else {
            return
        }
        
        if let color = (centerViewController as? UINavigationController)?.navigationBar.barTintColor where statusBarUnderlay.backgroundColor != color {
            statusBarUnderlay.backgroundColor = color
        }
        
        statusBarUnderlay.alpha = alpha
    }

    func updateCenterPanel(withFrame frame: CGRect) {
        centerPanel.frame = frame
        if _preferences.animating.statusBarBehaviour == .HorizontalPan {
            statusBarWindow?.frame = frame
        }
    }
    
    // MARK:- Containment -

    private func prepareCenterControllerForContainment (controller: UINavigationController){
        addMenuButtonToController(controller)
        controller.view.frame = centerPanel.bounds
    }
    
    private func addMenuButtonToController(controller: UINavigationController) {
        
        guard let image = _preferences.drawing.menuButtonImage else {
            return
        }
        
        let button = UIButton(frame: CGRectMake(0, 0, 40, 40))
        button.setImage(image, forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(toggleSidePanel), forControlEvents: UIControlEvents.TouchUpInside)
        
        let item:UIBarButtonItem = UIBarButtonItem()
        item.customView = button
        
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        spacer.width = -10
        
        if sidePanelPosition.isPositionedLeft {
            controller.childViewControllers[0].navigationItem.leftBarButtonItems = [spacer, item]
        }else{
            controller.childViewControllers[0].navigationItem.rightBarButtonItems = [spacer, item]
        }
    }
    
    private func prepareSidePanel(forDisplay display: Bool){
        
        sidePanel.hidden = !display
        
        if !sidePanelPosition.isPositionedUnder {
            if display && centerPanelOverlay.superview == nil {
                centerPanelOverlay.alpha = 0
                view.insertSubview(self.centerPanelOverlay, belowSubview: self.sidePanel)
            }else if !display {
                centerPanelOverlay.removeFromSuperview()
            }
        } else {
            setSideShadow(hidden: display)
        }
    }
    
    private func animate(toReveal reveal: Bool, statusUpdateAnimated: Bool = true){
        
        transitionInProgress = true
        sidePanelVisible = reveal
        setStatusBar(hidden: reveal, animated: statusUpdateAnimated)
        
        let hide = sidePanelPosition.isPositionedUnder ? setUnderSidePanelHidden : setAboveSidePanelHidden
        hide(!reveal) { _ in
            if !reveal {
                self.prepareSidePanel(forDisplay: false)
            }
            self.transitionInProgress = false
            self.centerViewController.view.userInteractionEnabled = !reveal
        }
    }
    
    func handleTap() {
        animate(toReveal: false)
    }
    
    // MARK:- .UnderCenterPanelLeft & Right -
    
    private func setSideShadow(hidden hidden: Bool) {
        
        guard _preferences.drawing.drawSideShadow else {
            return
        }
        
        if hidden {
            centerPanel.layer.shadowOpacity = 0.0
        } else {
            centerPanel.layer.shadowOpacity = 0.8
        }
    }
    
    private func setUnderSidePanelHidden(hidden: Bool, completion: (() -> ())? = nil) {
        
        var centerPanelFrame = centerPanel.frame
        
        if !hidden {
            if sidePanelPosition.isPositionedLeft {
                centerPanelFrame.origin.x = CGRectGetMaxX(sidePanel.frame)
            }else{
                centerPanelFrame.origin.x = CGRectGetMinX(sidePanel.frame) - CGRectGetWidth(centerPanel.frame)
            }
        } else {
            centerPanelFrame.origin = CGPointZero
        }
        
        var duration = hidden ? _preferences.animating.hideDuration : _preferences.animating.reavealDuration
        
        if abs(flickVelocity) > 0 {
            let newDuration = NSTimeInterval(sidePanel.frame.size.width / abs(flickVelocity))
            flickVelocity = 0
            duration = min(newDuration, duration)
        }
        
        
        UIView.panelAnimation( duration, animations: { _ in
            self.updateCenterPanel(withFrame: centerPanelFrame)
            self.setStatusUnderlay(alpha: hidden ? 0 : 1)
        }) { _ in
            if hidden {
                self.setSideShadow(hidden: hidden)
            }
            completion?()
        }
    }
    
    func handleCenterPanelPan(recognizer: UIPanGestureRecognizer){
        
        guard canDisplaySideController else {
            return
        }
        
        self.flickVelocity = recognizer.velocityInView(recognizer.view).x
        let leftToRight = flickVelocity > 0
    
        switch(recognizer.state) {
        
        case .Began:
            if !sidePanelVisible {
                sidePanelVisible = true
                prepareSidePanel(forDisplay: true)
                setSideShadow(hidden: false)
            }
            
            setStatusBar(hidden: true)
            
        case .Changed:
            let translation = recognizer.translationInView(view).x
            let sidePanelFrame = sidePanel.frame
            
            // origin.x or origin.x + width
            let xPoint: CGFloat = centerPanel.center.x + translation +
                (sidePanelPosition.isPositionedLeft ? -1  : 1 ) * CGRectGetWidth(centerPanel.frame) / 2
            
            
            if xPoint < CGRectGetMinX(sidePanelFrame) || xPoint > CGRectGetMaxX(sidePanelFrame){
                return
            }
            
            var alpha: CGFloat
            
            if sidePanelPosition.isPositionedLeft {
                alpha = xPoint / CGRectGetWidth(sidePanelFrame)
            }else{
                alpha = 1 - (xPoint - CGRectGetMinX(sidePanelFrame)) / CGRectGetWidth(sidePanelFrame)
            }
            
            setStatusUnderlay(alpha: alpha)
            
            var frame = centerPanel.frame
            frame.origin.x += translation
            updateCenterPanel(withFrame: frame)
            recognizer.setTranslation(CGPointZero, inView: view)
            
        default:
            if sidePanelVisible {
                
                var reveal = true
                let centerFrame = centerPanel.frame
                let sideFrame = sidePanel.frame
                
                let shouldOpenPercentage = CGFloat(0.2)
                let shouldHidePercentage = CGFloat(0.8)
                
                if sidePanelPosition.isPositionedLeft {
                    if leftToRight {
                        // opening
                        reveal = CGRectGetMinX(centerFrame) > CGRectGetWidth(sideFrame) * shouldOpenPercentage
                    } else{
                        // closing
                        reveal = CGRectGetMinX(centerFrame) > CGRectGetWidth(sideFrame) * shouldHidePercentage
                    }
                }else{
                    if leftToRight {
                        //closing
                        reveal = CGRectGetMaxX(centerFrame) < CGRectGetMinX(sideFrame) + shouldOpenPercentage * CGRectGetWidth(sideFrame)
                    }else{
                        // opening
                        reveal = CGRectGetMaxX(centerFrame) < CGRectGetMinX(sideFrame) + shouldHidePercentage * CGRectGetWidth(sideFrame)
                    }
                }
                
                animate(toReveal: reveal)
            }
        }
    }
    
    // MARK:- .OverCenterPanelLeft & Right -
    
    func handleSidePanelPan(recognizer: UIPanGestureRecognizer){
        
        guard canDisplaySideController else {
            return
        }
        
        flickVelocity = recognizer.velocityInView(recognizer.view).x
        
        let leftToRight = flickVelocity > 0
        let sidePanelWidth = CGRectGetWidth(sidePanel.frame)
        
        switch recognizer.state {
        case .Began:
            
            prepareSidePanel(forDisplay: true)
            setStatusBar(hidden: true)
        
        case .Changed:
            
            let translation = recognizer.translationInView(view).x
            let xPoint: CGFloat = sidePanel.center.x + translation + (sidePanelPosition.isPositionedLeft ? 1 : -1) * sidePanelWidth / 2
            var alpha: CGFloat
            
            if sidePanelPosition.isPositionedLeft {
                if xPoint <= 0 || xPoint > CGRectGetWidth(sidePanel.frame) {
                    return
                }
                alpha = xPoint / CGRectGetWidth(sidePanel.frame)
            }else{
                if xPoint <= screenSize.width - sidePanelWidth || xPoint >= screenSize.width {
                    return
                }
                alpha = 1 - (xPoint - (screenSize.width - sidePanelWidth)) / sidePanelWidth
            }
            
            setStatusUnderlay(alpha: alpha)
            centerPanelOverlay.alpha = alpha
            sidePanel.center.x = sidePanel.center.x + translation
            recognizer.setTranslation(CGPointZero, inView: view)
            
        default:
            
            let shouldClose: Bool
            if sidePanelPosition.isPositionedLeft {
                shouldClose = !leftToRight && CGRectGetMaxX(sidePanel.frame) < sidePanelWidth
            } else {
               shouldClose = leftToRight && CGRectGetMinX(sidePanel.frame) >  (screenSize.width - sidePanelWidth)
            }
            
            animate(toReveal: !shouldClose)
        }
    }
    
    private func setAboveSidePanelHidden(hidden: Bool, completion: ((Void) -> Void)? = nil){
        
        var destinationFrame = sidePanel.frame
        
        if sidePanelPosition.isPositionedLeft {
            if hidden {
                destinationFrame.origin.x = -CGRectGetWidth(destinationFrame)
            } else {
                destinationFrame.origin.x = CGRectGetMinX(view.frame)
            }
        } else {
            if hidden {
                destinationFrame.origin.x = CGRectGetMaxX(view.frame)
            } else {
                destinationFrame.origin.x = CGRectGetMaxX(view.frame) - CGRectGetWidth(destinationFrame)
            }
        }
        
        var duration = hidden ? _preferences.animating.hideDuration : _preferences.animating.reavealDuration
        
        if abs(flickVelocity) > 0 {
            let newDuration = NSTimeInterval (destinationFrame.size.width / abs(flickVelocity))
            flickVelocity = 0
            
            if newDuration < duration {
                duration = newDuration
            }
        }
        
        UIView.panelAnimation(duration, animations: { () -> () in
            
            self.centerPanelOverlay.alpha = hidden ? 0 : 1
            self.setStatusUnderlay(alpha: hidden ? 0 : 1)
            
            self.sidePanel.frame = destinationFrame
            
            }, completion: completion)
    }
    
    func handleLeftSwipe(){
        handleHorizontalSwipe(toLeft: true)
    }
    
    func handleRightSwipe(){
        handleHorizontalSwipe(toLeft: false)
    }
    
    
    func handleHorizontalSwipe(toLeft left: Bool) {
        if (left && sidePanelPosition.isPositionedLeft) ||
            (!left && !sidePanelPosition.isPositionedLeft) {
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
        
        switch gestureRecognizer {
        case panRecognizer:
            return _preferences.drawing.panningEnabled
        case tapRecognizer:
            return sidePanelVisible
        default:
            if gestureRecognizer is UISwipeGestureRecognizer {
                return _preferences.drawing.swipingEnabled
            }
            return true
        }
    }
}