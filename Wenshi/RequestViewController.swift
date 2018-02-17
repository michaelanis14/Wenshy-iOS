//
//  RequestViewController.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 17/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class RequestViewController: UIViewController {
  override func viewDidAppear(_ animated: Bool) {
    if let user = Auth.auth().currentUser {
      Database.database().reference(withPath: "Requests")
        .queryOrderedByKey()
        .queryEqual(toValue: user.uid)
        .observeSingleEvent(of: .childChanged) { snapshot in
          guard let requestData = snapshot.value as? [String: Any] else { return }

          if let driverID = requestData["driverID"] as? String {
            Database.database().reference(withPath: "Users/Drivers")
              .child(driverID)
              .observeSingleEvent(of: .value) { snapshot in
                if let userData = snapshot.value as? [String: Any] {
                  self.handleRequestAccepted(requestData, by: userData)
                }
              }
          }
      }
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let vc = segue.destination as? AcceptedViewController,
      let data = sender as? [String: Any],
      let requestData = data["request"] as? [String: Any],
      let driverData = data["driver"] as? [String: Any] {
      vc.requestData = requestData
      vc.driverData = driverData
    }
  }

  @IBAction func handleCancelButton() {
    presentLoader(view)
    if let user = Auth.auth().currentUser {
      Database.database().reference(withPath: "Requests")
        .child(user.uid).removeValue() { (_, _) in
          dismissLoader()
          
          self.dismiss(animated: true)
      }
    }
  }

  func handleRequestAccepted(_ requestData: [String: Any], by driverData: [String: Any]) {
    if let driverName = driverData["name"] as? String {
      self.present(buildAlert(withTitle: "Accepted",
                              message: "\(driverName) accepted your request.") { _ in
                                self.performSegue(withIdentifier: "accepted", sender: [
                                  "request": requestData,
                                  "driver": driverData
                                ])
                   },
                   animated: true)
    }
  }
}
