import SwiftUI

struct HomeView: View {
    @StateObject private var store = NoteStore()
    @State private var selectedNote: Note?
    @State private var showEditor = false

    private let columns = [
        GridItem(.adaptive(minimum: 175, maximum: 280), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if store.notes.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(store.notes) { note in
                                NoteCard(note: note)
                                    .onTapGesture { open(note) }
                                    .contextMenu { deleteMenu(for: note) }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("DrawNotes")
            .toolbar { toolbar }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .fullScreenCover(isPresented: $showEditor) {
            if let note = selectedNote {
                NoteEditorView(note: note, store: store)
            }
        }
    }

    // MARK: - Sub-views

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 72, weight: .ultraLight))
                .foregroundStyle(.tertiary)

            Text("No Notes Yet")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("Tap + to scribble something.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)

            Button("Create Note") { createAndOpen() }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: createAndOpen) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
    }

    @ViewBuilder
    private func deleteMenu(for note: Note) -> some View {
        Button(role: .destructive) {
            store.deleteNote(note)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Actions

    private func open(_ note: Note) {
        selectedNote = note
        showEditor = true
    }

    private func createAndOpen() {
        let note = store.createNote()
        selectedNote = note
        showEditor = true
    }
}
