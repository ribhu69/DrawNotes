import SwiftUI
import PencilKit

struct NoteEditorView: View {
    @State var note: Note
    @ObservedObject var store: NoteStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Toolbar state
    @State private var shapeRecognitionEnabled = true
    @State private var fingerInputEnabled = false
    @State private var showTitleEditor = false
    @State private var draftTitle = ""

    var body: some View {
        ZStack(alignment: .top) {
            // Full-screen canvas — drawing binding backed by the note
            CanvasRepresentable(
                drawing: Binding(
                    get: { note.drawing },
                    set: { newDrawing in
                        note.drawing = newDrawing
                        store.updateNote(note)
                    }
                ),
                shapeRecognitionEnabled: shapeRecognitionEnabled,
                fingerInputEnabled: fingerInputEnabled
            )
            .ignoresSafeArea()

            // Floating top bar
            topBar
        }
        .onDisappear {
            // Commit title edit on close even if the user didn't press return
            if showTitleEditor {
                note.title = draftTitle
                store.updateNote(note)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 10) {
            backButton
            Spacer()
            titleControl
            Spacer()
            controlRow
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var titleControl: some View {
        if showTitleEditor {
            TextField("Title", text: $draftTitle)
                .font(.headline)
                .multilineTextAlignment(.center)
                .submitLabel(.done)
                .onSubmit { commitTitle() }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial, in: Capsule())
                .frame(maxWidth: 280)
                .onAppear { draftTitle = note.title }
        } else {
            Button {
                draftTitle = note.title
                showTitleEditor = true
            } label: {
                Text(note.title)
                    .font(.headline)
                    .lineLimit(1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var controlRow: some View {
        HStack(spacing: 8) {
            // Finger / pencil toggle
            Button {
                fingerInputEnabled.toggle()
            } label: {
                Image(systemName: fingerInputEnabled ? "hand.point.up.fill" : "hand.point.up")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 36, height: 36)
                    .foregroundStyle(fingerInputEnabled ? Color.accentColor : .secondary)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)

            // Shape recognition toggle
            Button {
                shapeRecognitionEnabled.toggle()
            } label: {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 36, height: 36)
                    .foregroundStyle(shapeRecognitionEnabled ? Color.accentColor : .secondary)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func commitTitle() {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespaces)
        note.title = trimmed.isEmpty ? "New Note" : trimmed
        store.updateNote(note)
        showTitleEditor = false
    }
}
