//
//  SideMenuTableViewController.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 10/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import UIKit
import FirebaseAuth
import FacebookLogin
import GoogleSignIn

class SideMenuTableViewController: UITableViewController {
  @IBOutlet weak var profileView: UIView!
  @IBOutlet weak var avatarImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.backgroundView = UIView(frame: CGRect(x: 0, y: 0,
                                                    width: tableView.bounds.size.width,
                                                    height: tableView.bounds.size.height))
    tableView.backgroundColor = profileView.backgroundColor
    tableView.delegate = self

    avatarImageView.layer.cornerRadius = avatarImageView.frame.size.width / 2
  }

  override func viewWillAppear(_ animated: Bool) {
    if let user = Auth.auth().currentUser {
      nameLabel.text = user.displayName ?? user.email
    }
  }

  @IBAction func handleLogoutButton() {
    try? Auth.auth().signOut()
    LoginManager().logOut()
    GIDSignIn.sharedInstance().signOut()

    if let vc = presentingViewController?.presentingViewController {
      presentingViewController?.dismiss(animated: true, completion: {
        vc.dismiss(animated: true)
      })
    }
  }
}

extension SideMenuTableViewController {
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return profileView
  }

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return profileView.frame.size.height
  }
}
