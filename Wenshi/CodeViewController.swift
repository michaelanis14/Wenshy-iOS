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

  let CODE_LENGTH = 6

  var userUid: String?
  var mobile: String?
  var verificationID: String?

  override func viewDidLoad() {
    super.viewDidLoad()

    guard let _ = userUid, let mobile = mobile else { return }

    if let _ = verificationID { return }

    self.present(buildAlert(withTitle: "Verify",
                            message: "Please follow the instructions to verify \"\(mobile)\".") { _ in
                   PhoneAuthProvider.provider().verifyPhoneNumber(mobile,
                                                                  uiDelegate: nil) { (verificationID, error) in
                     if let error = error {
                       self.present(buildAlert(withTitle: "Error",
                                               message: error.localizedDescription),
                                    animated: true)
                       return
                     }

                     self.verificationID = verificationID
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
      Database.database().reference(withPath: "Users/Customers")
        .child(user.uid)
        .observeSingleEvent(of: .value) { snapshot in
          dismissLoader()

          guard snapshot.exists() else {
            presentLoader(self.view)
            Database.database().reference(withPath: "Users/Drivers")
              .child(user.uid)
              .observeSingleEvent(of: .value) { snapshot in
                dismissLoader()

                guard snapshot.exists() else { return }

                self.completeVerification(withUid: user.uid, snapshot: snapshot, as: "Driver")
            }

            return
          }

          self.completeVerification(withUid: user.uid, snapshot: snapshot, as: "Customer")
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
      .updateChildValues(["verified": true]) { (error, ref) in
        dismissLoader()

        if let error = error {
          self.present(buildAlert(withTitle: "Error",
                                  message: error.localizedDescription),
                       animated: true)
          print(error.localizedDescription)
          return
        }

        self.dismiss(animated: true)
    }
  }
}
