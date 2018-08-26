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
    static func performTransition(forView view: UIView, completion:  @escaping () -> Void)
}


public struct FadeAnimator: TransitionAnimatable {
    
    public static func performTransition(forView view: UIView, completion: @escaping () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.duration = 0.35
        fadeAnimation.fromValue = 0
        fadeAnimation.toValue = 1
        fadeAnimation.fillMode = CAMediaTimingFillMode.forwards
        fadeAnimation.isRemovedOnCompletion = true
        view.layer.add(fadeAnimation, forKey: "fade")
        CATransaction.commit()
    }
}

public struct CircleMaskAnimator: TransitionAnimatable {
    
    public static func performTransition(forView view: UIView, completion: @escaping () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        
        let screenSize = UIScreen.main.bounds.size
        let dim = max(screenSize.width, screenSize.height)
        let circleDiameter : CGFloat = 50.0
        let circleFrame = CGRect(x: (screenSize.width - circleDiameter) / 2, y: (screenSize.height - circleDiameter) / 2, width: circleDiameter, height: circleDiameter)
        let circleCenter = CGPoint(x: circleFrame.origin.x + circleDiameter / 2, y: circleFrame.origin.y + circleDiameter / 2)
        
        let circleMaskPathInitial = UIBezierPath(ovalIn: circleFrame)
        let extremePoint = CGPoint(x: circleCenter.x - dim, y: circleCenter.y - dim)
        let radius = sqrt((extremePoint.x * extremePoint.x) + (extremePoint.y * extremePoint.y))
        let circleMaskPathFinal = UIBezierPath(ovalIn: circleFrame.insetBy(dx: -radius, dy: -radius))
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = circleMaskPathFinal.cgPath
        view.layer.mask = maskLayer
        
        let maskLayerAnimation = CABasicAnimation(keyPath: "path")
        maskLayerAnimation.fromValue = circleMaskPathInitial.cgPath
        maskLayerAnimation.toValue = circleMaskPathFinal.cgPath
        maskLayerAnimation.duration = 0.6
        
        view.layer.mask?.add(maskLayerAnimation, forKey: "circleMask")
        CATransaction.commit()
    }
}
