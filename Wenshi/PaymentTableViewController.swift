//
//  PaymentTableViewController.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 17/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import AcceptSDK

class PaymentTableViewController: UITableViewController {
  #if IOS
  let accept = AcceptSDK()
  #endif
  var cards: [(pan: String, type: String, token: String)] = []
  var selectedPayment = "cash"

  override func viewDidLoad() {
    super.viewDidLoad()

    #if IOS
    accept.delegate = self
    #endif

    if let user = Auth.auth().currentUser {
      let userRef = Database.database().reference(withPath: "Users/Customers")
        .child(user.uid)

      userRef.child("payment")
        .observe(.value) { snapshot in
          guard let payment = snapshot.value as? String else { return }

          self.selectedPayment = payment
          self.tableView.reloadData()
        }

      userRef.child("cards")
        .observe(.childAdded) { snapshot in
          guard let card = snapshot.value as? [String: Any] else { return }

          if let pan = card["pan"] as? String,
            let type = card["type"] as? String {
            self.cards.append((pan: pan, type: type, token: snapshot.key))
            self.tableView.reloadData()
          }
        }
    }
  }

  @IBAction func handleAddButton() {
    #if SIMULATOR
      self.present(buildAlert(withTitle: "Error",
                              message: "Payments not supported on Simulator"),
                   animated: true)
    #else
    presentLoader(view)
    PayMobApi.getPaymentKey(for: 100) { (paymentKey, error) in
      dismissLoader()

      if let error = error {
        self.present(buildAlert(withTitle: "Error",
                                message: error.localizedDescription),
                     animated: true)
        return
      }

      guard let paymentKey = paymentKey else { return }

      guard let user = Auth.auth().currentUser, let email = user.email else { return }

      do {
        try self.accept.presentPayVC(vC: self,
                                     billingData: ["email": email],
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
    #endif
  }

  @IBAction func handleDoneButton() {
    dismiss(animated: true, completion: nil)
  }

  #if IOS
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
  }
  #endif
}

extension PaymentTableViewController {
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return cards.count + 1
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "paymentCard", for: indexPath)

    if indexPath.row == cards.count {
      cell.textLabel?.text = "Cash"
      cell.accessoryType = selectedPayment == "cash" ? .checkmark : .none
    } else {
      let card = cards[indexPath.row]
      cell.textLabel?.text = "xxxx xxxx xxxx \(card.pan) (\(card.type))"
      cell.accessoryType = card.token == selectedPayment ? .checkmark : .none
    }

    return cell
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    guard editingStyle == .delete else { return }

    let card = cards[indexPath.row]
    if let user = Auth.auth().currentUser {
      let userRef = Database.database().reference(withPath: "Users/Customers")
        .child(user.uid)
      userRef.child("cards")
        .child(card.token)
        .removeValue { (_, _) in
          self.cards.remove(at: indexPath.row)
          self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }

      guard selectedPayment == card.token else { return }

      userRef.child("payment").setValue("cash")
    }
  }

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return indexPath.row < cards.count
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let payment = indexPath.row < cards.count ? cards[indexPath.row].token : "cash"
    
    if let user = Auth.auth().currentUser {
      Database.database().reference(withPath: "Users/Customers")
        .child(user.uid)
        .updateChildValues(["payment": payment])
    }
  }
}

#if IOS
extension PaymentTableViewController: AcceptSDKDelegate {
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
#endif
