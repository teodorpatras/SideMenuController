//
//  SideMenuController+SideOver.swift
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

// MARK: - Extension for implementing the specific functionality for when side panel is positioned over the center
extension SideMenuController {
    
    func configureGestureRecognizersForPositionOver() {
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapRecognizer.delegate = self
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSidePanelPan))
        panRecognizer.delegate = self
        sidePanel.addGestureRecognizer(panRecognizer)
        
        let leftSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleLeftSwipe))
        leftSwipeRecognizer.delegate = self
        leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirection.Left
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipe))
        rightSwipeGesture.delegate = self
        rightSwipeGesture.direction = UISwipeGestureRecognizerDirection.Right
        
        centerPanelOverlay.addGestureRecognizer(tapRecognizer)
        
        if sidePanelPosition.isPositionedLeft {
            centerPanel.addGestureRecognizer(rightSwipeGesture)
            centerPanelOverlay.addGestureRecognizer(leftSwipeRecognizer)
        } else {
            centerPanel.addGestureRecognizer(leftSwipeRecognizer)
            centerPanelOverlay.addGestureRecognizer(rightSwipeGesture)
        }
    }
    
    func handleSidePanelPan(recognizer: UIPanGestureRecognizer){
        
        guard canDisplaySideController else {
            return
        }
        
        flickVelocity = recognizer.velocityInView(recognizer.view).x
        
        let leftToRight = flickVelocity > 0
        let sidePanelWidth = CGRectGetWidth(sidePanel.frame)
        
        switch recognizer.state {
        case .Began:
            
            prepare(sidePanelForDisplay: true)
            set(statusBarHidden: true)
            
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
            
            set(statusUnderlayAlpha: alpha)
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
    
    func setAboveSidePanel(hidden hidden: Bool, completion: ((Bool) -> ())? = nil){
        
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
        
        let updated = sidePanel.frame != destinationFrame
        
        UIView.panelAnimation(duration, animations: { () -> () in
            let alpha = CGFloat(hidden ? 0 : 1)
            self.centerPanelOverlay.alpha = alpha
            self.set(statusUnderlayAlpha: alpha)
            self.sidePanel.frame = destinationFrame
            }, completion: { _ in
                completion?(updated)
        })
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
}