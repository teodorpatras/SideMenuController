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
        leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirection.left
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleRightSwipe))
        rightSwipeGesture.delegate = self
        rightSwipeGesture.direction = UISwipeGestureRecognizerDirection.right
        
        centerPanelOverlay.addGestureRecognizer(tapRecognizer)
        
        if sidePanelPosition.isPositionedLeft {
            centerPanel.addGestureRecognizer(rightSwipeGesture)
            centerPanelOverlay.addGestureRecognizer(leftSwipeRecognizer)
        } else {
            centerPanel.addGestureRecognizer(leftSwipeRecognizer)
            centerPanelOverlay.addGestureRecognizer(rightSwipeGesture)
        }
    }
    
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
    
    func setAboveSidePanel(hidden: Bool, completion: ((Bool) -> ())? = nil){
        
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
