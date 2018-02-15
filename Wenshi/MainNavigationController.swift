//
//  MainNavigationController.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 8/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import UIKit
import Firebase

class MainNavigationController: UINavigationController {
  override func viewWillAppear(_ animated: Bool) {
    setNavigationBarHidden(true, animated: animated)
    super.viewWillAppear(animated)
  }

  override func viewWillDisappear(_ animated: Bool) {
    setNavigationBarHidden(false, animated: animated)
    super.viewWillDisappear(animated)
  }

  override func viewDidAppear(_ animated: Bool) {
    guard let user = Auth.auth().currentUser else {
      performSegue(withIdentifier: "auth", sender: nil)
      return
    }

    Database.database().reference(withPath: "Users/Customers")
      .child(user.uid)
      .observeSingleEvent(of: .value) { (snapshot) in
        guard snapshot.exists() else {
          Database.database().reference(withPath: "Users/Drivers")
            .child(user.uid)
            .observeSingleEvent(of: .value) { (snapshot) in
              guard snapshot.exists() else {
                self.performSegue(withIdentifier: "auth", sender: nil)
                return
              }

              self.performSegue(withIdentifier: "driver", sender: nil)
          }
          return
        }

        self.performSegue(withIdentifier: "customer", sender: nil)
    }

    dismissLoader()
  }
}
