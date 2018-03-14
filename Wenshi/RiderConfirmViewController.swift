//
//  ConfirmViewController.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 12/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseAuth
import FirebaseDatabase
import GeoFire

class RiderConfirmViewController: UIViewController {
  @IBOutlet weak var pickUpAddressLabel: UILabel!
  @IBOutlet weak var dropOffAddressLabel: UILabel!
  @IBOutlet weak var serviceLabel: UILabel!
  @IBOutlet weak var carTypeLabel: UILabel!
  @IBOutlet weak var carModelLabel: UILabel!
  @IBOutlet weak var etaLabel: UILabel!
  @IBOutlet weak var distanceLabel: UILabel!
  @IBOutlet weak var paymentLabel: UILabel!
  @IBOutlet weak var fareLabel: UILabel!

  var pickUpLocation: CLLocation?
  var pickUpAddress: String?
  var dropOffLocation: CLLocation?
  var dropOffAddress: String?
  var service: String?
  var carType: String?
  var carModel: String?

  override func viewDidLoad() {
    super.viewDidLoad()

    pickUpAddressLabel.text = pickUpAddress
    dropOffAddressLabel.text = dropOffAddress
    serviceLabel.text = service
    carTypeLabel.text = carType
    carModelLabel.text = carModel
    paymentLabel.text = "Cash"

    if let pickUp = pickUpLocation, let dropOff = dropOffLocation {
      let distance = dropOff.distance(from: pickUp)
      etaLabel.text = durationString(distance * secondsPerMeter)
      distanceLabel.text = distanceString(distance)
      fareLabel.text = moneyString(distance * piastersPerMeter)
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let vc = segue.destination as? RiderRequestViewController,
      let data = sender as? [String: Any] {
      vc.location = data["location"] as? CLLocation
    }
  }

  @IBAction func handleSubmitButton() {
    presentLoader(view)
    if let location = pickUpLocation, let user = Auth.auth().currentUser {
      let ref = Database.database().reference(withPath: "Requests")
      let geoFire = GeoFire(firebaseRef: ref)
      geoFire.setLocation(location, forKey: user.uid) { _ in
        ref.child(user.uid).updateChildValues([
          "service": self.service!,
          "carType": self.carType!,
          "carModel": self.carModel!,
          "dropOff": self.dropOffLocation!.coordinate.latitudeAndLongitude
        ]) { (_, _) in
          dismissLoader()
          
          self.performSegue(withIdentifier: "submit", sender: [
            "location": location
          ])
        }
      }
    }
  }
}
