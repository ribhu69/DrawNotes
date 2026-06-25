import UIKit
import PencilKit

final class CanvasViewController: UIViewController {

    // MARK: - Public Interface

    var initialDrawing: PKDrawing = PKDrawing()
    var initialImageItems: [ImageItem] = []
    var onDrawingChanged: ((PKDrawing) -> Void)?
    var onImageItemsChanged: (([ImageItem]) -> Void)?

    var template: CanvasTemplate = .blank {
        didSet { applyTemplate() }
    }

    // MARK: - Private — Canvas

    private(set) var canvasView: PKCanvasView!
    private var toolPicker: PKToolPicker!
    private var templateView: UIView!
    private var marginLineView: UIView!
    private var saveWorkItem: DispatchWorkItem?

    // MARK: - Private — Images

    private var imageItems: [ImageItem] = []
    private var imageViews: [UUID: ImageItemView] = [:]
    private var selectedImageID: UUID?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTemplateLayer()
        setupCanvas()
        applyTemplate()
        loadImageItems(initialImageItems)
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

    private func setupTemplateLayer() {
        templateView = UIView()
        templateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(templateView)
        NSLayoutConstraint.activate([
            templateView.topAnchor.constraint(equalTo: view.topAnchor),
            templateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            templateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            templateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

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

        // Tap on empty canvas area → deselect images
        let deselectTap = UITapGestureRecognizer(target: self, action: #selector(deselectAllImages))
        deselectTap.delegate = self
        canvasView.addGestureRecognizer(deselectTap)
    }

    // MARK: - Template

    private func applyTemplate() {
        guard isViewLoaded else { return }
        let dark = traitCollection.userInterfaceStyle == .dark

        templateView.backgroundColor = template.patternImage(dark: dark)
            .map { UIColor(patternImage: $0) } ?? .clear

        marginLineView.isHidden = !template.hasMarginLine
        marginLineView.backgroundColor = dark
            ? UIColor(red: 0.9, green: 0.25, blue: 0.25, alpha: 0.5)
            : UIColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 0.5)
    }

    // MARK: - External Updates (from SwiftUI)

    func loadDrawing(_ drawing: PKDrawing) {
        guard canvasView.drawing != drawing else { return }
        canvasView.drawing = drawing
    }

    func setDrawingPolicy(_ policy: PKCanvasViewDrawingPolicy) {
        canvasView.drawingPolicy = policy
    }

    // MARK: - Image Management

    func addImage(_ image: UIImage) {
        let offset = canvasView.contentOffset
        let visible = CGRect(
            x: offset.x, y: offset.y,
            width: canvasView.bounds.width,
            height: canvasView.bounds.height
        )
        let center = CGPoint(x: visible.midX, y: visible.midY)
        let maxDim = min(visible.width * 0.65, 480)
        let aspect = image.size.width / image.size.height
        let size: CGSize = aspect >= 1
            ? CGSize(width: maxDim, height: maxDim / aspect)
            : CGSize(width: maxDim * aspect, height: maxDim)

        let item = ImageItem(image: image, center: center, size: size)
        imageItems.append(item)
        mountImageView(for: item)
        deselectAll()
        imageViews[item.id]?.isSelected = true
        selectedImageID = item.id
        onImageItemsChanged?(imageItems)
    }

    private func loadImageItems(_ items: [ImageItem]) {
        imageItems = items
        items.forEach { mountImageView(for: $0) }
    }

    private func mountImageView(for item: ImageItem) {
        let v = ImageItemView(item: item)
        v.delegate = self
        canvasView.addSubview(v)
        imageViews[item.id] = v
    }

    // MARK: - Deselect

    @objc private func deselectAllImages() {
        deselectAll()
    }

    private func deselectAll() {
        selectedImageID = nil
        imageViews.values.forEach { $0.isSelected = false }
    }

    // MARK: - Debounced Drawing Save

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

// MARK: - UIGestureRecognizerDelegate

extension CanvasViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gr: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool { true }
}

// MARK: - ImageItemViewDelegate

extension CanvasViewController: ImageItemViewDelegate {

    func imageItemViewRequestedSelection(_ view: ImageItemView) {
        deselectAll()
        view.isSelected = true
        selectedImageID = view.itemID
    }

    func imageItemViewRequestedDeletion(_ view: ImageItemView) {
        view.removeFromSuperview()
        imageViews.removeValue(forKey: view.itemID)
        imageItems.removeAll { $0.id == view.itemID }
        if selectedImageID == view.itemID { selectedImageID = nil }
        onImageItemsChanged?(imageItems)
    }

    func imageItemViewDidUpdate(_ view: ImageItemView) {
        guard let idx = imageItems.firstIndex(where: { $0.id == view.itemID }) else { return }
        imageItems[idx].center   = view.snapshotCenter()
        imageItems[idx].size     = view.snapshotSize()
        imageItems[idx].rotation = view.currentRotation
        onImageItemsChanged?(imageItems)
    }
}
