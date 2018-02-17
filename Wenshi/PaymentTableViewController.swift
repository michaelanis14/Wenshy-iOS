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

class PaymentTableViewController: UITableViewController {
  var cards: [(pan: String, type: String, token: String)] = []
  var selectedPayment = "cash"

  override func viewDidLoad() {
    super.viewDidLoad()

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

  @IBAction func handleDoneButton() {
    dismiss(animated: true, completion: nil)
  }
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
