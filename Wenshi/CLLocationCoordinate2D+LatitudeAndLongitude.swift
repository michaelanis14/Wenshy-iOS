//
//  CLLocationCoordinate2D+LatitudeAndLongitude.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 17/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D {
  var latitudeAndLongitude: [CLLocationDegrees] {
    return [latitude, longitude]
  }
}
