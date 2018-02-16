//
//  Helpers.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 12/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import PhoneNumberKit

func distanceString(_ distance: CLLocationDistance) -> String {
  let formatter = MKDistanceFormatter()
  return formatter.string(fromDistance: distance)
}

func moneyString(_ money: Double) -> String {
  return String(format: "EGP %.2f", money / 100)
}

func durationString(_ duration: Double) -> String {
  let formatter = DateComponentsFormatter()
  formatter.allowedUnits = [.hour, .minute]
  formatter.maximumUnitCount = 1
  formatter.unitsStyle = .full
  return formatter.string(from: TimeInterval(duration))!
}

func sanitizeMobile(_ mobile: String) -> String {
  var sanitizedMobile = ""
  do {
    let phoneNumberKit = PhoneNumberKit()
    let parsedMobile = try phoneNumberKit.parse(mobile)
    sanitizedMobile = phoneNumberKit.format(parsedMobile, toType: .e164)
  } catch {}
  return sanitizedMobile
}
