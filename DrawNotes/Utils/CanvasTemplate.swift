import UIKit

enum CanvasTemplate: String, CaseIterable, Codable {
    case blank  = "blank"
    case ruled  = "ruled"
    case grid   = "grid"
    case dotted = "dotted"

    var displayName: String {
        switch self {
        case .blank:  return "Blank"
        case .ruled:  return "Ruled"
        case .grid:   return "Grid"
        case .dotted: return "Dotted"
        }
    }

    var iconName: String {
        switch self {
        case .blank:  return "doc"
        case .ruled:  return "text.alignleft"
        case .grid:   return "grid"
        case .dotted: return "circle.grid.3x3"
        }
    }

    /// Whether this template includes a vertical red margin line.
    var hasMarginLine: Bool { self == .ruled }

    // MARK: - Pattern Tile

    /// Returns a small repeating tile image for use as a UIColor(patternImage:) background.
    func patternImage(dark: Bool) -> UIImage? {
        switch self {
        case .blank:  return nil
        case .ruled:  return Self.ruledTile(dark: dark)
        case .grid:   return Self.gridTile(dark: dark)
        case .dotted: return Self.dottedTile(dark: dark)
        }
    }

    // MARK: - Tile Rendering

    private static func lineColor(dark: Bool) -> UIColor {
        dark
            ? UIColor.white.withAlphaComponent(0.1)
            : UIColor(red: 0.72, green: 0.85, blue: 1.0, alpha: 0.7)
    }

    private static func ruledTile(dark: Bool) -> UIImage {
        let spacing: CGFloat = 36
        let size = CGSize(width: 2, height: spacing)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let c = ctx.cgContext
            c.setFillColor(lineColor(dark: dark).cgColor)
            c.fill(CGRect(x: 0, y: spacing - 0.5, width: size.width, height: 0.5))
        }
    }

    private static func gridTile(dark: Bool) -> UIImage {
        let spacing: CGFloat = 36
        let size = CGSize(width: spacing, height: spacing)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let c = ctx.cgContext
            c.setFillColor(lineColor(dark: dark).cgColor)
            // Bottom edge
            c.fill(CGRect(x: 0, y: spacing - 0.5, width: spacing, height: 0.5))
            // Right edge
            c.fill(CGRect(x: spacing - 0.5, y: 0, width: 0.5, height: spacing))
        }
    }

    private static func dottedTile(dark: Bool) -> UIImage {
        let spacing: CGFloat = 36
        let size = CGSize(width: spacing, height: spacing)
        let r: CGFloat = 1.4
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let c = ctx.cgContext
            c.setFillColor(lineColor(dark: dark).cgColor)
            c.fillEllipse(in: CGRect(x: spacing - r, y: spacing - r, width: r * 2, height: r * 2))
        }
    }
}
