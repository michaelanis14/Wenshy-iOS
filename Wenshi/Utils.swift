//
//  Utils.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 3/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import UIKit
import CoreLocation

var loader: UIActivityIndicatorView?
var geocoder = CLGeocoder()

func buildAlert(withTitle title: String, message: String, done: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
  let alert = UIAlertController(title: title,
                                message: message,
                                preferredStyle: .alert)
  alert.addAction(UIAlertAction(title: "OK",
                                style: .default,
                                handler: done))
  return alert
}

func presentLoader(_ view: UIView) {
  if loader == nil {
    let l = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
    l.activityIndicatorViewStyle = .whiteLarge;
    l.hidesWhenStopped = true
    l.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    l.clipsToBounds = true
    l.layer.cornerRadius = 3.0
    loader = l
  }

  if let l = loader {
    DispatchQueue.main.async {
      l.center = view.center
      view.addSubview(l)
      l.startAnimating()

      UIApplication.shared.beginIgnoringInteractionEvents()
    }
  }
}

func dismissLoader() {
  if let l = loader {
    DispatchQueue.main.async {
      l.stopAnimating()
      l.removeFromSuperview()

      UIApplication.shared.endIgnoringInteractionEvents()
    }
  }
}

func reverseGeocode(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completionHandler: ((String?) -> Void)?) {
  geocoder.cancelGeocode()
  let pickupLocation = CLLocation(latitude: latitude, longitude: longitude)
  geocoder.reverseGeocodeLocation(pickupLocation, completionHandler: { (placemarks, error) in
    if let _ = error { return }

    if let placemarks = placemarks, placemarks.count > 0 {
      completionHandler?(placemarks[0].compactAddress)
    }
  })
}
