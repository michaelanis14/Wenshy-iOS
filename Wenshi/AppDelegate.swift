//
//  AppDelegate.swift
//  Wenshi
//
//  Created by Ramy Aboul Naga on 20/12/2017.
//  Copyright © 2017 RaMin0 Development. All rights reserved.
//

import UIKit
import Firebase
import IQKeyboardManagerSwift
import FacebookCore
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    /**
     * KeyboardManager
     */
    let keyboardManager = IQKeyboardManager.sharedManager()
    keyboardManager.enable = true
    keyboardManager.shouldShowToolbarPlaceholder = false
    // keyboardManager.toolbarDoneBarButtonItemText = ""
    keyboardManager.toolbarTintColor = UIView().tintColor

    /**
     * Firebase
     */
    FirebaseApp.configure()

    /**
     * Facebook
     */
    SDKApplicationDelegate.shared.application(application,
                                              didFinishLaunchingWithOptions: launchOptions)

    /**
     * Google
     */
    GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID

    return true
  }

  @available(iOS 9.0, *)
  func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    var handled = false

    /**
     * Facebook
     */
    handled = handled || SDKApplicationDelegate.shared
      .application(application,
                   open: url,
                   sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                   annotation: options[UIApplicationOpenURLOptionsKey.annotation] as Any)

    /**
     * Google
     */
    handled = handled || GIDSignIn.sharedInstance()
      .handle(url,
              sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
              annotation: [:])

    return handled
  }

  func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    var handled = false

    /**
     * Facebook
     */
    handled = handled || SDKApplicationDelegate.shared
      .application(application,
                   open: url,
                   sourceApplication: sourceApplication,
                   annotation: annotation)

    /**
     * Google
     */
    handled = handled || GIDSignIn.sharedInstance()
      .handle(url,
              sourceApplication: sourceApplication,
              annotation: annotation)

    return handled
  }
}
