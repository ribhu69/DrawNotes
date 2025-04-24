//
//  CanvasViewController.swift
//  DrawNotes
//
//  Created by Arkaprava Ghosh on 24/04/25.
//

import UIKit
import SwiftUI
import PencilKit

class CanvasViewController: UIViewController, PKToolPickerObserver, PKCanvasViewDelegate, UIScrollViewDelegate , UIPencilInteractionDelegate{
    var canvasView: PKCanvasView!
    let scrollView = UIScrollView()
    let toolPicker = PKToolPicker()
    
    private var previousInkTool: PKTool?
    private var isUsingEraser = false
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

        previousInkTool = canvasView.tool
        // Tool Picker
        if let window = view.window ?? UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first {
            
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            toolPicker.addObserver(self)
            canvasView.becomeFirstResponder()
        }

        // Set up pencil interaction (double tap)
        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = self
        view.addInteraction(pencilInteraction)
    }
    
    
    func pencilInteraction(_ interaction: UIPencilInteraction, didReceiveTap tap: UIPencilInteraction.Tap) {
        pencilInteractionDidTap(interaction)
    }
    
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        let currentTool = canvasView.tool

        if currentTool is PKEraserTool {
            // Switch back to previous ink tool if available
            if let previousInk = previousInkTool {
                canvasView.tool = previousInk
                isUsingEraser = false
            }
        } else if let inkTool = currentTool as? PKInkingTool {
            // Save current ink tool and switch to eraser
            previousInkTool = inkTool
            canvasView.tool = PKEraserTool(.vector)
            isUsingEraser = true
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
    
    func invertStrokeColors(for backgroundColor: UIColor) {
        let drawing = canvasView.drawing

        let newStrokes = drawing.strokes.map { stroke in
            let originalInk = stroke.ink
            let inverted = invertedColor(from: originalInk.color, against: backgroundColor)
            let newInk = PKInk(originalInk.inkType, color: inverted)

            return PKStroke(ink: newInk, path: stroke.path)
        }

        canvasView.drawing = PKDrawing(strokes: newStrokes)
    }

    func invertedColor(from color: UIColor, against background: UIColor) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)

        return UIColor(red: 1.0 - r, green: 1.0 - g, blue: 1.0 - b, alpha: a)
    }
}
