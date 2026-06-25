import SwiftUI
import PencilKit

struct CanvasRepresentable: UIViewControllerRepresentable {

    @Binding var drawing: PKDrawing
    @Binding var imageItems: [ImageItem]
    @Binding var pendingImage: UIImage?
    let fingerInputEnabled: Bool
    let template: CanvasTemplate

    // MARK: - Lifecycle

    func makeUIViewController(context: Context) -> CanvasViewController {
        let vc = CanvasViewController()
        vc.initialDrawing = drawing
        vc.initialImageItems = imageItems
        vc.template = template

        let coordinator = context.coordinator

        vc.onDrawingChanged = { newDrawing in
            coordinator.receivedFromCanvas = true
            drawing = newDrawing
            DispatchQueue.main.async { coordinator.receivedFromCanvas = false }
        }

        vc.onImageItemsChanged = { newItems in
            imageItems = newItems
        }

        return vc
    }

    func updateUIViewController(_ vc: CanvasViewController, context: Context) {
        vc.setDrawingPolicy(fingerInputEnabled ? .anyInput : .pencilOnly)
        vc.template = template

        if !context.coordinator.receivedFromCanvas {
            vc.loadDrawing(drawing)
        }

        // Consume a pending image (e.g., just picked from photo library)
        if let img = pendingImage {
            vc.addImage(img)
            DispatchQueue.main.async { pendingImage = nil }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Coordinator

    final class Coordinator {
        var receivedFromCanvas = false
    }
}
