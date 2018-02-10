//
//  ViewController.swift
//  Wenchy
//
//  Created by Ramy Aboul Naga on 20/12/2017.
//  Copyright © 2017 RaMin0. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SideMenu
import Firebase

class MainViewController: UIViewController {
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var myLocationButton: UIButton!

  var sideMenuManager = SideMenuManager.default
  var locationManager = CLLocationManager()
  var firstLocationUpdate = false

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

  @IBAction func handleRequestButton() {

  }
}

extension MainViewController: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let coordinate = manager.location?.coordinate {
      if !firstLocationUpdate {
        let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: false)

        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        mapView.addAnnotation(annotation)

        myLocationButton.isHidden = true

        firstLocationUpdate = true
      }
    }
  }
}

extension MainViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    for annotation in mapView.annotations {
      if let annotation = annotation as? MKPointAnnotation {
        annotation.coordinate = mapView.centerCoordinate
        myLocationButton.isHidden = false
      }
    }
  }
}

extension CLLocationCoordinate2D {
  func isEqual(_ coordinate: CLLocationCoordinate2D) -> Bool {
    return (fabs(self.latitude - coordinate.latitude) < .ulpOfOne) &&
      (fabs(self.longitude - coordinate.longitude) < .ulpOfOne)
  }
}
