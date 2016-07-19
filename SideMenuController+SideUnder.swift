//
//  SideMenuController+SideUnder.swift
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

// MARK: - Extension for implementing the specific functionality for when side panel is positioned under the center
extension SideMenuController {
    
    // MARK: - Methods -
    
    func configureGestureRecognizersForPositionUnder() {
        
        let panLeft = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleCenterPanelPanLeft))
        panLeft.edges = .Left
        panLeft.delegate = self
        
        let panRight = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleCenterPanelPanRight))
        panRight.edges = .Right
        panRight.delegate = self
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapRecognizer.delegate = self
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCenterPanelPan))
        panGesture.delegate = self
        
        centerPanel.addGestureRecognizer(panLeft)
        centerPanel.addGestureRecognizer(panRight)
        centerPanel.addGestureRecognizer(tapRecognizer)
    }
    
    @inline(__always) func handleCenterPanelPanLeft(gesture: UIScreenEdgePanGestureRecognizer) {
        handleCenterPanelPan(gesture)
    }
    
    @inline(__always) func handleCenterPanelPanRight(gesture: UIScreenEdgePanGestureRecognizer) {
        handleCenterPanelPan(gesture)
    }
    
    func set(sideShadowHidden hidden: Bool) {
        
        guard _preferences.drawing.centerPanelShadow else {
            return
        }
        
        if hidden {
            centerPanel.layer.shadowOpacity = 0.0
        } else {
            centerPanel.layer.shadowOpacity = 0.8
        }
    }
    
    func setUnderSidePanel(hidden hidden: Bool, completion: ((Bool) -> ())? = nil) {
        
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
        
        let updated = centerPanel.frame != centerPanelFrame
        
        UIView.panelAnimation( duration, animations: { _ in
            self.centerPanel.frame = centerPanelFrame
            self.set(statusUnderlayAlpha: hidden ? 0 : 1)
        }) { _ in
            if hidden {
                self.set(sideShadowHidden: hidden)
            }
            completion?(updated)
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
                prepare(sidePanelForDisplay: true)
                set(sideShadowHidden: false)
            }
            
            set(statusBarHidden: true)
            
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
            
            set(statusUnderlayAlpha: alpha)
            var frame = centerPanel.frame
            frame.origin.x += translation
            centerPanel.frame = frame
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
}