//
//  PayMobApi.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 16/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import Foundation
import JSONRequest

class PayMobApi {
  static let BASE_URL = "https://accept.paymobsolutions.com/api"

  static var token: String?
  static var integrationID: String?

  enum Routes: String {
    case acceptancePaymentKeys = "acceptance/payment_keys"
  }

  static func initialize(token: String, integrationID: String) {
    self.token = token
    self.integrationID = integrationID
  }

  static func getPaymentKey(for amount: Int, in currency: String = "EGP", completion: ((String?, Error?) -> Void)?) {
    JSONRequest.post(url: "\(BASE_URL)/\(Routes.acceptancePaymentKeys.rawValue)",
      queryParams: [
        "token": token!
      ],
      payload: [
        "integration_id": self.integrationID!,
        "amount_cents": amount,
        "currency": currency
      ],
      headers: nil) { result in
        guard let completion = completion else { return }

        switch result {
        case .success(let data):
          if let data = data.data as? [String: Any] {
            let key = data["token"] as? String
            completion(key, nil)
          }
        case .failure(let error):
          completion(nil, error.error)
        }
    }
  }
}
