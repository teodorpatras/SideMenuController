//
//  TransitionAnimator.swift
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