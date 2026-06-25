import Foundation
import PencilKit

struct Note: Identifiable, Equatable {
    let id: UUID
    var title: String
    var drawingData: Data
    var template: CanvasTemplate
    var createdAt: Date
    var modifiedAt: Date

    var drawing: PKDrawing {
        get { (try? PKDrawing(data: drawingData)) ?? PKDrawing() }
        set {
            drawingData = (try? newValue.dataRepresentation()) ?? Data()
            modifiedAt = Date()
        }
    }

    init(
        id: UUID = UUID(),
        title: String = "New Note",
        drawing: PKDrawing = PKDrawing(),
        template: CanvasTemplate = .blank
    ) {
        self.id = id
        self.title = title
        self.drawingData = (try? drawing.dataRepresentation()) ?? Data()
        self.template = template
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.drawingData == rhs.drawingData &&
        lhs.template == rhs.template &&
        lhs.modifiedAt == rhs.modifiedAt
    }
}

// MARK: - Codable (manual for backward compat — template defaults to .blank)

extension Note: Codable {
    enum CodingKeys: String, CodingKey {
        case id, title, drawingData, template, createdAt, modifiedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self,   forKey: .id)
        title       = try c.decode(String.self, forKey: .title)
        drawingData = try c.decode(Data.self,   forKey: .drawingData)
        createdAt   = try c.decode(Date.self,   forKey: .createdAt)
        modifiedAt  = try c.decode(Date.self,   forKey: .modifiedAt)
        // Older saved notes won't have this key — default to .blank
        template = try c.decodeIfPresent(CanvasTemplate.self, forKey: .template) ?? .blank
    }
}
