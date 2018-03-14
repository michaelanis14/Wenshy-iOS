//
//  DriverAcceptedViewController.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 7/3/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import UIKit
import MapKit
import FirebaseAuth
import FirebaseDatabase

class DriverAcceptedViewController: UIViewController {
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var riderLabel: UILabel!
  @IBOutlet weak var etaLabel: UILabel!

  var riderId: String?
  var riderData: [String: Any]?
  var requestData: [String: Any]?
  var driverLocation: CLLocation?

  override func viewDidLoad() {
    super.viewDidLoad()

    mapView.delegate = self

    riderLabel.text = riderData?["name"] as? String

    updateMapView()
  }

  override func viewDidAppear(_ animated: Bool) {
    guard let driverId = Auth.auth().currentUser?.uid,
      let riderName = riderData?["name"] as? String else { return }

    Database.database().reference(withPath: "DriversAvailable")
      .child(driverId)
      .observeSingleEvent(of: .childRemoved) { snapshot in
        guard snapshot.key == "riderId" else { return }

        self.present(buildAlert(withTitle: "Canceled",
                                message: "\(riderName) canceled the request.") { _ in
                                  self.dismiss(animated: true)
          },
                     animated: true)
      }
  }

  @IBAction func handleCallRiderButton() {
    if let mobile = riderData?["mobile"] as? String {
      call(mobile)
    }
  }

  @IBAction func handleCancelButton() {
    let alert = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
      guard let driverId = Auth.auth().currentUser?.uid else { return }

      presentLoader(self.view)
      Database.database().reference(withPath: "DriversAvailable")
        .child(driverId)
        .child("riderId")
        .removeValue() { (_, _) in
          dismissLoader()
          self.dismiss(animated: true)
      }
    }))
    alert.addAction(UIAlertAction(title: "No", style: .cancel))
    present(alert, animated: true)
  }

  func updateMapView() {
    guard let riderName = riderData?["name"] as? String else { return }

    guard let rl = requestData?["l"] as? [CLLocationDegrees] else { return }
    let riderLocation = CLLocationCoordinate2D(latitude: rl[0], longitude: rl[1])
    let riderAnnotation = MKPointAnnotation()
    riderAnnotation.coordinate = riderLocation
    riderAnnotation.title = riderName
    mapView.addAnnotation(riderAnnotation)

    guard let dl = driverLocation else { return }
    let driverLocation2 = CLLocationCoordinate2D(latitude: dl.coordinate.latitude,
                                                 longitude: dl.coordinate.longitude)
    let driverAnnotation = MKPointAnnotation()
    driverAnnotation.coordinate = driverLocation2
    driverAnnotation.title = "You"
    mapView.addAnnotation(driverAnnotation)

    mapView.showAnnotations(mapView.annotations, animated: true)

    let rider = CLLocation(latitude: riderLocation.latitude, longitude: riderLocation.longitude)
    let driver = CLLocation(latitude: driverLocation2.latitude, longitude: driverLocation2.longitude)
    let distance = rider.distance(from: driver)
    etaLabel.text = durationString(distance * secondsPerMeter)

    overlayDirections(on: mapView, from: driver, to: rider)
  }
}

extension DriverAcceptedViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    let renderer = MKPolylineRenderer(overlay: overlay)
    renderer.strokeColor = UIColor.black
    renderer.lineWidth = 4.0

    return renderer
  }
}
