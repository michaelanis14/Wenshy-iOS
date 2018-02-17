//
//  DismissSegue.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 17/2/2018.
//  Copyright © 2018 RaMin0 Development. All rights reserved.
//

import UIKit

class DismissSegue: UIStoryboardSegue {
  override func perform() {
    self.source.presentingViewController?.dismiss(animated: true, completion: nil)
  }
}
