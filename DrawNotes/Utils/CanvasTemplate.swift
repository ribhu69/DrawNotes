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
}
