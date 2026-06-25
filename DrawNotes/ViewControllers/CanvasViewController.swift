import UIKit
import PencilKit

final class CanvasViewController: UIViewController {

    // MARK: - Public Interface

    var initialDrawing: PKDrawing = PKDrawing()
    var onDrawingChanged: ((PKDrawing) -> Void)?

    var template: CanvasTemplate = .blank {
        didSet { applyTemplate() }
    }

    // MARK: - Private

    private(set) var canvasView: PKCanvasView!
    private var toolPicker: PKToolPicker!
    private var templateView: UIView!
    private var marginLineView: UIView!
    private var saveWorkItem: DispatchWorkItem?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTemplate()
        setupCanvas()
        applyTemplate()
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyTemplate()
        }
    }

    // MARK: - Setup

    private func setupTemplate() {
        // Template sits below the canvas, fills the full view, stays fixed.
        // Since the patterns are repeating tiles, the visual stays correct at any scroll offset.
        templateView = UIView()
        templateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(templateView)
        NSLayoutConstraint.activate([
            templateView.topAnchor.constraint(equalTo: view.topAnchor),
            templateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            templateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            templateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Red margin line — only visible for the Ruled template
        marginLineView = UIView()
        marginLineView.translatesAutoresizingMaskIntoConstraints = false
        marginLineView.isHidden = true
        view.addSubview(marginLineView)
        NSLayoutConstraint.activate([
            marginLineView.topAnchor.constraint(equalTo: view.topAnchor),
            marginLineView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            marginLineView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 88),
            marginLineView.widthAnchor.constraint(equalToConstant: 1)
        ])
    }

    private func setupCanvas() {
        canvasView = PKCanvasView()
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.drawing = initialDrawing
        canvasView.delegate = self
        canvasView.drawingPolicy = .anyInput
        // Clear so the template view shows through
        canvasView.backgroundColor = .clear
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

    // MARK: - Template Rendering

    private func applyTemplate() {
        guard isViewLoaded else { return }
        let dark = traitCollection.userInterfaceStyle == .dark

        if let tile = template.patternImage(dark: dark) {
            templateView.backgroundColor = UIColor(patternImage: tile)
        } else {
            templateView.backgroundColor = .clear
        }

        marginLineView.isHidden = !template.hasMarginLine
        marginLineView.backgroundColor = dark
            ? UIColor(red: 0.9, green: 0.25, blue: 0.25, alpha: 0.55)
            : UIColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 0.55)
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
