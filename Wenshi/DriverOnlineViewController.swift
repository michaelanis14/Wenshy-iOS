//
//  DriverViewController.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 10/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SideMenu
import FirebaseAuth
import FirebaseDatabase
import GeoFire

class DriverOnlineViewController: UIViewController {
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var onlineSwitch: UISwitch!

  var sideMenuManager = SideMenuManager.default
  var locationManager = CLLocationManager()
  var driverLocation: CLLocation?

  override func viewDidLoad() {
    super.viewDidLoad()

    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.requestWhenInUseAuthorization()

    sideMenuManager.menuPresentMode = .menuSlideIn
    sideMenuManager.menuFadeStatusBar = false
    let menuLeftNavigationController = storyboard!.instantiateViewController(withIdentifier: "SideMenuNavigationController") as! UISideMenuNavigationController
    sideMenuManager.menuLeftNavigationController = menuLeftNavigationController
    // self.sideMenuManager.menuAddPanGestureToPresent(toView: viewController.view)
    sideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: view, forMenu: .left)
  }

  override func viewDidAppear(_ animated: Bool) {
    guard let user = Auth.auth().currentUser else { return }

    Database.database().reference(withPath: "DriversAvailable")
      .child(user.uid)
      .observe(.childAdded) { snapshot in
        if snapshot.key == "riderId", let riderId = snapshot.value as? String {
          Database.database().reference(withPath: "Users/Customers")
            .child(riderId)
            .observeSingleEvent(of: .value) { (snapshot, error) in
              if let riderData = snapshot.value as? [String: Any] {
                self.handleRequest(riderId, riderData)
              }
          }
        }
      }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let vc = segue.destination as? DriverAcceptedViewController,
      let data = sender as? [String: Any] {
      vc.riderId = data["riderId"] as? String
      vc.riderData = data["riderData"] as? [String: Any]
      vc.requestData = data["requestData"] as? [String: Any]
      vc.driverLocation = data["driverLocation"] as? CLLocation
    }
  }

  @IBAction func handleMenuButton() {
    present(self.sideMenuManager.menuLeftNavigationController!, animated: true)
  }

  @IBAction func handleOnlineSwitch() {
    if onlineSwitch.isOn {
      locationManager.startUpdatingLocation()
      mapView.showsUserLocation = true
    } else {
      locationManager.stopUpdatingLocation()
      mapView.showsUserLocation = false

      if let user = Auth.auth().currentUser {
        let ref = Database.database().reference(withPath: "DriversAvailable")
        let geoFire = GeoFire(firebaseRef: ref)
        geoFire.removeKey(user.uid)
      }
    }
  }

  func handleRequest(_ riderId: String, _ riderData: [String: Any]) {
    guard let user = Auth.auth().currentUser,
      let riderName = riderData["name"] as? String,
      let carType = riderData["carType"] as? String,
      let carModel = riderData["carModel"] as? String else { return }

    let alert = UIAlertController(title: "New Request",
                                  message: "Customer: \(riderName)\nCar Type: \(carType)\nCar Model: \(carModel)",
                                  preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Accept",
                                  style: .default,
                                  handler: { _ in
      presentLoader(self.view)
      let request = Database.database().reference(withPath: "Requests")
        .child(riderId)
      request.observeSingleEvent(of: .value, with: { snapshot in
        if let requestData = snapshot.value as? [String: Any] {
          request.updateChildValues(["driverId": user.uid]) { (_,_) in
            dismissLoader()
            self.performSegue(withIdentifier: "accept", sender: [
              "riderId": riderId,
              "riderData": riderData,
              "requestData": requestData,
              "driverLocation": self.driverLocation as Any
            ])
          }
        }
      })
    }))
    alert.addAction(UIAlertAction(title: "Cancel",
                                  style: .cancel))
    self.present(alert, animated: true) {
      Database.database().reference(withPath: "DriversAvailable")
        .child(user.uid)
        .observeSingleEvent(of: .childRemoved) { snapshot in
          if snapshot.key == "riderId" && snapshot.value as! String == riderId {
            alert.dismiss(animated: true)
          }
      }
    }
  }
}

extension DriverOnlineViewController: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let location = manager.location {
      let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
      let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
      mapView.setRegion(region, animated: false)

      if let user = Auth.auth().currentUser {
        let ref = Database.database().reference(withPath: "DriversAvailable")
        let geoFire = GeoFire(firebaseRef: ref)
        geoFire.setLocation(location, forKey: user.uid)
        driverLocation = location
      }
    }
  }
}
