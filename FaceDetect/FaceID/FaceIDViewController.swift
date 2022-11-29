//
//  ViewController.swift
//  FaceDetect
//
//  Created by Vladimir Gorbunov on 11/24/22.
//

import UIKit

class FaceIDViewController: UIViewController {
    private lazy var faceDetectionService = FaceDetectionService()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let previewView = UIView(frame: .zero)
        view.addSubview(previewView)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        previewView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        previewView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        previewView.layoutIfNeeded()

        faceDetectionService.prepare(previewView: previewView, cameraPosition: .front) { [weak self] _ in
            self?.faceDetectionService.start()
        }
    }

    // Ensure that the interface stays locked in Portrait.
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }

    // Ensure that the interface stays locked in Portrait.
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { return .portrait }
}
