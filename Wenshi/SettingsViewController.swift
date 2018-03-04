//
//  SettingsViewController.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 28/12/2017.
//  Copyright © 2017 RaMin0 Development. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class SettingsViewController: UITableViewController {
  var user: User?

  let LANGUAGES = [
    "English": "en",
    "Arabic": "ar"
  ]

  let SETTINGS = [
    [["General"], [
      "Language"
    ]],
    [["Profile"], [
      "Name",
      "Email",
      "Mobile",
      "Password"
    ]]
  ]

  override func viewDidAppear(_ animated: Bool) {
    user = Auth.auth().currentUser
    tableView.reloadData()
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let vc = segue.destination as? CodeViewController,
      let userData = sender as? [String: Any] {
      vc.userUid = userData["uid"] as? String
      vc.mobile = userData["mobile"] as? String
      vc.actionText = "Confirm"
    }
  }

  func handleLanguageButton() {
    let alert = UIAlertController(title: "Language", message: nil, preferredStyle: .alert)
    for (languageName, _) in LANGUAGES {
      alert.addAction(UIAlertAction(title: languageName, style: .default, handler: { action in
        if let languageName = action.title, let languageCode = self.LANGUAGES[languageName] {
          UserDefaults.standard.set(languageCode, forKey: prefLanguage)
          self.tableView.reloadData()
        }
      }))
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(alert, animated: true)
  }

  func handleNameButton() {
    guard let user = self.user else { return }

    let alert = UIAlertController(title: "Name", message: nil, preferredStyle: .alert)
    alert.addTextField { textField in
      textField.text = user.displayName
    }
    alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { action in
      presentLoader(self.view)

      findUser(user.uid) { (snapshot, role) in
        guard let name = (alert.textFields![0] as UITextField).text else { return }
        Database.database().reference(withPath: "Users/\(role.rawValue)s")
          .child(user.uid)
          .updateChildValues(["name": name]) { (_, _) in
            let profile = user.createProfileChangeRequest()
            profile.displayName = name
            profile.commitChanges(completion: { _ in
              dismissLoader()

              self.tableView.reloadData()
            })
          }
      }
    }))
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(alert, animated: true)
  }

  func handleEmailButton() {
    guard let user = self.user else { return }

    let alert = UIAlertController(title: "Email", message: nil, preferredStyle: .alert)
    alert.addTextField { textField in
      textField.text = user.email
    }
    alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { action in
      presentLoader(self.view)

      findUser(user.uid) { (snapshot, role) in
        guard let email = (alert.textFields![0] as UITextField).text else { return }

        user.updateEmail(to: email) { error in
          if let error = error {
            dismissLoader()

            var message = error.localizedDescription

            switch AuthErrorCode(rawValue: error._code)! {
            case .requiresRecentLogin:
              message = "Please logout and login first, then try again"
            default:
              break
            }

            self.present(buildAlert(withTitle: "Error",
                                    message: message),
                         animated: true)

            return
          }

          Database.database().reference(withPath: "Users/\(role.rawValue)s")
            .child(user.uid)
            .updateChildValues(["email": email]) { (_, _) in
              user.sendEmailVerification { _ in
                dismissLoader()

                self.tableView.reloadData()
              }
          }
        }
      }
    }))
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(alert, animated: true)
  }

  func handleMobileButton() {
    guard let user = self.user else { return }

    let alert = UIAlertController(title: "Mobile", message: nil, preferredStyle: .alert)
    alert.addTextField { textField in
      textField.text = user.phoneNumber
    }
    alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { action in
      presentLoader(self.view)

      findUser(user.uid) { (snapshot, role) in
        dismissLoader()

        guard let mobile = (alert.textFields![0] as UITextField).text else { return }

        self.performSegue(withIdentifier: "code", sender: [
          "uid": user.uid,
          "mobile": mobile
        ])
      }
    }))
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(alert, animated: true)
  }

  func handlePasswordButton() {
    guard let user = self.user else { return }

    let alert = UIAlertController(title: "Password", message: nil, preferredStyle: .alert)
    alert.addTextField { textField in
      textField.isSecureTextEntry = true
    }
    alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { action in
      presentLoader(self.view)

      findUser(user.uid) { (snapshot, role) in
        dismissLoader()

        guard let password = (alert.textFields![0] as UITextField).text else { return }

        user.updatePassword(to: password) { error in
          dismissLoader()

          if let error = error {
            var message = error.localizedDescription

            switch AuthErrorCode(rawValue: error._code)! {
            case .requiresRecentLogin:
              message = "Please logout and login first, then try again"
            default:
              break
            }

            self.present(buildAlert(withTitle: "Error",
                                    message: message),
                         animated: true)

            return
          }

          self.present(buildAlert(withTitle: "Password",
                                  message: "Saved"),
                       animated: true)
        }
      }
    }))
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(alert, animated: true)
  }
}

extension SettingsViewController {
  override func numberOfSections(in tableView: UITableView) -> Int {
    return SETTINGS.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return SETTINGS[section][0][0]
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return SETTINGS[section][1].count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "setting", for: indexPath)

    cell.textLabel?.text = SETTINGS[indexPath.section][1][indexPath.row]
    cell.detailTextLabel?.text = nil

    if let user = user {
      switch indexPath.section {
      case 0:
        switch indexPath.row {
        case 0:
          let languageCode = UserDefaults.standard.string(forKey: prefLanguage) ?? LANGUAGES.first!.value
          cell.detailTextLabel?.text = ((LANGUAGES as NSDictionary).allKeys(for: languageCode) as! [String]).first
        default:
          break
        }
      case 1:
        switch indexPath.row {
        case 0:
          cell.detailTextLabel?.text = user.displayName
        case 1:
          cell.detailTextLabel?.text = user.email
        case 2:
          cell.detailTextLabel?.text = user.phoneNumber
        default:
          break
        }
      default:
        break
      }
    }

    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch indexPath.section {
    case 0:
      switch indexPath.row {
      case 0:
        handleLanguageButton()
      default:
        break
      }
    case 1:
      switch indexPath.row {
      case 0:
        handleNameButton()
      case 1:
        handleEmailButton()
      case 2:
        handleMobileButton()
      case 3:
        handlePasswordButton()
      default:
        break
      }
    default:
      break
    }
  }
}
