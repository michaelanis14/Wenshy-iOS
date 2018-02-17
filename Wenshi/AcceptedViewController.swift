//
//  AcceptedViewController.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 17/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import FirebaseDatabase

class AcceptedViewController: UIViewController {
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var driverLabel: UILabel!
  @IBOutlet weak var etaLabel: UILabel!

  var requestData: [String: Any]?
  var driverData: [String: Any]?

  override func viewDidLoad() {
    super.viewDidLoad()

    driverLabel.text = driverData?["name"] as? String

    guard let driverID = requestData?["driverID"] as? String else { return }

    Database.database().reference(withPath: "DriversAvailable")
      .child(driverID)
      .observeSingleEvent(of: .value) { snapshot in
        self.updateMapView(snapshot)

        Database.database().reference(withPath: "DriversAvailable")
          .queryOrderedByKey()
          .queryEqual(toValue: driverID)
          .observe(.childChanged) { snapshot in
            self.updateMapView(snapshot)
        }
    }
  }

  @IBAction func handleCallDriverButton() {
    if let mobile = driverData?["mobile"] as? String {
      call(mobile)
    }
  }
  
  @IBAction func handleCancelButton() {
    let alert = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { action in
      guard let vc = self.presentingViewController as? RequestViewController else { return }

      self.dismiss(animated: true) {
        vc.handleCancelButton()
      }
    }))
    alert.addAction(UIAlertAction(title: "No", style: .cancel))
    present(alert, animated: true)
  }

  func updateMapView(_ snapshot: DataSnapshot) {
    guard let l = requestData?["l"] as? [CLLocationDegrees] else { return }
    let riderLocation = CLLocationCoordinate2D(latitude: l[0], longitude: l[1])

    guard let driverName = driverData?["name"] as? String else { return }

    if let data = snapshot.value as? [String: Any],
      let l = data["l"] as? [CLLocationDegrees],
      l.count == 2 {
      mapView.removeAnnotations(mapView.annotations)

      let driverLocation = CLLocationCoordinate2D(latitude: l[0], longitude: l[1])
      let annotation = MKPointAnnotation()
      annotation.coordinate = driverLocation
      annotation.title = driverName
      mapView.addAnnotation(annotation)

      mapView.showAnnotations(mapView.annotations, animated: true)

      let rider = CLLocation(latitude: riderLocation.latitude, longitude: riderLocation.longitude)
      let driver = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
      let distance = rider.distance(from: driver)
      etaLabel.text = durationString(distance * secondsPerMeter)
    }
  }
}


