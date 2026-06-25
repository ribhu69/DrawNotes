import SwiftUI
import PencilKit

struct NoteCard: View {
    let note: Note
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            previewArea
                .frame(height: 160)

            infoArea
        }
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.28 : 0.08),
            radius: 10, x: 0, y: 3
        )
    }

    // MARK: - Sub-views

    private var previewArea: some View {
        ZStack {
            Color(UIColor.systemBackground)

            if let img = thumbnail {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(12)
            } else {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 36))
                    .foregroundStyle(.quaternary)
            }
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 14,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 14,
                style: .continuous
            )
        )
    }

    private var infoArea: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(note.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            Text(note.modifiedAt, format: .dateTime.month(.abbreviated).day().year())
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    // MARK: - Thumbnail

    private var thumbnail: UIImage? {
        let d = note.drawing
        let bounds = d.bounds
        guard !bounds.isEmpty, bounds.width > 2, bounds.height > 2 else { return nil }
        return d.image(from: bounds, scale: UIScreen.main.scale * 0.25)
    }
}
