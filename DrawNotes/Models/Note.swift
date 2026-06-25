import Foundation
import PencilKit

struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var drawingData: Data
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
        drawing: PKDrawing = PKDrawing()
    ) {
        self.id = id
        self.title = title
        self.drawingData = (try? drawing.dataRepresentation()) ?? Data()
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.drawingData == rhs.drawingData &&
        lhs.modifiedAt == rhs.modifiedAt
    }
}
