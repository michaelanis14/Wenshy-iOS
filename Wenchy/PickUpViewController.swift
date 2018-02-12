//
//  PickUpViewController.swift
//  Wenchy
//
//  Created by Ramy Aboul Naga on 20/12/2017.
//  Copyright © 2017 RaMin0. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SideMenu

class PickUpViewController: UIViewController {
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var myLocationButton: UIButton!
  @IBOutlet weak var pickUpAddressLabel: UILabel!

  var sideMenuManager = SideMenuManager.default
  var locationManager = CLLocationManager()
  var firstLocationUpdate = false
  var selectedService: String?

  let SERVICES = [
    "Accident",
    "Car Broke-down"
  ]

  override func viewDidLoad() {
    super.viewDidLoad()

    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()

    sideMenuManager.menuPresentMode = .menuSlideIn
    sideMenuManager.menuFadeStatusBar = false
    let menuLeftNavigationController = storyboard!.instantiateViewController(withIdentifier: "SideMenuNavigationController") as! UISideMenuNavigationController
    sideMenuManager.menuLeftNavigationController = menuLeftNavigationController
    // self.sideMenuManager.menuAddPanGestureToPresent(toView: viewController.view)
    sideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: view, forMenu: .left)

    mapView.delegate = self
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let vc = segue.destination as? DropOffViewController,
      let requestData = sender as? [String: Any] {
      vc.service = requestData["service"] as? String
      vc.pickUpLocation = CLLocation(latitude: mapView.centerCoordinate.latitude,
                                     longitude: mapView.centerCoordinate.longitude)
      vc.pickUpAddress = pickUpAddressLabel.text
    }
  }

  @IBAction func handleMenuButton() {
    present(self.sideMenuManager.menuLeftNavigationController!, animated: true)
  }

  @IBAction func handleMyLocationButton() {
    if let location = mapView.userLocation.location {
      firstLocationUpdate = false
      locationManager(locationManager, didUpdateLocations: [location])
      myLocationButton.isHidden = true
    }
  }

  @IBAction func handleChooseServiceButton() {
    let alert = UIAlertController(title: "Choose Service", message: nil, preferredStyle: .actionSheet)
    for service in SERVICES {
      alert.addAction(UIAlertAction(title: service, style: .default, handler: { action in
        if let service = action.title {
          self.performSegue(withIdentifier: "request", sender: [
            "service": service
          ])
        }
      }))
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(alert, animated: true)
  }
}

extension PickUpViewController: CLLocationManagerDelegate {
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
                        self.pickUpAddressLabel.text = address
        })

        myLocationButton.isHidden = true

        firstLocationUpdate = true
      }
    }
  }
}

extension PickUpViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    for annotation in mapView.annotations {
      if let annotation = annotation as? MKPointAnnotation {
        annotation.coordinate = mapView.centerCoordinate

        reverseGeocode(latitude: mapView.centerCoordinate.latitude,
                       longitude: mapView.centerCoordinate.longitude,
                       completionHandler: { address in
                        self.pickUpAddressLabel.text = address
        })

        myLocationButton.isHidden = false
      }
    }
  }
}
