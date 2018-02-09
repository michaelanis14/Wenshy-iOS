//
//  SettingsViewController.swift
//  Wenchy
//
//  Created by Ramy Aboul Naga on 28/12/2017.
//  Copyright © 2017 RaMin0. All rights reserved.
//

import UIKit
import Firebase
import FacebookLogin
import GoogleSignIn

class SettingsViewController: UIViewController {
  @IBAction func handleSaveButton() {
    dismiss(animated: true, completion: nil)
  }

  @IBAction func handleLogoutButton() {
    try? Auth.auth().signOut()
    LoginManager().logOut()
    GIDSignIn.sharedInstance().signOut()

    let vc = self.presentingViewController?.presentingViewController
    dismiss(animated: true) {
      vc?.viewDidAppear(true)
    }
  }
}
