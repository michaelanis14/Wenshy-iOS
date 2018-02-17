//
//  SettingsViewController.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 28/12/2017.
//  Copyright © 2017 RaMin0 Development. All rights reserved.
//

import UIKit
import AcceptSDK
import FirebaseAuth
import FirebaseDatabase

class SettingsViewController: UIViewController {
  let accept = AcceptSDK()

  override func viewDidLoad() {
    accept.delegate = self
  }

  @IBAction func handleSaveButton() {
    presentLoader(view)
    PayMobApi.getPaymentKey(for: 5000) { (paymentKey, error) in
      dismissLoader()

      if let error = error {
        self.present(buildAlert(withTitle: "Error",
                                message: error.localizedDescription),
                     animated: true)
        return
      }

      guard let paymentKey = paymentKey else { return }

      do {
        try self.accept.presentPayVC(vC: self,
                                     billingData: ["email": "test@accou.nt"],
                                     paymentKey: paymentKey,
                                     saveCardDefault: true,
                                     showSaveCard: true,
                                     showAlerts: false,
                                     token: nil,
                                     maskedPanNumber: nil,
                                     buttonsColor: UIColor.black)
      } catch (let error) {
        self.present(buildAlert(withTitle: "Error",
                                message: error.localizedDescription),
                     animated: true)
      }
    }
  }

  func handlePayment(pay: PayResponse, savedCard: SaveCardResponse? = nil) {
    if let savedCard = savedCard {
      if let user = Auth.auth().currentUser {
        let userRef = Database.database().reference(withPath: "Users/Customers")
          .child(user.uid)
        userRef.child("cards").child(savedCard.token).setValue([
            "pan": savedCard.masked_pan.split(separator: "-")[3],
            "type": savedCard.card_subtype
        ]) { (_, _) in
          userRef.child("payment").setValue(savedCard.token)
        }
      }
    }

    dismiss(animated: true, completion: nil)
  }
}

extension SettingsViewController: AcceptSDKDelegate {
  func userDidCancel() {}

  func paymentAttemptFailed(_ error: AcceptSDKError, detailedDescription: String) {
    self.present(buildAlert(withTitle: "Error",
                            message: detailedDescription),
                 animated: true)
  }

  func transactionRejected(_ payData: PayResponse) {
    self.present(buildAlert(withTitle: "Error",
                            message: payData.dataMessage),
                 animated: true)
  }

  func transactionAccepted(_ payData: PayResponse) {
    handlePayment(pay: payData)
  }

  func transactionAccepted(_ payData: PayResponse, savedCardData: SaveCardResponse) {
    handlePayment(pay: payData, savedCard: savedCardData)
  }

  func userDidCancel3dSecurePayment(_ pendingPayData: PayResponse) {}
}
