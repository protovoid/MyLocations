//
//  MyTabBarController.swift
//  MyLocations
//
//  Created by Chad on 1/30/18.
//  Copyright © 2018 Chad Williams. All rights reserved.
//

import UIKit

class MyTabBarController: UITabBarController {
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  override var childViewControllerForStatusBarStyle: UIViewController? {
    return nil
  }
}
