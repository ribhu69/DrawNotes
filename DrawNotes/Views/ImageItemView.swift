import UIKit

// MARK: - Delegate

protocol ImageItemViewDelegate: AnyObject {
    func imageItemViewRequestedSelection(_ view: ImageItemView)
    func imageItemViewRequestedDeletion(_ view: ImageItemView)
    func imageItemViewDidUpdate(_ view: ImageItemView)
}

// MARK: - ImageItemView

final class ImageItemView: UIView {

    // MARK: - Public

    let itemID: UUID
    weak var delegate: ImageItemViewDelegate?

    private(set) var currentRotation: CGFloat

    var isSelected: Bool = false {
        didSet {
            guard isSelected != oldValue else { return }
            UIView.animate(withDuration: 0.18, delay: 0,
                           usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                self.updateSelectionAppearance()
            }
        }
    }

    // MARK: - Private UI

    private let imageView = UIImageView()
    private let borderLayer = CAShapeLayer()
    private let deleteButton = UIButton(type: .custom)
    private let shadowContainer = UIView()

    // MARK: - Gesture State

    private var panStartCenter: CGPoint = .zero
    private var pinchStartSize: CGSize = .zero
    private var rotationAtStart: CGFloat = 0

    // MARK: - Init

    init(item: ImageItem) {
        itemID = item.id
        currentRotation = item.rotation
        super.init(frame: CGRect(origin: .zero, size: item.size))
        center = item.center
        transform = CGAffineTransform(rotationAngle: item.rotation)
        setupUI(image: UIImage(data: item.imageData))
        setupGestures()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowContainer.frame = bounds
        imageView.frame = bounds

        borderLayer.frame = bounds
        borderLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 1.5, dy: 1.5), cornerRadius: 6
        ).cgPath

        let btnSize: CGFloat = 30
        deleteButton.frame = CGRect(
            x: bounds.width - btnSize * 0.55,
            y: -btnSize * 0.45,
            width: btnSize, height: btnSize
        )
    }

    // MARK: - Setup

    private func setupUI(image: UIImage?) {
        clipsToBounds = false

        // Shadow container sits behind image to give a floating feel when selected
        shadowContainer.layer.cornerRadius = 6
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowRadius = 10
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        shadowContainer.layer.shadowOpacity = 0
        addSubview(shadowContainer)

        // Image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.image = image
        addSubview(imageView)

        // Dashed selection border
        borderLayer.strokeColor = UIColor.systemBlue.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 2
        borderLayer.lineDashPattern = [6, 3]
        borderLayer.isHidden = true
        layer.addSublayer(borderLayer)

        // Delete button — circular red X, rendered outside bounds
        deleteButton.backgroundColor = UIColor.systemRed
        deleteButton.layer.cornerRadius = 15
        deleteButton.clipsToBounds = true
        let xConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        deleteButton.setImage(UIImage(systemName: "xmark", withConfiguration: xConfig), for: .normal)
        deleteButton.tintColor = .white
        deleteButton.isHidden = true
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        addSubview(deleteButton)
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))

        [tap, pan, pinch, rotate].forEach {
            $0.delegate = self
            addGestureRecognizer($0)
        }
    }

    private func updateSelectionAppearance() {
        borderLayer.isHidden = !isSelected
        deleteButton.isHidden = !isSelected
        shadowContainer.layer.shadowOpacity = isSelected ? 0.22 : 0
        imageView.layer.borderWidth = 0
    }

    // MARK: - Hit Testing (delete button is outside bounds)

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !deleteButton.isHidden {
            let btnPoint = convert(point, to: deleteButton)
            if deleteButton.point(inside: btnPoint, with: event) {
                return deleteButton
            }
        }
        return super.hitTest(point, with: event)
    }

    // MARK: - Gesture Handlers

    @objc private func handleTap(_ gr: UITapGestureRecognizer) {
        delegate?.imageItemViewRequestedSelection(self)
    }

    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
        if !isSelected {
            delegate?.imageItemViewRequestedSelection(self)
            return
        }
        switch gr.state {
        case .began:
            panStartCenter = center
        case .changed:
            let t = gr.translation(in: superview)
            center = CGPoint(x: panStartCenter.x + t.x, y: panStartCenter.y + t.y)
        case .ended, .cancelled:
            delegate?.imageItemViewDidUpdate(self)
        default: break
        }
    }

    @objc private func handlePinch(_ gr: UIPinchGestureRecognizer) {
        guard isSelected else { return }
        switch gr.state {
        case .began:
            pinchStartSize = bounds.size
        case .changed:
            let s = gr.scale
            let newW = max(60, pinchStartSize.width * s)
            let newH = max(60, pinchStartSize.height * s)
            bounds = CGRect(origin: .zero, size: CGSize(width: newW, height: newH))
            setNeedsLayout()
        case .ended, .cancelled:
            delegate?.imageItemViewDidUpdate(self)
        default: break
        }
    }

    @objc private func handleRotation(_ gr: UIRotationGestureRecognizer) {
        guard isSelected else { return }
        switch gr.state {
        case .began:
            rotationAtStart = currentRotation
        case .changed:
            currentRotation = rotationAtStart + gr.rotation
            transform = CGAffineTransform(rotationAngle: currentRotation)
        case .ended, .cancelled:
            delegate?.imageItemViewDidUpdate(self)
        default: break
        }
    }

    @objc private func deleteTapped() {
        delegate?.imageItemViewRequestedDeletion(self)
    }

    // MARK: - State Readout

    func snapshotCenter() -> CGPoint { center }
    func snapshotSize() -> CGSize { bounds.size }
}

// MARK: - UIGestureRecognizerDelegate

extension ImageItemView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gr: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool { true }

    func gestureRecognizer(_ gr: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Let Apple Pencil events fall through to PKCanvasView for drawing
        touch.type != .stylus
    }
}
