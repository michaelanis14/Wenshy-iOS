//
//  DropOffViewController.swift
//  Wenchy
//
//  Created by Ramy Aboul Naga on 11/2/2018.
//  Copyright © 2018 RaMin0. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Firebase

class DropOffViewController: UIViewController {
  @IBOutlet weak var pickUpAddressLabel: UILabel!
  @IBOutlet weak var dropOffAddressLabel: UILabel!
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var myLocationButton: UIButton!
  @IBOutlet weak var serviceLabel: UILabel!
  @IBOutlet weak var carTypeLabel: UILabel!
  @IBOutlet weak var carModelLabel: UILabel!
  
  var service: String?
  var pickUpLocation: CLLocation?
  var pickUpAddress: String?

  var locationManager = CLLocationManager()
  var firstLocationUpdate = false

  override func viewDidLoad() {
    super.viewDidLoad()

    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()

    mapView.delegate = self

    pickUpAddressLabel.text = pickUpAddress
    serviceLabel.text = service

    if let user = Auth.auth().currentUser {
      Database.database().reference(withPath: "Users/Customers")
        .child(user.uid)
        .observeSingleEvent(of: .value) { snapshot in
          guard snapshot.exists() else { return }

          if let userData = snapshot.value as? [String: Any] {
            self.carTypeLabel.text = userData["carType"] as? String
            self.carModelLabel.text = userData["carModel"] as? String
          }
      }
    }
  }

  @IBAction func handleMyLocationButton() {
    if let location = mapView.userLocation.location {
      firstLocationUpdate = false
      locationManager(locationManager, didUpdateLocations: [location])
      myLocationButton.isHidden = true
    }
  }

  @IBAction func handleConfirmDropOffButton() {
    
  }
}

extension DropOffViewController: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let coordinate = manager.location?.coordinate {
      if !firstLocationUpdate {
        let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: false)

        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        mapView.addAnnotation(annotation)

        reverseGeocode(latitude: coordinate.latitude,
                       longitude: coordinate.longitude,
                       completionHandler: { address in
                        self.dropOffAddressLabel.text = address
        })

        myLocationButton.isHidden = true

        firstLocationUpdate = true
      }
    }
  }
}

extension DropOffViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    for annotation in mapView.annotations {
      if let annotation = annotation as? MKPointAnnotation {
        annotation.coordinate = mapView.centerCoordinate

        reverseGeocode(latitude: mapView.centerCoordinate.latitude,
                       longitude: mapView.centerCoordinate.longitude,
                       completionHandler: { address in
                        self.dropOffAddressLabel.text = address
        })

        myLocationButton.isHidden = false
      }
    }
  }
}
