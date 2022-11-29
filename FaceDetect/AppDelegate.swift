//
//  AppDelegate.swift
//  FaceDetect
//
//  Created by Vladimir Gorbunov on 11/24/22.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       
        self.window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = FaceIDViewController()
        window?.makeKeyAndVisible()
        
        return true
    }
}
