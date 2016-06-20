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
    static var animation: CAAnimation {get}
}


public struct FadeAnimator: TransitionAnimatable {
    
    public static var animation: CAAnimation{
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.duration = 0.35
        fadeAnimation.fromValue = 0
        fadeAnimation.toValue = 1
        fadeAnimation.fillMode = kCAFillModeForwards
        fadeAnimation.removedOnCompletion = true
        return fadeAnimation
    }
}