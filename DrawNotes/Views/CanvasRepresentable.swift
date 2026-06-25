import SwiftUI
import PencilKit

struct CanvasRepresentable: UIViewControllerRepresentable {

    @Binding var drawing: PKDrawing
    let shapeRecognitionEnabled: Bool
    let fingerInputEnabled: Bool

    // MARK: - Lifecycle

    func makeUIViewController(context: Context) -> CanvasViewController {
        let vc = CanvasViewController()
        vc.initialDrawing = drawing
        vc.shapeRecognitionEnabled = shapeRecognitionEnabled
        let coordinator = context.coordinator
        vc.onDrawingChanged = { newDrawing in
            coordinator.receivedFromCanvas = true
            drawing = newDrawing
            DispatchQueue.main.async { coordinator.receivedFromCanvas = false }
        }
        return vc
    }

    func updateUIViewController(_ vc: CanvasViewController, context: Context) {
        vc.shapeRecognitionEnabled = shapeRecognitionEnabled
        vc.setDrawingPolicy(fingerInputEnabled ? .anyInput : .pencilOnly)

        // Only push drawing externally if we didn't just receive it from the canvas
        if !context.coordinator.receivedFromCanvas {
            vc.loadDrawing(drawing)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Coordinator

    final class Coordinator {
        /// Prevents re-pushing the drawing back to the VC right after the VC sent it out.
        var receivedFromCanvas = false
    }
}
