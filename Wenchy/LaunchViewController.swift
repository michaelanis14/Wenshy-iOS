//
//  LaunchViewController.swift
//  Wenchy
//
//  Created by Ramy Aboul Naga on 8/2/2018.
//  Copyright © 2018 RaMin0. All rights reserved.
//

import UIKit
import Firebase

class LaunchNavigationController: UINavigationController {
  override func viewDidAppear(_ animated: Bool) {
    guard let _ = Auth.auth().currentUser else {
      performSegue(withIdentifier: "auth", sender: nil)
      return
    }
  }
}
