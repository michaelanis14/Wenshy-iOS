//
//  RequestViewController.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 17/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import CoreLocation
import GeoFire

class RiderRequestViewController: UIViewController {
  var location: CLLocation?
  var geoFireQuery: GFCircleQuery?
  var nearbyDrivers = NSMutableOrderedSet()
  var nearbyDriversLocations: [String: CLLocation] = [:]
  var requesting = false
  var accepted = false
  var timer: Timer?
  var nearbyDriver: String?

  override func viewDidAppear(_ animated: Bool) {
    if let user = Auth.auth().currentUser {
      Database.database().reference(withPath: "Requests")
        .queryOrderedByKey()
        .queryEqual(toValue: user.uid)
        .observeSingleEvent(of: .childChanged) { snapshot in
          guard let requestData = snapshot.value as? [String: Any] else { return }

          if let driverId = requestData["driverId"] as? String {
            Database.database().reference(withPath: "Users/Drivers")
              .child(driverId)
              .observeSingleEvent(of: .value) { snapshot in
                if let userData = snapshot.value as? [String: Any] {
                  self.handleRequestAccepted(requestData, by: userData)
                }
              }
          }
      }

      if let location = location {
        let ref = Database.database().reference(withPath: "DriversAvailable")
        let geoFire = GeoFire(firebaseRef: ref)
        geoFireQuery = geoFire.query(at: location, withRadius: driverRange)
        geoFireQuery?.observe(.keyEntered, with: { (key, location) in
          Database.database().reference(withPath: "DriversAvailable")
            .child(key)
            .observeSingleEvent(of: .value, with: { snapshot in
              if let data = snapshot.value as? [String: Any] {
                guard let _ = data["riderId"] else {
                  self.nearbyDrivers.add(key)
                  self.nearbyDriversLocations[key] = location

                  if !self.requesting {
                    self.request()
                  }

                  return
                }
              }
            })
        })
        geoFireQuery?.observe(.keyExited, with: { (key, location) in
          self.nearbyDrivers.remove(key)
          self.nearbyDriversLocations[key] = nil
        })
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    geoFireQuery?.removeAllObservers()
    timer?.invalidate()

    if !accepted {
      freeNearbyDriver()
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let vc = segue.destination as? RiderAcceptedViewController,
      let data = sender as? [String: Any],
      let requestData = data["request"] as? [String: Any],
      let driverData = data["driver"] as? [String: Any] {
      vc.requestData = requestData
      vc.driverData = driverData
    }
  }

  @IBAction func handleCancelButton() {
    freeNearbyDriver()
    
    if let user = Auth.auth().currentUser {
      Database.database().reference(withPath: "Requests")
        .child(user.uid).removeValue() { (_, _) in
          self.dismiss(animated: true)
      }
    }
  }

  func request() {
    guard let location = location else { return }

    requesting = true

    nearbyDrivers.sort(comparator: { (a, b) in
      if let d2a = nearbyDriversLocations[a as! String]?.distance(from: location),
        let d2b = nearbyDriversLocations[b as! String]?.distance(from: location) {
        return d2a < d2b ? .orderedAscending : .orderedDescending
      }
      return .orderedSame
    })

    guard let nearbyDriver = nearbyDrivers.firstObject as? String,
      let user = Auth.auth().currentUser else {
      requesting = false
      return
    }

    self.nearbyDriver = nearbyDriver

    Database.database().reference(withPath: "DriversAvailable")
      .child(nearbyDriver)
      .updateChildValues(["riderId": user.uid])

    timer = Timer.scheduledTimer(timeInterval: requestWait,
                                 target: self,
                                 selector: #selector(requestNext),
                                 userInfo: nil,
                                 repeats: false)
  }

  @objc func requestNext() {
    if accepted { return }

    guard let nearbyDriver = nearbyDriver else { return }

    nearbyDrivers.remove(nearbyDriver)
    nearbyDriversLocations[nearbyDriver] = nil

    freeNearbyDriver()

    request()
  }

  func freeNearbyDriver() {
    guard let nearbyDriver = nearbyDriver else { return }

    Database.database().reference(withPath: "DriversAvailable")
      .child(nearbyDriver)
      .child("riderId")
      .removeValue()
  }

  func handleRequestAccepted(_ requestData: [String: Any], by driverData: [String: Any]) {
    accepted = true

    if let driverName = driverData["name"] as? String {
      self.present(buildAlert(withTitle: "Accepted",
                              message: "\(driverName) accepted your request.") { _ in
                                self.performSegue(withIdentifier: "accepted", sender: [
                                  "request": requestData,
                                  "driver": driverData
                                ])
                   },
                   animated: true)
    }
  }
}
