//
//  CachingSideViewController.swift
//  Example
//
//  Created by Teodor Patras on 15/07/16.
//  Copyright © 2016 teodorpatras. All rights reserved.
//

import UIKit
import SideMenuController

class CachingSideViewController: UITableViewController, SideMenuControllerDelegate {

    let dataSource = [FCViewController.self, SCViewController.self, TCViewController.self]
    let cellIdentifier = "cachingSideCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.whiteColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        sideMenuController?.delegate = self
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        cell?.textLabel?.text = "Switch to: " + (dataSource[indexPath.row] as! CacheableViewController.Type).cacheIdentifier
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let controllerType = dataSource[indexPath.row] as! CacheableViewController.Type
        
        if let controller = sideMenuController?.viewController(forCacheIdentifier: controllerType.cacheIdentifier) {
            sideMenuController?.embed(centerViewController: controller)
        } else {
            sideMenuController?.embed(centerViewController: UINavigationController(rootViewController: controllerType.init()), cacheIdentifier: controllerType.cacheIdentifier)
        }
    }
    
    func sideMenuControllerDidHide(sideMenuController: SideMenuController) {
        print(#function)
    }
    
    func sideMenuControllerDidReveal(sideMenuController: SideMenuController) {
        print(#function)
    }
}
