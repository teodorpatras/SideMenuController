//
//  SideMenuController+CustomTypes.swift
//  SideMenuController
//
//  Created by Teodor Patras on 15/07/16.
//  Copyright © 2016 teodorpatras. All rights reserved.
//

// MARK: - Extension for implementing the custom nested types
public extension SideMenuController {
    public enum SidePanelPosition {
        case underCenterPanelLeft
        case underCenterPanelRight
        case overCenterPanelLeft
        case overCenterPanelRight
        
        var isPositionedUnder: Bool {
            return self == SidePanelPosition.underCenterPanelLeft || self == SidePanelPosition.underCenterPanelRight
        }
        
        var isPositionedLeft: Bool {
            return self == SidePanelPosition.underCenterPanelLeft || self == SidePanelPosition.overCenterPanelLeft
        }
    }
    
    public enum StatusBarBehaviour {
        case slideAnimation
        case fadeAnimation
        case horizontalPan
        case showUnderlay
        
        var statusBarAnimation: UIStatusBarAnimation {
            switch self {
            case .fadeAnimation:
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
}
