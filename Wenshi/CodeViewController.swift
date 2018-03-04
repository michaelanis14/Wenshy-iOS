//
//  CodeViewController.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 15/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class CodeViewController: UIViewController {
  @IBOutlet weak var codeTextField: UITextField!
  @IBOutlet weak var registerButton: UIButton!

  let CODE_LENGTH = 6

  var userUid: String?
  var mobile: String?
  var actionText: String?
  var verificationID: String?
  var verifying = false

  override func viewDidLoad() {
    super.viewDidLoad()

    if let actionText = actionText {
      registerButton.setTitle(actionText.uppercased(), for: .normal)
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    guard let _ = userUid, let mobile = mobile else { return }

    if verifying { return }

    self.present(buildAlert(withTitle: "Verify",
                            message: "Please follow the instructions to verify \"\(mobile)\".") { _ in
                   self.verifying = true

                   PhoneAuthProvider.provider().verifyPhoneNumber(sanitizeMobile(mobile),
                                                                  uiDelegate: nil) { (verificationID, error) in
                     if let error = error {
                       self.present(buildAlert(withTitle: "Error",
                                               message: error.localizedDescription),
                                    animated: true)
                       return
                     }

                     self.verificationID = verificationID
                     self.verifying = false
                   }
                 },
                 animated: true)
  }

  @IBAction func handleRegisterButton() {
    guard let verificationID = verificationID else {
      return
    }

    guard let code = codeTextField.text, code != "", code.count == CODE_LENGTH else {
      self.present(buildAlert(withTitle: "Error",
                              message: "Missing or invalid code"),
                   animated: true)
      return
    }

    guard let user = Auth.auth().currentUser else { return }

    let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID,
                                                             verificationCode: code)

    presentLoader(view)
    if let _ = user.phoneNumber {
      user.updatePhoneNumber(credential) { error in
        dismissLoader()

        if let error = error {
          self.present(buildAlert(withTitle: "Error",
                                  message: error.localizedDescription),
                       animated: true)
          return
        }

        self.verificationID = nil

        presentLoader(self.view)

        findUser(user.uid) { (snapshot, role) in
          dismissLoader()

          guard let snapshot = snapshot else { return }

          switch role {
          case .customer, .driver:
            self.completeVerification(withUid: user.uid, snapshot: snapshot, as: role.rawValue)
          case .none:
            return
          }
        }
      }
    } else {
      user.link(with: credential) { (_, error) in
        dismissLoader()

        if let error = error {
          self.present(buildAlert(withTitle: "Error",
                                  message: error.localizedDescription),
                       animated: true)
          return
        }

        self.verificationID = nil

        presentLoader(self.view)

        findUser(user.uid) { (snapshot, role) in
          dismissLoader()

          guard let snapshot = snapshot else { return }

          switch role {
          case .customer, .driver:
            self.completeVerification(withUid: user.uid, snapshot: snapshot, as: role.rawValue)
          case .none:
            return
          }
        }
      }
    }
  }

  @IBAction func handleResendCode() {
    verificationID = nil

    viewDidLoad()
  }


  func completeVerification(withUid uid: String, snapshot: DataSnapshot, as role: String) {
    presentLoader(view)

    let refPath = "\(role)s"
    Database.database().reference(withPath: "Users/\(refPath)")
      .child(uid)
      .updateChildValues([
        "mobile": sanitizeMobile(mobile!),
        "verified": true
      ]) { (error, ref) in
        dismissLoader()

        if let error = error {
          self.present(buildAlert(withTitle: "Error",
                                  message: error.localizedDescription),
                       animated: true)
          return
        }

        self.dismiss(animated: true)
    }
  }
}
