//
//  LoginViewController.swift
//  Wenchy
//
//  Created by Ramy Aboul Naga on 24/12/2017.
//  Copyright © 2017 RaMin0. All rights reserved.
//

import UIKit
import Firebase
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
    if let vc = segue.destination as? RegisterViewController,
      let userData = sender as? [String: Any] {
      vc.userData = userData
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

      if credential.provider == EmailAuthProviderID {
        self.dismiss(animated: true, completion: nil)
        return
      }

      presentLoader(self.view)
      Database.database().reference(withPath: "Users/Customers")
        .child(result.user.uid)
        .observeSingleEvent(of: .value) { snapshot in
          guard snapshot.exists() else {
            Database.database().reference(withPath: "Users/Drivers")
              .child(result.user.uid)
              .observeSingleEvent(of: .value) { snapshot in
                dismissLoader()

                guard snapshot.exists() else {
                  if let profile = result.additionalUserInfo?.profile {
                    let userData: [String : Any] = [
                      "uid": result.user.uid,
                      "name": profile["name"] as! String,
                      "email": profile["email"] as! String
                    ]

                    self.performSegue(withIdentifier: "register", sender: userData)
                  }
                  return
                }

                self.dismiss(animated: true)
            }

            return
          }

          self.dismiss(animated: true)
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
