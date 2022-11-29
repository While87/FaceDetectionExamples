//
//  FaceView.swift
//  FaceDetect
//
//  Created by Vladimir Gorbunov on 11/24/22.
//

import UIKit
import Vision
import AVFoundation

class FaceFrameView: UIView {
    private var boundingBox = CGRect.zero

    func clearAndSetNeedsDisplay() {
        boundingBox = .zero
        DispatchQueue.main.async { [weak self] in self?.setNeedsDisplay() }
    }

    private func drawElement(context: CGContext, points: [CGPoint], needToClosePath: Bool) {
        if !points.isEmpty {
            context.addLines(between: points)
            if needToClosePath { context.closePath() }
            context.strokePath()
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        defer { context.restoreGState()}

        context.addRect(boundingBox)
        UIColor.red.setStroke()
        context.strokePath()

        UIColor.white.setStroke()
    }

    func read(result: VNFaceObservation, previewLayer: AVCaptureVideoPreviewLayer) {
        defer { DispatchQueue.main.async { [weak self] in self?.setNeedsDisplay() } }

        let rect = result.boundingBox
        let origin = previewLayer.layerPointConverted(fromCaptureDevicePoint: rect.origin)
        let size = previewLayer.layerPointConverted(fromCaptureDevicePoint: rect.size.cgPoint).cgSize
        boundingBox = CGRect(origin: origin, size: size)
    }
}
