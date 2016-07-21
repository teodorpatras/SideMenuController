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
     */
    public func embed(centerViewController controller: UIViewController) {
        
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
                animate(toReveal: false, statusUpdateAnimated: false)
            }
        }
    }
}

public class SideMenuController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK:- Custom types -
    
    public enum SidePanelPosition {
        case underCenterPanelLeft
        case underCenterPanelRight
        case overCenterPanelLeft
        case overCenterPanelRight
        
        var isPositionedUnder: Bool {
            return self == underCenterPanelLeft || self == underCenterPanelRight
        }
        
        var isPositionedLeft: Bool {
            return self == underCenterPanelLeft || self == overCenterPanelLeft
        }
    }
    
    public enum StatusBarBehaviour {
        case slideAnimation
        case fadeAnimation
        case horizontalPan
        case showUnderlay
        
        var statusBarAnimation: UIStatusBarAnimation {
            switch self {
            case fadeAnimation:
                return .fade
            case .slideAnimation:
                return .slide
            default:
                return .none
            }
        }
    }
    
    public struct Preferences {
        public struct Drawing {
            public var menuButtonImage: UIImage?
            public var sidePanelPosition = SidePanelPosition.underCenterPanelLeft
            public var sidePanelWidth: CGFloat = 300
            public var centerPanelOverlayColor = UIColor(hue:0.15, saturation:0.21, brightness:0.17, alpha:0.6)
            public var centerPanelShadow = false
        }
        
        public struct Animating {
            public var statusBarBehaviour = StatusBarBehaviour.slideAnimation
            public var reavealDuration = 0.3
            public var hideDuration = 0.2
            public var transitionAnimator: TransitionAnimatable.Type? = FadeAnimator.self
        }
        
        public struct Interaction {
            public var panningEnabled = true
            public var swipingEnabled = true
            public var menuButtonAccessibilityIdentifier: String?
        }
        
        public var drawing = Drawing()
        public var animating = Animating()
        public var interaction = Interaction()
        
        public init() {}
    }
    
    // MARK: - Properties -
    
    // MARK: Public
    
    public weak var delegate: SideMenuControllerDelegate?
    public static var preferences: Preferences = Preferences()
    private(set) public var sidePanelVisible = false
    
    // MARK: Private
    
    private lazy var _preferences: Preferences = {
        return self.dynamicType.preferences
    }()
    
    private var centerViewController: UIViewController!
    private var centerNavController: UINavigationController? {
        return centerViewController as? UINavigationController
    }
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
        return UIScreen.main().bounds.size
    }()
    
    private lazy var sidePanelPosition: SidePanelPosition = {
        return self._preferences.drawing.sidePanelPosition
    }()
    
    // MARK: Internal
    
    
    // MARK: Computed
    
    private var statusBarHeight: CGFloat {
        return UIApplication.shared().statusBarFrame.size.height > 0 ? UIApplication.shared().statusBarFrame.size.height : 20
    }
    
    private var hidesStatusBar: Bool {
        return [.slideAnimation, .fadeAnimation].contains(_preferences.animating.statusBarBehaviour)
    }
    
    private var showsStatusUnderlay: Bool {
        
        guard _preferences.animating.statusBarBehaviour == .showUnderlay else {
            return false
        }
        
        if UIDevice.current().userInterfaceIdiom == UIUserInterfaceIdiom.pad {
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
            return CGRect(x: sidePanelPosition.isPositionedLeft ? sidePanelWidth : -sidePanelWidth, y: 0, width: screenSize.width, height: screenSize.height)

        } else {
            return CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
        }
    }
    
    private var sidePanelFrame: CGRect {
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
    
    private var statusBarWindow: UIWindow? {
        return UIApplication.shared().value(forKey: "statusBarWindow") as? UIWindow
    }
    
    // MARK:- View lifecycle -

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpViewHierarchy()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setUpViewHierarchy()
    }
    
    private func setUpViewHierarchy() {
        view = UIView(frame: UIScreen.main().bounds)
        configureViews()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if sidePanelVisible {
            toggle()
        }
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        screenSize = size
        
        coordinator.animate(alongsideTransition: { _ in
            // reposition center panel
            self.update(centerPanelFrame: self.centerPanelFrame)
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
    }
    
    // MARK: - Configurations -
    
    private func configureViews(){
        
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
            leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirection.left
            
            rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipe))
            rightSwipeGesture.delegate = self
            rightSwipeGesture.direction = UISwipeGestureRecognizerDirection.right
            
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
    
    private func set(statusBarHidden hidden: Bool, animated: Bool = true) {
        
        guard hidesStatusBar else {
            return
        }
        
        let setting = _preferences.animating.statusBarBehaviour
        
        let size = UIScreen.main().applicationFrame.size
        self.view.window?.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        if animated {
            UIApplication.shared().setStatusBarHidden(hidden, with: setting.statusBarAnimation)
        } else {
            UIApplication.shared().isStatusBarHidden = hidden
        }
        
    }
    
    private func set(statusUnderlayAlpha alpha: CGFloat) {
        guard showsStatusUnderlay else {
            return
        }
        
        if let color = centerNavController?.navigationBar.barTintColor where statusBarUnderlay.backgroundColor != color {
            statusBarUnderlay.backgroundColor = color
        }
        
        statusBarUnderlay.alpha = alpha
    }

    func update(centerPanelFrame frame: CGRect) {
        centerPanel.frame = frame
        if _preferences.animating.statusBarBehaviour == .horizontalPan {
            statusBarWindow?.frame = frame
        }
    }
    
    // MARK:- Containment -

    private func prepare(centerControllerForContainment controller: UINavigationController){
        controller.addSideMenuButton()
        controller.view.frame = centerPanel.bounds
    }
    
    private func prepare(sidePanelForDisplay display: Bool){
        
        sidePanel.isHidden = !display
        
        if !sidePanelPosition.isPositionedUnder {
            if display && centerPanelOverlay.superview == nil {
                centerPanelOverlay.alpha = 0
                view.insertSubview(self.centerPanelOverlay, belowSubview: self.sidePanel)
            }else if !display {
                centerPanelOverlay.removeFromSuperview()
            }
        } else {
            set(sideShadowHidden: display)
        }
    }
    
    private func animate(toReveal reveal: Bool, statusUpdateAnimated: Bool = true){
        
        transitionInProgress = true
        sidePanelVisible = reveal
        set(statusBarHidden: reveal, animated: statusUpdateAnimated)
        
        let setFunction = sidePanelPosition.isPositionedUnder ? setUnderSidePanel : setAboveSidePanel
        setFunction(hidden: !reveal) { _ in
            if !reveal {
                self.prepare(sidePanelForDisplay: false)
            }
            self.transitionInProgress = false
            self.centerViewController.view.isUserInteractionEnabled = !reveal
            let delegateMethod = reveal ? self.delegate?.sideMenuControllerDidReveal : self.delegate?.sideMenuControllerDidHide
            delegateMethod?(self)
        }
    }
    
    func handleTap() {
        animate(toReveal: false)
    }
    
    // MARK:- .UnderCenterPanelLeft & Right -
    
    private func set(sideShadowHidden hidden: Bool) {
        
        guard _preferences.drawing.centerPanelShadow else {
            return
        }
        
        if hidden {
            centerPanel.layer.shadowOpacity = 0.0
        } else {
            centerPanel.layer.shadowOpacity = 0.8
        }
    }
    
    private func setUnderSidePanel(hidden: Bool, completion: (() -> ())? = nil) {
        
        var centerPanelFrame = centerPanel.frame
        
        if !hidden {
            if sidePanelPosition.isPositionedLeft {
                centerPanelFrame.origin.x = sidePanel.frame.maxX
            }else{
                centerPanelFrame.origin.x = sidePanel.frame.minX - centerPanel.frame.width
            }
        } else {
            centerPanelFrame.origin = CGPoint.zero
        }
        
        var duration = hidden ? _preferences.animating.hideDuration : _preferences.animating.reavealDuration
        
        if abs(flickVelocity) > 0 {
            let newDuration = TimeInterval(sidePanel.frame.size.width / abs(flickVelocity))
            flickVelocity = 0
            duration = min(newDuration, duration)
        }
        
        
        UIView.panelAnimation( duration, animations: { _ in
            self.update(centerPanelFrame: centerPanelFrame)
            self.set(statusUnderlayAlpha: hidden ? 0 : 1)
        }) { _ in
            if hidden {
                self.set(sideShadowHidden: hidden)
            }
            completion?()
        }
    }
    
    func handleCenterPanelPan(_ recognizer: UIPanGestureRecognizer){
        
        guard canDisplaySideController else {
            return
        }
        
        self.flickVelocity = recognizer.velocity(in: recognizer.view).x
        let leftToRight = flickVelocity > 0
    
        switch(recognizer.state) {
        
        case .began:
            if !sidePanelVisible {
                sidePanelVisible = true
                prepare(sidePanelForDisplay: true)
                set(sideShadowHidden: false)
            }
            
            set(statusBarHidden: true)
            
        case .changed:
            let translation = recognizer.translation(in: view).x
            let sidePanelFrame = sidePanel.frame
            
            // origin.x or origin.x + width
            let xPoint: CGFloat = centerPanel.center.x + translation +
                (sidePanelPosition.isPositionedLeft ? -1  : 1 ) * centerPanel.frame.width / 2
            
            
            if xPoint < sidePanelFrame.minX || xPoint > sidePanelFrame.maxX{
                return
            }
            
            var alpha: CGFloat
            
            if sidePanelPosition.isPositionedLeft {
                alpha = xPoint / sidePanelFrame.width
            }else{
                alpha = 1 - (xPoint - sidePanelFrame.minX) / sidePanelFrame.width
            }
            
            set(statusUnderlayAlpha: alpha)
            var frame = centerPanel.frame
            frame.origin.x += translation
            update(centerPanelFrame: frame)
            recognizer.setTranslation(CGPoint.zero, in: view)
            
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
                        reveal = centerFrame.minX > sideFrame.width * shouldOpenPercentage
                    } else{
                        // closing
                        reveal = centerFrame.minX > sideFrame.width * shouldHidePercentage
                    }
                }else{
                    if leftToRight {
                        //closing
                        reveal = centerFrame.maxX < sideFrame.minX + shouldOpenPercentage * sideFrame.width
                    }else{
                        // opening
                        reveal = centerFrame.maxX < sideFrame.minX + shouldHidePercentage * sideFrame.width
                    }
                }
                
                animate(toReveal: reveal)
            }
        }
    }
    
    // MARK:- .OverCenterPanelLeft & Right -
    
    func handleSidePanelPan(_ recognizer: UIPanGestureRecognizer){
        
        guard canDisplaySideController else {
            return
        }
        
        flickVelocity = recognizer.velocity(in: recognizer.view).x
        
        let leftToRight = flickVelocity > 0
        let sidePanelWidth = sidePanel.frame.width
        
        switch recognizer.state {
        case .began:
            
            prepare(sidePanelForDisplay: true)
            set(statusBarHidden: true)
        
        case .changed:
            
            let translation = recognizer.translation(in: view).x
            let xPoint: CGFloat = sidePanel.center.x + translation + (sidePanelPosition.isPositionedLeft ? 1 : -1) * sidePanelWidth / 2
            var alpha: CGFloat
            
            if sidePanelPosition.isPositionedLeft {
                if xPoint <= 0 || xPoint > sidePanel.frame.width {
                    return
                }
                alpha = xPoint / sidePanel.frame.width
            }else{
                if xPoint <= screenSize.width - sidePanelWidth || xPoint >= screenSize.width {
                    return
                }
                alpha = 1 - (xPoint - (screenSize.width - sidePanelWidth)) / sidePanelWidth
            }
            
            set(statusUnderlayAlpha: alpha)
            centerPanelOverlay.alpha = alpha
            sidePanel.center.x = sidePanel.center.x + translation
            recognizer.setTranslation(CGPoint.zero, in: view)
            
        default:
            
            let shouldClose: Bool
            if sidePanelPosition.isPositionedLeft {
                shouldClose = !leftToRight && sidePanel.frame.maxX < sidePanelWidth
            } else {
               shouldClose = leftToRight && sidePanel.frame.minX >  (screenSize.width - sidePanelWidth)
            }
            
            animate(toReveal: !shouldClose)
        }
    }
    
    private func setAboveSidePanel(hidden: Bool, completion: ((Void) -> Void)? = nil){
        
        var destinationFrame = sidePanel.frame
        
        if sidePanelPosition.isPositionedLeft {
            if hidden {
                destinationFrame.origin.x = -destinationFrame.width
            } else {
                destinationFrame.origin.x = view.frame.minX
            }
        } else {
            if hidden {
                destinationFrame.origin.x = view.frame.maxX
            } else {
                destinationFrame.origin.x = view.frame.maxX - destinationFrame.width
            }
        }
        
        var duration = hidden ? _preferences.animating.hideDuration : _preferences.animating.reavealDuration
        
        if abs(flickVelocity) > 0 {
            let newDuration = TimeInterval (destinationFrame.size.width / abs(flickVelocity))
            flickVelocity = 0
            
            if newDuration < duration {
                duration = newDuration
            }
        }
        
        UIView.panelAnimation(duration, animations: { () -> () in
            let alpha = CGFloat(hidden ? 0 : 1)
            self.centerPanelOverlay.alpha = alpha
            self.set(statusUnderlayAlpha: alpha)
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
                prepare(sidePanelForDisplay: true)
                animate(toReveal: true)
            }
        }
    }
    
    // MARK:- UIGestureRecognizerDelegate -
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        switch gestureRecognizer {
        case panRecognizer:
            return _preferences.interaction.panningEnabled
        case tapRecognizer:
            return sidePanelVisible
        default:
            if gestureRecognizer is UISwipeGestureRecognizer {
                return _preferences.interaction.swipingEnabled
            }
            return true
        }
    }
}
