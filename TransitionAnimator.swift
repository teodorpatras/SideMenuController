//
//  TransitionAnimator.swift
//  SideMenuController
//
//  Created by Teodor Patras on 16/06/16.
//  Copyright © 2016 teodorpatras. All rights reserved.
//

import Foundation

/**
 *  Protocol for defining custom animations for when switching the center view controller.
 *  By the time this method is called, the view of the new center view controller has been
 *  added to the center panel and resized. You only need to implement a custom animation.
 */
public protocol TransitionAnimatable {
    static func animateTransition(forView view: UIView, completion: () -> Void)
}


public struct FadeInAnimator: TransitionAnimatable {
    public static func animateTransition(forView view: UIView, completion: () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.duration = 0.7
        fadeAnimation.fromValue = 0
        fadeAnimation.toValue = 1
        
        fadeAnimation.fillMode = kCAFillModeBoth
        fadeAnimation.removedOnCompletion = true
        
        view.layer.addAnimation(fadeAnimation, forKey: "fadeInAnimation")
        
        CATransaction.commit()
    }
}

public struct CircleMaskAnimator: TransitionAnimatable {
    public static func animateTransition(forView view: UIView, completion: () -> Void) {
        
        let screenSize = UIScreen.mainScreen().bounds.size
        
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
        view.layer.mask = maskLayer
        
        let maskLayerAnimation = CABasicAnimation(keyPath: "path")
        maskLayerAnimation.fromValue = circleMaskPathInitial.CGPath
        maskLayerAnimation.toValue = circleMaskPathFinal.CGPath
        maskLayerAnimation.duration = 0.75
        maskLayer.addAnimation(maskLayerAnimation, forKey: "path")
        
        CATransaction.commit()
    }
}