//
//  CanvasViewController.swift
//  DrawNotes
//
//  Created by Arkaprava Ghosh on 24/04/25.
//

import UIKit
import SwiftUI
import PencilKit

class CanvasViewController: UIViewController, PKToolPickerObserver, PKCanvasViewDelegate, UIScrollViewDelegate {
    var canvasView: PKCanvasView!
    let scrollView = UIScrollView()
    let toolPicker = PKToolPicker()

    var contentSize = CGSize(width: 2000, height: 2000)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        canvasView = PKCanvasView()

        // Configure ScrollView
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.backgroundColor = .white
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.bouncesZoom = true
        view.addSubview(scrollView)

        // Configure CanvasView
        canvasView.frame = CGRect(origin: .zero, size: contentSize)
        canvasView.backgroundColor = .white
        canvasView.drawingPolicy = .pencilOnly
        canvasView.delegate = self
        canvasView.contentSize = contentSize
        canvasView.becomeFirstResponder()

        canvasView.minimumZoomScale = scrollView.minimumZoomScale
        canvasView.maximumZoomScale = scrollView.maximumZoomScale

        scrollView.addSubview(canvasView)
        scrollView.contentSize = contentSize

        // Tool Picker
        if let window = view.window ?? UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first {
            
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            toolPicker.addObserver(self)
            canvasView.becomeFirstResponder()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        canvasView.becomeFirstResponder()
    }

    // MARK: - PKCanvasViewDelegate
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        let drawingBounds = canvasView.drawing.bounds
        let buffer: CGFloat = 200

        // Ensure the drawing bounds are valid numbers
        guard drawingBounds.maxY.isFinite else {
            print("⚠️ Invalid drawing bounds: \(drawingBounds)")
            return
        }

        var newHeight = max(contentSize.height, drawingBounds.maxY + buffer)

        // Avoid unnecessary updates
        if newHeight != contentSize.height {
            contentSize = CGSize(width: contentSize.width, height: newHeight)

            // Apply size safely
            canvasView.frame.size = contentSize
            scrollView.contentSize = contentSize
        }
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        canvasView.zoomScale = scrollView.zoomScale
    }
}
