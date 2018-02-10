//
//  SideMenuTableViewController.swift
//  Wenchy
//
//  Created by Ramy Aboul Naga on 10/2/2018.
//  Copyright © 2018 RaMin0. All rights reserved.
//

import UIKit
import Firebase
import FacebookLogin
import GoogleSignIn

class SideMenuTableViewController: UITableViewController {
  @IBOutlet weak var avatarImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    avatarImageView.layer.cornerRadius = avatarImageView.frame.size.width / 2
    avatarImageView.clipsToBounds = true

    nameLabel.text = Auth.auth().currentUser?.displayName
  }

  override func viewWillAppear(_ animated: Bool) {
    self.navigationController?.setNavigationBarHidden(true, animated: animated)
    super.viewWillAppear(animated)
  }

  override func viewWillDisappear(_ animated: Bool) {
    self.navigationController?.setNavigationBarHidden(false, animated: animated)
    super.viewWillDisappear(animated)
  }

  @IBAction func handleLogoutButton() {
    try? Auth.auth().signOut()
    LoginManager().logOut()
    GIDSignIn.sharedInstance().signOut()

    let vc = self.presentingViewController
    dismiss(animated: true) {
      vc?.viewDidAppear(true)
    }
  }
}
