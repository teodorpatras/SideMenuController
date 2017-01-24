//
//  SideMenuController+Animation.swift
//  SideMenuController
//
//  Created by Sergey Navka on 1/16/17.
//  Copyright © 2017 teodorpatras. All rights reserved.
//

extension SideMenuController {
    
    public func sideMenu(toFull: Bool, animation:(()->Void)? = nil, completion: ((Bool)->Void)? = nil) {
        let duration = 0.25
        let valuesForChanges = valuesForSideFullScreen(toFull)
        
        let animationClosure: ()-> Void = { [weak self] in
            self?.sidePanel.frame.size.width = valuesForChanges.sidePanelWidht
            self?.sidePanel.frame.origin.x = valuesForChanges.sidePanelX
            self?.centerPanel.frame.origin.x = valuesForChanges.centerPanelX
            self?.sideMenuController?.view.layoutIfNeeded()
            if let animation = animation {
                animation()
            }
        }
        
        UIView.animate(withDuration: duration, animations: animationClosure, completion: completion)
    }
    
    private func valuesForSideFullScreen(_ isFull: Bool) -> (sidePanelWidht: CGFloat, sidePanelX: CGFloat, centerPanelX: CGFloat) {
       
        var sidePanelX: CGFloat = 0.0
        var centerPanelX: CGFloat = 0.0
        let sidePanelWidht = isFull ? screenSize.width : _preferences.drawing.sidePanelWidth
        
        if sidePanelPosition.isPositionedLeft {
            sidePanelX = 0.0
            centerPanelX = isFull ? screenSize.width : _preferences.drawing.sidePanelWidth
        } else {
            sidePanelX = isFull ? 0.0 : screenSize.width - _preferences.drawing.sidePanelWidth
            centerPanelX = isFull ? -screenSize.width : -_preferences.drawing.sidePanelWidth
        }
        if !sidePanelPosition.isPositionedUnder { centerPanelX = 0.0 }
        return (sidePanelWidht, sidePanelX, centerPanelX)
    }
}
