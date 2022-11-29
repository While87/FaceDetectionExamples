//
//  Helpers.swift
//  FaceDetect
//
//  Created by Vladimir Gorbunov on 11/24/22.
//

//import CoreGraphics

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

extension CGSize {
    var cgPoint: CGPoint { return CGPoint(x: width, y: height) }
}

extension CGPoint {
    var cgSize: CGSize { return CGSize(width: x, height: y) }

    func absolutePoint(in rect: CGRect) -> CGPoint {
        return CGPoint(x: x * rect.size.width, y: y * rect.size.height) + rect.origin
    }
}

import UIKit

extension UIApplication {
    private class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }

    class var topViewController: UIViewController? { return topViewController() }
}
