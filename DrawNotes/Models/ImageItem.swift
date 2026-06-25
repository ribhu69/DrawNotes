import UIKit

struct ImageItem: Identifiable {
    let id: UUID
    var imageData: Data
    var center: CGPoint
    var size: CGSize
    var rotation: CGFloat

    init(image: UIImage, center: CGPoint, size: CGSize) {
        self.id = UUID()
        // JPEG at 0.8 quality — good trade-off between size and fidelity
        self.imageData = image.jpegData(compressionQuality: 0.8) ?? Data()
        self.center = center
        self.size = size
        self.rotation = 0
    }
}

// MARK: - Codable (manual — CGPoint/CGSize are not auto-Codable)

extension ImageItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id, imageData, cx, cy, w, h, rotation
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,           forKey: .id)
        try c.encode(imageData,    forKey: .imageData)
        try c.encode(center.x,     forKey: .cx)
        try c.encode(center.y,     forKey: .cy)
        try c.encode(size.width,   forKey: .w)
        try c.encode(size.height,  forKey: .h)
        try c.encode(rotation,     forKey: .rotation)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id       = try c.decode(UUID.self,   forKey: .id)
        imageData = try c.decode(Data.self,  forKey: .imageData)
        center   = CGPoint(x: try c.decode(CGFloat.self, forKey: .cx),
                           y: try c.decode(CGFloat.self, forKey: .cy))
        size     = CGSize(width:  try c.decode(CGFloat.self, forKey: .w),
                          height: try c.decode(CGFloat.self, forKey: .h))
        rotation = try c.decode(CGFloat.self, forKey: .rotation)
    }
}
