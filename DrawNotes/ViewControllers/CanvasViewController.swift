import UIKit
import PencilKit

final class CanvasViewController: UIViewController {

    // MARK: - Public Interface

    var initialDrawing: PKDrawing = PKDrawing()
    var onDrawingChanged: ((PKDrawing) -> Void)?

    // MARK: - Private

    private(set) var canvasView: PKCanvasView!
    private var toolPicker: PKToolPicker!
    private var saveWorkItem: DispatchWorkItem?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupCanvas()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        canvasView.becomeFirstResponder()
        toolPicker.setVisible(true, forFirstResponder: canvasView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveWorkItem?.cancel()
        onDrawingChanged?(canvasView.drawing)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = view.bounds.width
        let minH = view.bounds.height * 4
        if canvasView.contentSize.height < minH {
            canvasView.contentSize = CGSize(width: w, height: minH)
        }
    }

    // MARK: - Setup

    private func setupCanvas() {
        canvasView = PKCanvasView()
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.drawing = initialDrawing
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .systemBackground
        canvasView.alwaysBounceVertical = true
        canvasView.showsVerticalScrollIndicator = true
        canvasView.showsHorizontalScrollIndicator = false

        view.addSubview(canvasView)
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: view.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        toolPicker = PKToolPicker()
        toolPicker.addObserver(canvasView)
    }

    // MARK: - External Updates

    func loadDrawing(_ drawing: PKDrawing) {
        guard canvasView.drawing != drawing else { return }
        canvasView.drawing = drawing
    }

    func setDrawingPolicy(_ policy: PKCanvasViewDrawingPolicy) {
        canvasView.drawingPolicy = policy
    }

    // MARK: - Debounced Save

    private func scheduleSave() {
        saveWorkItem?.cancel()
        let drawing = canvasView.drawing
        let item = DispatchWorkItem { [weak self] in
            self?.onDrawingChanged?(drawing)
        }
        saveWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: item)
    }
}

// MARK: - PKCanvasViewDelegate

extension CanvasViewController: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        scheduleSave()
    }
}
