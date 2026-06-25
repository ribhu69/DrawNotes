import SwiftUI
import PencilKit

struct CanvasRepresentable: UIViewControllerRepresentable {

    @Binding var drawing: PKDrawing
    let fingerInputEnabled: Bool
    let template: CanvasTemplate

    func makeUIViewController(context: Context) -> CanvasViewController {
        let vc = CanvasViewController()
        vc.initialDrawing = drawing
        vc.template = template
        let coordinator = context.coordinator
        vc.onDrawingChanged = { newDrawing in
            coordinator.receivedFromCanvas = true
            drawing = newDrawing
            DispatchQueue.main.async { coordinator.receivedFromCanvas = false }
        }
        return vc
    }

    func updateUIViewController(_ vc: CanvasViewController, context: Context) {
        vc.setDrawingPolicy(fingerInputEnabled ? .anyInput : .pencilOnly)
        vc.template = template
        if !context.coordinator.receivedFromCanvas {
            vc.loadDrawing(drawing)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var receivedFromCanvas = false
    }
}
