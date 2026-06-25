import UIKit
import PencilKit

final class CanvasViewController: UIViewController {

    // MARK: - Public Interface

    var initialDrawing: PKDrawing = PKDrawing()
    var shapeRecognitionEnabled = true
    var onDrawingChanged: ((PKDrawing) -> Void)?

    // MARK: - Private

    private(set) var canvasView: PKCanvasView!
    private var toolPicker: PKToolPicker!

    /// Tracks strokes present before the latest user action — used to find newly added strokes.
    private var baselineStrokes: [PKStroke] = []
    private var shapeWorkItem: DispatchWorkItem?
    private var saveWorkItem: DispatchWorkItem?

    /// Guards against feeding our own programmatic drawing change back as a new user stroke.
    private var isApplyingShape = false

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
        // Flush any pending save immediately on exit
        saveWorkItem?.cancel()
        onDrawingChanged?(canvasView.drawing)
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

        baselineStrokes = initialDrawing.strokes
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Give the canvas a tall scrollable content area (≥4 screen heights)
        let w = view.bounds.width
        let minH = view.bounds.height * 4
        let currentH = canvasView.contentSize.height
        if currentH < minH {
            canvasView.contentSize = CGSize(width: w, height: minH)
        }
    }

    // MARK: - External Updates

    /// Call this to push a drawing into the canvas without triggering shape recognition.
    func loadDrawing(_ drawing: PKDrawing) {
        guard canvasView.drawing != drawing else { return }
        isApplyingShape = true
        canvasView.drawing = drawing
        baselineStrokes = drawing.strokes
        isApplyingShape = false
    }

    func setDrawingPolicy(_ policy: PKCanvasViewDrawingPolicy) {
        canvasView.drawingPolicy = policy
    }

    // MARK: - Shape Recognition Pipeline

    private func scheduleShapeCheck() {
        shapeWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.runShapeRecognition()
        }
        shapeWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38, execute: item)
    }

    private func runShapeRecognition() {
        guard shapeRecognitionEnabled, !isApplyingShape else { return }
        let current = canvasView.drawing.strokes
        let baseline = baselineStrokes

        guard current.count > baseline.count else {
            baselineStrokes = current
            return
        }

        // Only inspect newly added strokes
        var replacements: [(index: Int, stroke: PKStroke)] = []
        for i in baseline.count..<current.count {
            if let clean = ShapeRecognizer.recognize(stroke: current[i]) {
                replacements.append((i, clean))
            }
        }

        guard !replacements.isEmpty else {
            baselineStrokes = current
            return
        }

        isApplyingShape = true
        var updated = Array(current)
        for r in replacements where r.index < updated.count {
            updated[r.index] = r.stroke
        }

        let newDrawing = PKDrawing(strokes: updated)
        canvasView.drawing = newDrawing
        baselineStrokes = updated
        onDrawingChanged?(newDrawing)
        isApplyingShape = false
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
        guard !isApplyingShape else { return }

        if shapeRecognitionEnabled {
            scheduleShapeCheck()
        } else {
            baselineStrokes = canvasView.drawing.strokes
        }

        scheduleSave()
    }
}
