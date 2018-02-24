//
//  LoginViewController.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 24/12/2017.
//  Copyright © 2017 RaMin0 Development. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FacebookCore
import FacebookLogin
import GoogleSignIn

class LoginViewController: UIViewController {
  @IBOutlet weak var emailTextField: UITextField!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var facebookLoginButton: UIButton!
  @IBOutlet weak var googleButton: UIButton!
  @IBOutlet weak var googleButtonTopSpacing: NSLayoutConstraint!
  @IBOutlet weak var googleButtonHeight: NSLayoutConstraint!
  @IBOutlet weak var googleImageView: UIImageView!

  override func viewWillAppear(_ animated: Bool) {
    self.navigationController?.setNavigationBarHidden(true, animated: animated)
    super.viewWillAppear(animated)
  }

  override func viewWillDisappear(_ animated: Bool) {
    self.navigationController?.setNavigationBarHidden(false, animated: animated)
    super.viewWillDisappear(animated)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    guard #available(iOS 9.0, *) else {
      googleButton.isHidden = true
      googleButtonTopSpacing.constant = 0
      googleButtonHeight.constant = 0
      googleImageView.isHidden = true
      return
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.destination {
    case let vc as RegisterViewController:
      if let userData = sender as? [String: Any] {
        vc.userData = userData
      }
    case let vc as CodeViewController:
      if let userData = sender as? [String: Any] {
        vc.userUid = userData["uid"] as? String
        vc.mobile = userData["mobile"] as? String
      }
    default:
      return
    }
  }

  @IBAction func handleTap() {
    if let email = emailTextField.text {
      if email.contains("rider") {
        emailTextField.text = email.replacingOccurrences(of: "rider", with: "driver")
      } else {
        emailTextField.text = email.replacingOccurrences(of: "driver", with: "rider")
      }
    }
  }

  @IBAction func handleLoginButton() {
    guard let email = emailTextField.text,
      let password = passwordTextField.text,
      email != "" && password != "" else {
        self.present(buildAlert(withTitle: "Error",
                                message: "Missing email or password"),
                     animated: true)
        return
    }

    login(withEmail: email, password: password)
  }

  @IBAction func handleFacebookButton() {
    if let accessToken = AccessToken.current {
      login(withFacebookToken: accessToken)
      return
    }

    presentLoader(view)

    let loginManager = LoginManager()
    loginManager.logIn(readPermissions: [.publicProfile, .email]) { result in
      dismissLoader()

      switch result {
      case .success(_, _, let accessToken):
        self.login(withFacebookToken: accessToken)
      case .failed(let error):
        self.present(buildAlert(withTitle: "Error",
                                message: error.localizedDescription),
                     animated: true)
      default:
        return
      }
    }
  }
  
  @IBAction func handleGoogleButton() {
    if let accessToken = GIDSignIn.sharedInstance().currentUser?.authentication {
      login(withGoogleToken: accessToken)
      return
    }

    presentLoader(view)

    GIDSignIn.sharedInstance().delegate = self
    GIDSignIn.sharedInstance().uiDelegate = self
    GIDSignIn.sharedInstance().signIn()
  }

  func login(withCredential credential: AuthCredential) {
    presentLoader(view)

    Auth.auth().signInAndRetrieveData(with: credential) { (result, error) in
      dismissLoader()

      if let error = error {
        self.present(buildAlert(withTitle: "Error",
                                message: error.localizedDescription),
                     animated: true)
        return
      }

      guard let result = result else { return }

      presentLoader(self.view)
      findUser(result.user.uid) { (snapshot, role) in
        dismissLoader()
        
        guard let snapshot = snapshot else { return }

        switch role {
        case .customer, .driver:
          self.completeLogin(withUid: result.user.uid, snapshot: snapshot)
        case .none:
          var userData: [String : Any] = [
            "uid": result.user.uid
          ]

          if let profile = result.additionalUserInfo?.profile {
            userData["name"] = profile["name"] as! String
            userData["email"] = profile["email"] as! String
          }

          self.performSegue(withIdentifier: "register", sender: userData)
        }
      }
    }
  }

  func login(withEmail email: String, password: String) {
    let credential = EmailAuthProvider.credential(withEmail: email, password: password)
    login(withCredential: credential)
  }

  func login(withFacebookToken accessToken: AccessToken) {
    let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
    login(withCredential: credential)
  }

  func login(withGoogleToken accessToken: GIDAuthentication) {
    let credential = GoogleAuthProvider.credential(withIDToken: accessToken.idToken,
                                                   accessToken: accessToken.accessToken)
    login(withCredential: credential)
  }

  func completeLogin(withUid uid: String, snapshot: DataSnapshot) {
    if let userData = snapshot.value as? [String: Any] {
      guard let verified = userData["verified"] as? Bool, verified else {
        self.performSegue(withIdentifier: "code", sender: [
          "uid": uid,
          "mobile": userData["mobile"] as! String
          ])
        return
      }
    }

    self.dismiss(animated: true)
  }
}

extension LoginViewController: GIDSignInDelegate, GIDSignInUIDelegate {
  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
    dismissLoader()

    if let error = error {
      if case .canceled = GIDSignInErrorCode(rawValue: error._code)! { return }

      self.present(buildAlert(withTitle: "Error",
                              message: error.localizedDescription),
                   animated: true)
      return
    }

    guard let accessToken = user.authentication else { return }

    login(withGoogleToken: accessToken)
  }
}
