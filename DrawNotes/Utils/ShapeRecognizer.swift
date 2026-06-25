import UIKit
import PencilKit

// Geometric shape types we can detect and clean up
enum DetectedShape {
    case line(CGPoint, CGPoint)
    case rectangle(CGRect)
    case circle(center: CGPoint, radius: CGFloat)
    case triangle([CGPoint])
}

struct ShapeRecognizer {

    // Minimum path points to attempt recognition
    private static let minPoints = 5
    // Closedness threshold as fraction of bounding diagonal
    private static let closednessFraction: CGFloat = 0.18

    /// Attempts to recognize a drawn stroke as a geometric shape.
    /// Returns a clean replacement stroke, or nil if no shape was detected.
    static func recognize(stroke: PKStroke) -> PKStroke? {
        let path = stroke.path
        guard path.count >= minPoints else { return nil }

        let points = samplePoints(from: path, maxCount: 150)
        guard let shape = detectShape(in: points) else { return nil }

        return makeStroke(for: shape, ink: stroke.ink)
    }

    // MARK: - Sampling

    private static func samplePoints(from path: PKStrokePath, maxCount: Int) -> [CGPoint] {
        var result: [CGPoint] = []
        let total = path.count
        let step = max(1, total / maxCount)
        var i = 0
        while i < total {
            result.append(path[i].location)
            i += step
        }
        if let last = path.last { result.append(last.location) }
        return result
    }

    // MARK: - Shape Detection

    private static func detectShape(in points: [CGPoint]) -> DetectedShape? {
        let simplified = douglasPeucker(points: points, epsilon: 12.0)
        let start = points.first!
        let end = points.last!
        let diagonal = boundingDiagonal(of: points)

        let isClosed = dist(start, end) < max(40, diagonal * closednessFraction)

        if !isClosed {
            // Straight line
            if isLine(points: points, toleranceFraction: 0.06) {
                return .line(start, end)
            }
            return nil
        }

        // Closed shapes
        if isCircle(points: points, toleranceFraction: 0.22) {
            let center = centroid(of: points)
            let radius = avgDist(from: center, to: points)
            return .circle(center: center, radius: radius)
        }

        let corners = simplified
        if corners.count == 4 || (corners.count >= 3 && corners.count <= 7 && rectangleScore(corners: corners) > 0.7) {
            return .rectangle(boundingRect(of: points))
        }

        if corners.count == 3 || (corners.count >= 3 && corners.count <= 5 && isTriangle(points: corners)) {
            return .triangle(bestTriangle(from: corners))
        }

        return nil
    }

    // MARK: - Geometric Tests

    private static func isLine(points: [CGPoint], toleranceFraction: CGFloat) -> Bool {
        guard let s = points.first, let e = points.last else { return false }
        let length = dist(s, e)
        guard length > 30 else { return false }
        let maxDev = points.map { perpendicularDist(point: $0, a: s, b: e) }.max() ?? 0
        return maxDev / length < toleranceFraction
    }

    private static func isCircle(points: [CGPoint], toleranceFraction: CGFloat) -> Bool {
        let c = centroid(of: points)
        let radii = points.map { dist($0, c) }
        let mean = radii.reduce(0, +) / CGFloat(radii.count)
        guard mean > 20 else { return false }
        let variance = radii.map { pow($0 - mean, 2) }.reduce(0, +) / CGFloat(radii.count)
        return sqrt(variance) / mean < toleranceFraction
    }

    private static func rectangleScore(corners: [CGPoint]) -> CGFloat {
        // Score based on how close angles are to 90°
        let pts = corners.prefix(4).map { $0 }
        guard pts.count == 4 else { return 0 }
        var score: CGFloat = 0
        for i in 0..<4 {
            let a = pts[(i + 3) % 4]
            let b = pts[i]
            let c = pts[(i + 1) % 4]
            let angle = angleBetween(a: a, vertex: b, c: c)
            let deviation = abs(angle - .pi / 2) / (.pi / 2)
            score += max(0, 1 - deviation * 2)
        }
        return score / 4
    }

    private static func isTriangle(points: [CGPoint]) -> Bool {
        let tri = bestTriangle(from: points)
        guard tri.count == 3 else { return false }
        // All angles should be between 15° and 150°
        for i in 0..<3 {
            let angle = angleBetween(a: tri[(i + 2) % 3], vertex: tri[i], c: tri[(i + 1) % 3])
            if angle < 0.26 || angle > 2.62 { return false }
        }
        return true
    }

    private static func bestTriangle(from points: [CGPoint]) -> [CGPoint] {
        guard points.count >= 3 else { return Array(points.prefix(3)) }
        if points.count == 3 { return points }

        // Sample a spread of points and find the triple with max area
        let sampled = stride(from: 0, to: points.count, by: max(1, points.count / 12)).map { points[$0] }
        var best: [CGPoint] = [sampled[0], sampled[sampled.count / 2], sampled[sampled.count - 1]]
        var bestArea: CGFloat = 0

        for i in 0..<sampled.count {
            for j in (i+1)..<sampled.count {
                for k in (j+1)..<sampled.count {
                    let area = triangleArea(a: sampled[i], b: sampled[j], c: sampled[k])
                    if area > bestArea {
                        bestArea = area
                        best = [sampled[i], sampled[j], sampled[k]]
                    }
                }
            }
        }
        return best
    }

    // MARK: - Stroke Construction

    private static func makeStroke(for shape: DetectedShape, ink: PKInk) -> PKStroke? {
        let controlPoints: [CGPoint]

        switch shape {
        case .line(let a, let b):
            controlPoints = [a, b]
        case .rectangle(let rect):
            controlPoints = [
                CGPoint(x: rect.minX, y: rect.minY),
                CGPoint(x: rect.maxX, y: rect.minY),
                CGPoint(x: rect.maxX, y: rect.maxY),
                CGPoint(x: rect.minX, y: rect.maxY),
                CGPoint(x: rect.minX, y: rect.minY)
            ]
        case .circle(let center, let radius):
            let steps = 72
            controlPoints = (0...steps).map { i in
                let angle = 2 * CGFloat.pi * CGFloat(i) / CGFloat(steps)
                return CGPoint(x: center.x + radius * cos(angle),
                               y: center.y + radius * sin(angle))
            }
        case .triangle(let pts):
            guard pts.count == 3 else { return nil }
            controlPoints = pts + [pts[0]]
        }

        guard controlPoints.count >= 2 else { return nil }

        let strokePoints = controlPoints.enumerated().map { (i, pt) in
            PKStrokePoint(
                location: pt,
                timeOffset: Double(i) * 0.01,
                size: CGSize(width: 2.5, height: 2.5),
                opacity: 1.0,
                force: 1.0,
                azimuth: 0,
                altitude: .pi / 2
            )
        }
        let path = PKStrokePath(controlPoints: strokePoints, creationDate: Date())
        return PKStroke(ink: ink, path: path)
    }

    // MARK: - Douglas-Peucker Simplification

    private static func douglasPeucker(points: [CGPoint], epsilon: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }
        var maxDist: CGFloat = 0
        var maxIdx = 0
        let first = points[0], last = points[points.count - 1]
        for i in 1..<points.count - 1 {
            let d = perpendicularDist(point: points[i], a: first, b: last)
            if d > maxDist { maxDist = d; maxIdx = i }
        }
        if maxDist > epsilon {
            let left  = douglasPeucker(points: Array(points[0...maxIdx]), epsilon: epsilon)
            let right = douglasPeucker(points: Array(points[maxIdx...]), epsilon: epsilon)
            return Array(left.dropLast()) + right
        }
        return [first, last]
    }

    // MARK: - Math Helpers

    private static func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(b.x - a.x, b.y - a.y)
    }

    private static func perpendicularDist(point p: CGPoint, a: CGPoint, b: CGPoint) -> CGFloat {
        let dx = b.x - a.x, dy = b.y - a.y
        let len = hypot(dx, dy)
        guard len > 0 else { return dist(p, a) }
        return abs(dy * p.x - dx * p.y + b.x * a.y - b.y * a.x) / len
    }

    private static func centroid(of points: [CGPoint]) -> CGPoint {
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }

    private static func avgDist(from center: CGPoint, to points: [CGPoint]) -> CGFloat {
        points.map { dist($0, center) }.reduce(0, +) / CGFloat(points.count)
    }

    private static func boundingRect(of points: [CGPoint]) -> CGRect {
        guard !points.isEmpty else { return .zero }
        let xs = points.map { $0.x }, ys = points.map { $0.y }
        let minX = xs.min()!, maxX = xs.max()!
        let minY = ys.min()!, maxY = ys.max()!
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private static func boundingDiagonal(of points: [CGPoint]) -> CGFloat {
        let r = boundingRect(of: points)
        return hypot(r.width, r.height)
    }

    private static func angleBetween(a: CGPoint, vertex v: CGPoint, c: CGPoint) -> CGFloat {
        let u = CGPoint(x: a.x - v.x, y: a.y - v.y)
        let w = CGPoint(x: c.x - v.x, y: c.y - v.y)
        let dot = u.x * w.x + u.y * w.y
        let len = hypot(u.x, u.y) * hypot(w.x, w.y)
        guard len > 0 else { return 0 }
        return acos(max(-1, min(1, dot / len)))
    }

    private static func triangleArea(a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
        abs((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) / 2
    }
}
