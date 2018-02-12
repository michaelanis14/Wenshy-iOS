//
//  RegisterViewController.swift
//  Wenchy
//
//  Created by Ramy Aboul Naga on 3/2/2018.
//  Copyright © 2018 RaMin0. All rights reserved.
//

import UIKit
import Firebase

class RegisterViewController: UIViewController {
  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var emailTextField: UITextField!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var mobileTextField: UITextField!
  @IBOutlet weak var carTypeTextField: UITextField!
  @IBOutlet weak var carModelTextField: UITextField!
  @IBOutlet weak var addressTextField: UITextField!
  @IBOutlet weak var roleSwitch: UISwitch!

  @IBOutlet weak var nameTextFieldHeight: NSLayoutConstraint!
  @IBOutlet weak var nameTextFieldBottomSpacing: NSLayoutConstraint!
  @IBOutlet weak var emailTextFieldHeight: NSLayoutConstraint!
  @IBOutlet weak var emailTextFieldBottomSpacing: NSLayoutConstraint!
  @IBOutlet weak var passwordTextFieldHeight: NSLayoutConstraint!
  @IBOutlet weak var passwordTextFieldBottomSpacing: NSLayoutConstraint!

  var userData: [String: Any]?
  var userUid: String?

  override func viewDidLoad() {
    super.viewDidLoad()

    if let userData = userData {
      if let userUid = userData["uid"] as? String {
        self.userUid = userUid
        passwordTextFieldHeight.constant = 0
        passwordTextFieldBottomSpacing.constant = 0
        passwordTextField.isHidden = true
        passwordTextField.layoutIfNeeded()
      }

      if let name = userData["name"] as? String {
        nameTextField.text = name
        nameTextFieldHeight.constant = 0
        nameTextFieldBottomSpacing.constant = 0
        nameTextField.isHidden = true
        nameTextField.layoutIfNeeded()
      }

      if let email = userData["email"] as? String {
        emailTextField.text = email
        emailTextFieldHeight.constant = 0
        emailTextFieldBottomSpacing.constant = 0
        emailTextField.isHidden = true
        emailTextField.layoutIfNeeded()
      }
    }
  }
  
  @IBAction func handleRegisterButton() {
    guard let name = nameTextField.text,
      let email = emailTextField.text,
      let password = passwordTextField.text,
      let mobile = mobileTextField.text,
      let carType = carTypeTextField.text,
      let carModel = carModelTextField.text,
      let address = addressTextField.text,
      name != "" && email != "" && password != "" && mobile != "" &&
        carType != "" && carModel != "" && address != "" else {
          self.present(buildAlert(withTitle: "Error",
                                  message: "Missing fields"),
                       animated: true)
          return
    }

    userData = [
      "name": name,
      "email": email,
      "mobile": mobile,
      "carType": carType,
      "carModel": carModel,
      "address": address
    ]

    if let _ = userUid {
      self.completeRegisteration()
      return
    }

    presentLoader(view)
    Auth.auth().createUser(withEmail: email,
                           password: password) { (user, error) in
                            dismissLoader()
                            
                            if let error = error {
                              self.present(buildAlert(withTitle: "Error",
                                                      message: error.localizedDescription),
                                           animated: true)
                              return
                            }
                            
                            guard let user = user else { return }

                            self.userUid = user.uid

                            self.completeRegisteration()
    }
  }

  func completeRegisteration() {
    presentLoader(view)

    let profile = Auth.auth().currentUser?.createProfileChangeRequest()
    profile?.displayName = userData?["name"] as? String
    profile?.commitChanges()

    let refPath = roleSwitch.isOn ? "Drivers" : "Customers"
    Database.database().reference(withPath: "Users/\(refPath)")
      .child(userUid!)
      .setValue(userData) { (error, ref) in
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

