struct CanvasView: UIViewControllerRepresentable {
    
    @Binding var contentMode: ContentMode
    @State private var canvasVC: CanvasViewController?

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
        let canvasVC = CanvasViewController()
        self.canvasVC = canvasVC
        return canvasVC
    }

    func updateUIViewController(_ uiViewController: CanvasViewController, context: Context) {
        // Update the background color based on the contentMode
        
        UIView.animate(withDuration: 0.3) {
            uiViewController.canvasView.backgroundColor = contentMode == .light ? .white : .black

        }
    }
}