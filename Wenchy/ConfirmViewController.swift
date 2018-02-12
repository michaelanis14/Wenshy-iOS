//
//  ConfirmViewController.swift
//  Wenchy
//
//  Created by Ramy Aboul Naga on 12/2/2018.
//  Copyright © 2018 RaMin0. All rights reserved.
//

import UIKit
import CoreLocation

class ConfirmViewController: UIViewController {
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
  var piastersPerMeter = 0.5 // 5 EGP/Km
  var secondsPerMeter = 0.09 // 40 Km/Hour

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
}
