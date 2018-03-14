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

class RiderAcceptedViewController: UIViewController {
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var driverLabel: UILabel!
  @IBOutlet weak var etaLabel: UILabel!

  var requestData: [String: Any]?
  var driverData: [String: Any]?
  var firstUpdate = true
  var changeRef: DatabaseReference?

  override func viewDidLoad() {
    super.viewDidLoad()

    mapView.delegate = self

    guard let driverName = driverData?["name"] as? String else { return }

    driverLabel.text = driverName

    guard let driverId = requestData?["driverId"] as? String else { return }

    let ref = Database.database().reference(withPath: "DriversAvailable")
      .child(driverId)
    ref.observeSingleEvent(of: .value) { snapshot in
        self.updateMapView(snapshot)

        self.changeRef = ref
        ref.observe(.childChanged) { snapshot in
            self.updateMapView(snapshot)
        }
        ref.observeSingleEvent(of: .childRemoved) { snapshot in
          guard snapshot.key == "riderId" else { return }

          self.present(buildAlert(withTitle: "Canceled",
                                  message: "\(driverName) canceled the request.") { _ in
                         self.handleCancel()
                       },
                       animated: true)
        }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    if let ref = changeRef {
      ref.removeAllObservers()
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
      self.handleCancel()
    }))
    alert.addAction(UIAlertAction(title: "No", style: .cancel))
    present(alert, animated: true)
  }

  func updateMapView(_ snapshot: DataSnapshot) {
    guard let driverName = driverData?["name"] as? String else { return }

    if let data = snapshot.value as? [String: Any],
      let dl = data["l"] as? [CLLocationDegrees] {

      mapView.removeAnnotations(mapView.annotations)

      guard let rl = requestData?["l"] as? [CLLocationDegrees] else { return }
      let riderLocation = CLLocationCoordinate2D(latitude: rl[0], longitude: rl[1])
      let riderAnnotation = MKPointAnnotation()
      riderAnnotation.coordinate = riderLocation
      riderAnnotation.title = "You"
      mapView.addAnnotation(riderAnnotation)

      let driverLocation = CLLocationCoordinate2D(latitude: dl[0], longitude: dl[1])
      let driverAnnotation = MKPointAnnotation()
      driverAnnotation.coordinate = driverLocation
      driverAnnotation.title = driverName
      mapView.addAnnotation(driverAnnotation)

      mapView.showAnnotations(mapView.annotations, animated: true)

      let rider = CLLocation(latitude: riderLocation.latitude, longitude: riderLocation.longitude)
      let driver = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
      let distance = rider.distance(from: driver)
      etaLabel.text = durationString(distance * secondsPerMeter)

      if firstUpdate {
        overlayDirections(on: mapView, from: driver, to: rider)
        firstUpdate = false
      }
    }
  }

  func handleCancel() {
    guard let vc = self.presentingViewController as? RiderRequestViewController else { return }

    self.dismiss(animated: true) {
      vc.handleCancelButton()
    }
  }
}

extension RiderAcceptedViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    let renderer = MKPolylineRenderer(overlay: overlay)
    renderer.strokeColor = UIColor.black
    renderer.lineWidth = 4.0

    return renderer
  }
}
