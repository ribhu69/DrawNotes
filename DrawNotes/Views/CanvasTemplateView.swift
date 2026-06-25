import UIKit

/// Fixed-position view that renders template lines/dots in sync with the canvas scroll offset.
/// Lines are drawn using the scroll offset as a phase, so they visually track canvas content.
final class CanvasTemplateView: UIView {

    var template: CanvasTemplate = .blank {
        didSet { setNeedsDisplay() }
    }

    var scrollOffset: CGPoint = .zero {
        didSet { setNeedsDisplay() }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        // UIView draw calls are batched by the display link — safe to call setNeedsDisplay frequently
        contentMode = .redraw
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let dark = traitCollection.userInterfaceStyle == .dark

        switch template {
        case .blank:
            break
        case .ruled:
            drawHLines(ctx: ctx, rect: rect, dark: dark)
            drawMarginLine(ctx: ctx, rect: rect, dark: dark)
        case .grid:
            drawHLines(ctx: ctx, rect: rect, dark: dark)
            drawVLines(ctx: ctx, rect: rect, dark: dark)
        case .dotted:
            drawDots(ctx: ctx, rect: rect, dark: dark)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            setNeedsDisplay()
        }
    }

    // MARK: - Primitives

    private static let spacing: CGFloat = 36

    private func lineColor(dark: Bool) -> CGColor {
        (dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor(red: 0.72, green: 0.85, blue: 1.0, alpha: 0.72)
        ).cgColor
    }

    /// Starting y for the first visible line, accounting for scroll phase.
    private func yPhase() -> CGFloat {
        let s = Self.spacing
        let phase = scrollOffset.y.truncatingRemainder(dividingBy: s)
        return phase == 0 ? s : s - phase
    }

    private func xPhase() -> CGFloat {
        let s = Self.spacing
        let phase = scrollOffset.x.truncatingRemainder(dividingBy: s)
        return phase == 0 ? s : s - phase
    }

    private func drawHLines(ctx: CGContext, rect: CGRect, dark: Bool) {
        ctx.setFillColor(lineColor(dark: dark))
        var y = yPhase()
        while y <= rect.height {
            ctx.fill(CGRect(x: 0, y: y - 0.5, width: rect.width, height: 0.5))
            y += Self.spacing
        }
    }

    private func drawVLines(ctx: CGContext, rect: CGRect, dark: Bool) {
        ctx.setFillColor(lineColor(dark: dark))
        var x = xPhase()
        while x <= rect.width {
            ctx.fill(CGRect(x: x - 0.5, y: 0, width: 0.5, height: rect.height))
            x += Self.spacing
        }
    }

    private func drawDots(ctx: CGContext, rect: CGRect, dark: Bool) {
        ctx.setFillColor(lineColor(dark: dark))
        let r: CGFloat = 1.4
        var y = yPhase()
        while y <= rect.height + Self.spacing {
            var x = xPhase()
            while x <= rect.width + Self.spacing {
                ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                x += Self.spacing
            }
            y += Self.spacing
        }
    }

    private func drawMarginLine(ctx: CGContext, rect: CGRect, dark: Bool) {
        let color: CGColor = (dark
            ? UIColor(red: 0.9, green: 0.25, blue: 0.25, alpha: 0.5)
            : UIColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 0.5)
        ).cgColor
        ctx.setFillColor(color)
        ctx.fill(CGRect(x: 88, y: 0, width: 1, height: rect.height))
    }
}
