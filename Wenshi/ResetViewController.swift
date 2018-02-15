//
//  ResetViewController.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 4/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import UIKit
import FirebaseAuth

class ResetViewController: UIViewController {
  @IBOutlet weak var emailTextField: UITextField!

  @IBAction func handleResetButton() {
    guard let email = emailTextField.text,
      email != "" else {
        self.present(buildAlert(withTitle: "Error",
                                message: "Missing email"),
                     animated: true)
        return
    }

    presentLoader(view)
    Auth.auth().sendPasswordReset(withEmail: email) { err in
      dismissLoader()

      if let err = err {
        self.present(buildAlert(withTitle: "Error",
                                message: err.localizedDescription),
                     animated: true)
        return
      }

      self.present(buildAlert(withTitle: "Forgot Password",
                              message: "Please follow the instructions sent to \"\(email)\".") { _ in
                                self.navigationController?.popViewController(animated: true)
        },
                   animated: true)
    }
  }
}


