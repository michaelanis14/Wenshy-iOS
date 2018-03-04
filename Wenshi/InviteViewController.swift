//
//  InviteViewController.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 4/3/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import UIKit
import FirebaseAuth

class InviteViewController: UIViewController {
  @IBOutlet weak var uidLabel: UILabel!

  var uid = Auth.auth().currentUser?.uid

  override func viewDidLoad() {
    super.viewDidLoad()

    uidLabel.text = uid
  }

  @IBAction func handleShareButton() {
    guard let uid = uid else { return }

    let activity = UIActivityViewController(activityItems: [uid], applicationActivities: nil)
    present(activity, animated: true)
  }
}
