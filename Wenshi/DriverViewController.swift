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

class DriverViewController: UIViewController {
  var sideMenuManager = SideMenuManager.default
  var locationManager = CLLocationManager()

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
  }

  @IBAction func handleMenuButton() {
    present(self.sideMenuManager.menuLeftNavigationController!, animated: true)
  }
}

extension DriverViewController: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let location = manager.location {
      if let user = Auth.auth().currentUser {
        let ref = Database.database().reference(withPath: "DriversAvailable")
        let geoFire = GeoFire(firebaseRef: ref)
        geoFire.setLocation(location, forKey: user.uid)
      }
    }
  }
}

