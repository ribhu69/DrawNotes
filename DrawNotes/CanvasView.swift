//
//  CanvasView.swift
//  DrawNotes
//
//  Created by Arkaprava Ghosh on 24/04/25.
//

import SwiftUI

struct CanvasView: UIViewControllerRepresentable {
    
    @Binding var contentMode: ContentMode

    class Coordinator: NSObject {
        var parent: CanvasView
        init(parent: CanvasView) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> CanvasViewController {
        return CanvasViewController()
        
    }

    func updateUIViewController(_ uiViewController: CanvasViewController, context: Context) {
        // Update the background color based on the contentMode
        
        UIView.animate(withDuration: 0.3) {
            uiViewController.canvasView.backgroundColor = contentMode == .light ? .white : .black
            uiViewController.scrollView.backgroundColor = contentMode == .light ? .white : .black
            uiViewController.invertStrokeColors(for: contentMode == .light ? .white : .black)
        }
    }
}
