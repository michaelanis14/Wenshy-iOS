//
//  Utils.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 3/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseDatabase

var loader: UIActivityIndicatorView?
var geocoder = CLGeocoder()

enum Role: String {
  case customer = "Customer"
  case driver = "Driver"
  case none = "None"
}

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

func call(_ mobile: String) {
  guard let mobileURL = URL(string: "tel://\(mobile)") else { return }
  if #available(iOS 10.0, *) {
    UIApplication.shared.open(mobileURL, options: [:], completionHandler: nil)
  } else {
    UIApplication.shared.openURL(mobileURL)
  }
}

func findUser(_ uid: String, completion: @escaping (DataSnapshot?, Role) -> Void) {
  Database.database().reference(withPath: "Users/Customers")
    .child(uid)
    .observeSingleEvent(of: .value) { (snapshot) in
      guard snapshot.exists() else {
        Database.database().reference(withPath: "Users/Drivers")
          .child(uid)
          .observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.exists() else {
              completion(nil, .none)
              return
            }
            completion(snapshot, .driver)
        }
        return
      }
      completion(snapshot, .customer)
  }
}

func after(_ seconds: Double, completion: @escaping () -> ()) {
  DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: completion)
}

func overlayDirections(on mapView: MKMapView, from source: CLLocation, to destination: CLLocation) {
  let sourceLocation = CLLocationCoordinate2D(latitude: source.coordinate.latitude,
                                              longitude: source.coordinate.longitude)
  let destinationLocation = CLLocationCoordinate2D(latitude: destination.coordinate.latitude,
                                                   longitude: destination.coordinate.longitude)

  let sourcePlacemark = MKPlacemark(coordinate: sourceLocation, addressDictionary: nil)
  let destinationPlacemark = MKPlacemark(coordinate: destinationLocation, addressDictionary: nil)

  let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
  let destinationMapItem = MKMapItem(placemark: destinationPlacemark)

  let directionRequest = MKDirectionsRequest()
  directionRequest.source = sourceMapItem
  directionRequest.destination = destinationMapItem
  directionRequest.transportType = .automobile

  let directions = MKDirections(request: directionRequest)
  directions.calculate { (response, _) in
    guard let response = response else { return }

    let route = response.routes[0]
    mapView.add(route.polyline, level: .aboveRoads)
  }
}

