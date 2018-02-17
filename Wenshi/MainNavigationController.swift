//
//  MainNavigationController.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 8/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

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

              self.completeMain(withUid: user.uid, snapshot: snapshot, as: "Driver")
          }

          return
        }

        self.completeMain(withUid: user.uid, snapshot: snapshot, as: "Customer")
    }

    dismissLoader()
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let vc = segue.destination as? CodeViewController,
      let userData = sender as? [String: Any] {
      vc.userUid = userData["uid"] as? String
      vc.mobile = userData["mobile"] as? String
    }
  }

  func completeMain(withUid uid: String, snapshot: DataSnapshot, as role: String) {
    if let userData = snapshot.value as? [String: Any] {
      guard let verified = userData["verified"] as? Bool, verified else {
        self.performSegue(withIdentifier: "auth", sender: nil)

        return
      }

      self.performSegue(withIdentifier: role.lowercased(), sender: nil)
    }
  }
}
