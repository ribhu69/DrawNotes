import SwiftUI
import PencilKit
import PhotosUI

struct NoteEditorView: View {
    @State var note: Note
    @ObservedObject var store: NoteStore
    @Environment(\.dismiss) private var dismiss

    @State private var fingerInputEnabled = false
    @State private var showTitleEditor = false
    @State private var draftTitle = ""

    // Image picker
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pendingImage: UIImage?

    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemBackground).ignoresSafeArea()

            CanvasRepresentable(
                drawing: Binding(
                    get: { note.drawing },
                    set: { newDrawing in
                        note.drawing = newDrawing
                        store.updateNote(note)
                    }
                ),
                imageItems: Binding(
                    get: { note.imageItems },
                    set: { newItems in
                        note.imageItems = newItems
                        store.updateNote(note)
                    }
                ),
                pendingImage: $pendingImage,
                fingerInputEnabled: fingerInputEnabled,
                template: note.template
            )
            .ignoresSafeArea()

            topBar
        }
        .onChange(of: selectedPhotoItem) { item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    pendingImage = image
                }
                selectedPhotoItem = nil
            }
        }
        .onDisappear {
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
            HStack(spacing: 8) {
                photoPickerButton
                templateMenu
                fingerToggle
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
    }

    private var backButton: some View {
        Button { dismiss() } label: {
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

    // MARK: - Photo Picker

    private var photoPickerButton: some View {
        PhotosPicker(
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 16, weight: .medium))
                .frame(width: 36, height: 36)
                .foregroundStyle(.secondary)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Template Menu

    private var templateMenu: some View {
        Menu {
            ForEach(CanvasTemplate.allCases, id: \.self) { t in
                Button {
                    note.template = t
                    store.updateNote(note)
                } label: {
                    Label(t.displayName, systemImage: t.iconName)
                }
            }
        } label: {
            Image(systemName: note.template == .blank ? "doc" : note.template.iconName)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 36, height: 36)
                .foregroundStyle(note.template == .blank ? .secondary : Color.accentColor)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    // MARK: - Finger Toggle

    private var fingerToggle: some View {
        TooltipButton(
            systemImage: fingerInputEnabled ? "hand.point.up.fill" : "hand.point.up",
            tooltip: fingerInputEnabled
                ? "Finger draws — tap to switch to scroll"
                : "Finger scrolls — tap to draw with finger",
            isActive: fingerInputEnabled,
            action: { fingerInputEnabled.toggle() }
        )
    }

    // MARK: - Helpers

    private func commitTitle() {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespaces)
        note.title = trimmed.isEmpty ? "New Note" : trimmed
        store.updateNote(note)
        showTitleEditor = false
    }
}
