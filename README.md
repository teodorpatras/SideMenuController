# SideMenuController

Purpose
--------------

SideMenuController is a custom container view controller written in Swift which will display the main content within a center panel and the secondary content (option menu, navigation menu, etc.) within a side panel when triggered. The side panel can be displayed either on the left or on the right side, under or above the center panel.

![Example](/../master/images/preview.gif)

Usage
--------------

1. In the storyboard file, add one ``custom`` segue from the side menu controller to the center view controller. Don't forget to set its class to ``ContainmentSegue`` and its identifier to ``CenterContainment``. **NOTE: All future segues for changing the center controller will not require any identifier since the custom segue class defaults to ``CenterContainment`` when it has no identifier.**
![Example](/../master/images/segue_center.png)
2. In the storyboard file, add one ``custom`` segue from the side menu controller to the side view controller. Don't forget to set its class to ``ContainmentSegue`` and its identifier to ``SideContainment``.
![Example](/../master/images/segue_side.png)
3. In you ``AppDelegate`` file, in the ``application:didFinishLaunchingWithOptions:`` method you can customize the ``SideMenuController``:

	**You should customize at least these three properties :**
	
	```swift
  SideMenuController.menuButtonImage = UIImage(named: "menuButton")
  SideMenuController.presentationStyle = .UnderCenterPanelLeft
  SideMenuController.animationStyle = .FadeAnimation
	```
	
Customization
--------------

SideMenuController has the following customizable properties:
```swift
class var menuButtonImage : UIImage?
```
The image object to be displayed on the button that will trigger the side panel. Button displayed either on the right or left side of the navigation bar.
```swift
class var panningEnabled : Bool
```
A boolean flag indicating wether or not panning is enabled for revealing/hiding the side panel.
```swift
class var presentationStyle : SideMenuControllerPresentationStyle
```
The presentation style of the side menu controller.

```swift
class var animationStyle : CenterContainmentAnimationStyle
```
The animation style for changin the center view controller.

```swift
class var useShadow: Bool
```    
A flag indicating wether or not the center panel should draw shadow around it.

Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 7.0 (Xcode 6.x)

Custom types
--------------

```swift
enum SideMenuControllerPresentationStyle {
    case UnderCenterPanelLeft
    case UnderCenterPanelRight
    case AboveCenterPanelLeft
    case AboveCenterPanelRight
}
```

This enum exposes the four different presentation styles for the side menu controller. **Default value is** ``UnderCenterPanelLeft``**.**

```swift
enum CenterContainmentAnimationStyle {
    case CircleMaskAnimation
    case FadeAnimation
}
```

This enum exposes the two different animation styles for the change of the center view controller. **Default value is** ``CircleMaskAnimation``**.**

```swift
  class ContainmentSegue : UIStoryboardSegue
```

A custom ``UIStoryboardSegue`` subclass which makes this component work seamlessly with storyboards.

```swift
  enum ContainmentSegueType{
    case Center
    case Side
}
```

This enum exposes the two types of the containment segue: for adding a new center view controller, or for adding a new side view controller.

Methods
--------------

SideMenuController implements an extension for the ``UIViewController`` which exposes the method:

```swift
func sideMenuController() 
```

This method goes up the parent view controller chain and searches for the ``SideMenuController``. You can use this method if you want to get a reference to the ``SideMenuController`` from within your custom view controller.

```swift
func addNewController(controller : UIViewController, forSegueType type:ContainmentSegueType)
```

This method gets called when the ``ContainmentSegue`` gets performed. Normally you don't have to call this method yourself since it will get called automatically when the segue is performed. If you don't use storyboards or segues, you can use this method to add the center and side controllers.

```swift
func toggleSidePanel ()
```

This method gets called when the menu button in the navigation bar is pressed. You can call this method yourself from your view controller by using ``self.sideMenuController()?.toggleSidePanel()`` if you want to trigger the side pannel programmatically.

