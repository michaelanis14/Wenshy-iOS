//
//  CLPlacemark+CompactAddress.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 11/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import CoreLocation

extension CLPlacemark {
  var compactAddress: String? {
    if let name = name {
      var result = name

//      if let street = thoroughfare {
//        result += ", \(street)"
//      }

      if let city = locality {
        result += ", \(city)"
      }

      if let country = country {
        result += ", \(country)"
      }

      return result
    }

    return nil
  }
}
