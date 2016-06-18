
<img src="https://raw.githubusercontent.com/teodorpatras/SideMenuController/master/assets/smc_logo.png" alt="SideMenuController" width=900/>

Description
--------------

`SideMenuController` is a custom container view controller written in Swift which will display the main content within a center panel and the secondary content (option menu, navigation menu, etc.) within a side panel when triggered. The side panel can be displayed either on the left or on the right side, under or over the center panel.


<table style="width:100%">
  <tr>
    <td><img src="https://raw.githubusercontent.com/teodorpatras/SideMenuController/master/assets/under-left.gif" alt="SideMenuController" height=500/></td>
    <td><img src="https://raw.githubusercontent.com/teodorpatras/SideMenuController/master/assets/under-right.gif" alt="SideMenuController" height=500/></td> 
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/teodorpatras/SideMenuController/master/assets/over-left.gif" alt="SideMenuController" height=500/></td>
    <td><img src="https://raw.githubusercontent.com/teodorpatras/SideMenuController/master/assets/over-right.gif" alt="SideMenuController" height=500/></td> 
  </tr>
</table>

# Table of Contents
1. [Features](#features)
3. [Installation](#installation)
4. [Supported OS & SDK versions](#supported-versions)
5. [Usage](#usage)
6. [Customisation](#customisation)
7. [Implementing custom transitions](#custom-transitions)
8. [Public interface](#public-interface)
9. [License](#license)
10. [Contact](#contact)

##<a name="features"> Features </a>


- [x] Easy to use, fully customizable
- [x] Left and Right side positioning
- [x] Over and Under center positioning
- [x] Automatic orientation change adjustments.
- [x] Custom status bar behaviour
- [x] Fully customizable transition animations

<a name="installation"> Installation </a>
--------------

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects.

CocoaPods 0.36 adds supports for Swift and embedded frameworks. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate EasyTipView into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'SideMenuController', '~> 0.1.0'
```

Then, run the following command:

```bash
$ pod install
```


### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate `SideMenuController` into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "teodorpatras/SideMenuController"
```

Run `carthage update` to build the framework and drag the built `SideMenuController.framework` into your Xcode project.

### Manually

If you prefer not to use either of the aforementioned dependency managers, you can integrate EasyTipView into your project manually.

<a name="supported-versions"> Supported OS & SDK Versions </a>
-----------------------------

* Supported build target - iOS 8.0 (Xcode 7.x)


<a name="usage"> Usage </a>
--------------

You can get started using `SideMenuController` in 3 basic steps:

**Step 1.**  First of all, you should **add a menu button image** and **specify the position of the side panel**. Optionally, you can customize other preferences as well:

```
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.
        
    SideMenuController.preferences.drawing.menuButtonImage = UIImage(named: "menu")
    SideMenuController.preferences.drawing.sidePanelPosition = .OverCenterPanelLeft
    SideMenuController.preferences.drawing.sidePanelWidth = 300
    SideMenuController.preferences.drawing.drawSideShadow = true
    SideMenuController.preferences.animating.statusBarBehaviour = .ShowUnderlay
}
```
_If you **do not** specify a menu button image, `SideMenuController` **will not add one by default** and you will have to manually add one whenever transitioning to a new center view controller._

**Step 2.** `SideMenuController` can be used with storyboard segues, or you can programmatically transition to a new center view controller. 

####Using storyboard segues####

``SideMenuController`` defines two custom segues:
> - `SideContainmentSegue` - which transitions to a new side controller (triggers `embedSideController`)<br />
> - `CenterContainmentSegue` - which transitions to a new center controller (triggers `embedCenterController`)

In the storyboard file, add initially two segues from the `SideMenuController` scene, one for the center view controller, and another for the side menu view controller. Later on, you can add more `CenterContainmentSeuges` depending on how many scenes you want to transition to.

Remember to set all the appropriate attributes of each segue in the Attributes Inspector:

| SideContainmentSegue   |      CenterContainmentSegue     | 
|----------|:-------------:|------:|
| ![Example](https://raw.githubusercontent.com/teodorpatras/SideMenuController/master/assets/side_settings.png) |  ![Example](https://raw.githubusercontent.com/teodorpatras/SideMenuController/master/assets/center_settings.png) |

In order to embed the inital view controlles inside the `SideMenuController` you will have to call `performSegue(withIdentifier:sender:)`. Easiest way is to subclass `SideMenuController` and override `viewDidLoad`:

```
override func viewDidLoad() {
    super.viewDidLoad()
    performSegueWithIdentifier("embedInitialCenterController", sender: nil)
    performSegueWithIdentifier("embedSideController", sender: nil)
}
```

####Programmatically####
	
You can perform all the above mentioned transitions programmatically, without using segues, by calling one of the two public methods:

```
public func embedSideController(controller: UIViewController)
public func embedCenterController(controller: UINavigationController)
```

**Step 3.** You're almost set now. Last step is to know how to transition to new center view controllers.

**Important Note:** `SideMenuController` defines an extension to `UIViewController` in order to make it more accessible via the computed property `public var sideMenuController: SideMenuController?`. From any `UIViewController` instance, you can access the `SideMenuController` by typing: `self.sideMenuController`. This will return the `SideMenuController` if the caller is one of its child view controllers or otherwise `nil`. 

From here onwards, whenever the user selects an option in the side menu controller, you can easily perform the segue like so:

####Using storyboard segues####

```
override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
	sideMenuController?.performSegueWithIdentifier(segues[indexPath.row], sender: nil)
}
```

####Programmatically####

```
override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
	sideMenuController?.embedCenterController(someUIViewControllerInstance)
}
```

<a name="customisation"> Customisation </a>
--------------
In order to customize the `SideMenuController` appearance and behaviour, you can play with the `SideMenuController .Preferences` structure. It is split into two sub structures:

* ```Drawing``` - encapsulates customisable properties specifying how ```SideMenuController``` will adjust its layout, positioning on screen.
* ```Animating``` - encapsulates customisable properties specifying which animations will be used for different components.


| `Drawing` property   |      Description      |
|----------|-------------|------|
| `menuButtonImage` |    In case this attribute is set, `SideMenuController` will add a button on the left or right side of the navigation bar in order to trigger the slide animation. If the attribute is missing, you'll have to add the menu button by yourself to all the `UINavigationControllers` that will be embedded.   |
| `sidePanelPosition` |  Specifies the positioning of the side panel. This attribute can take one of the four values:         `.UnderCenterPanelLeft`, `.UnderCenterPanelRight`, `.OverCenterPanelLeft`, `. OverCenterPanelRight` |
| `centerPanelOverlayColor` | When the side panel is either `.OverCenterPanelLeft` or `. OverCenterPanelRight`, an overlay will be shown on top of the center panel when the side is revealed. Pass the preferred color of this overlay. |
| `panningEnabled` | Enable or disable the panning gesture. Default value is `true` |
| `swipingEnabled` | Enable or disable the swiping gesture. Default value is `true` |
| `drawSideShadow` | When the side panel is either `. UnderCenterPanelRight ` or `. UnderCenterPanelLeft` you can opt in or out to draw a side shadow for the center panel.  |
    
| `Animating` property   |      Description      |
|----------|-------------|------|
| `statusBarBehaviour` | The animating style of the status bar when the side panel is revealed. This can be: <br /> **+** `.SlideOut`: the status bar will be hidden using the `UIStatusBarAnimation.Slide` animation<br /> **+** `.FadeOut`: the status bar will be hidden using the `UIStatusBarAnimation.Fade` animation<br /> **+** `.ShowUnderlay`: a layer with the same color as the navigation bar will be displayed under the status bar  |
| `reavealDuration` | Reveal animation duration. |
| `hideDuration` | Hide animation duration. |
| `transitionAnimator` | `TransitionAnimatable` subtype which defines how the new center view controller will be animated on screen. |


<a name="custom-transitions"> Implementing custom transitions </a>
--------------

In order to implement custom transition animations for the center view controller, you have to create a `struct` that conforms to the `TransitionAnimatable` protocol and implement: ```static func animateTransition(forView view: UIView, completion: () -> Void)``` 

Example:

```
public struct FadeAnimator: TransitionAnimatable {
    public static func animateTransition(forView view: UIView, completion: () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.duration = 0.35
        fadeAnimation.fromValue = 0
        fadeAnimation.toValue = 1
        
        fadeAnimation.fillMode = kCAFillModeForwards
        fadeAnimation.removedOnCompletion = true
        
        view.layer.addAnimation(fadeAnimation, forKey: "fadeInAnimation")
        
        CATransaction.commit()
    }
}
```

<a name="public-interface"> Public interface </a>
--------------

##Public methods##

`public func toggleSidePanel()` - toggles the side panel visible or not. This is the same function that gets called when the user taps the menu button on the navigation bar.

`public func embedSideController(controller: UIViewController)` - embedds a new side view controller.

`public func embedCenterController(controller: UINavigationController) ` - embedds a new center view controller.

##Public properties##

`public static var preferences: Preferences` - use this static variable to customise the `SideMenuController` preferences
`private(set) public var sidePanelVisible` - use this instance variable to check at any time if the side panel is visible or not.

<a name="license"> License </a>
--------------

```SideMenuController``` is developed by [Teodor Patraş](https://www.teodorpatras.com) and is released under the MIT license. See the ```LICENSE``` file for details.  Logo graphic created with <a href="http://logomakr.com" title="Logo Maker">Logo Maker</a>.

<a name="contact"> Contact </a>
--------------

You can follow or drop me a line on [my Twitter account](https://twitter.com/teodorpatras). If you find any issues on the project, you can open a ticket. Pull requests are also welcome.
