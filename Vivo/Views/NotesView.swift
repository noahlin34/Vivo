//
//  NotesView.swift
//  Vivo
//

import SwiftUI
import SwiftData

struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HealthNote.createdAt, order: .reverse) private var notes: [HealthNote]
    @State private var showAdd = false
    @State private var selected: HealthNote? = nil
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil

    private let categories = ["Vitals", "Medications", "Lifestyle", "Questions", "Symptoms", "General"]

    private var filteredNotes: [HealthNote] {
        notes.filter { note in
            let matchesCategory = selectedCategory == nil || note.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.system(size: 28, weight: .regular, design: .serif))
                            .foregroundStyle(Color.nearBlack)
                        Text("\(notes.count) note\(notes.count == 1 ? "" : "s") saved")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mutedFg)
                    }
                    Spacer()
                    GradientAddButton(gradient: [.purpleStart, .purpleEnd]) { showAdd = true }
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 20)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.mutedFg.opacity(0.6))
                    TextField("Search notes...", text: $searchText)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .warmShadow()
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryChip(
                            title: "All",
                            gradient: [.purpleStart, .purpleEnd],
                            isSelected: selectedCategory == nil
                        ) { selectedCategory = nil }

                        ForEach(categories, id: \.self) { cat in
                            let style = CategoryStyle.forCategory(cat)
                            CategoryChip(
                                title: cat,
                                gradient: style.gradient,
                                isSelected: selectedCategory == cat
                            ) {
                                selectedCategory = selectedCategory == cat ? nil : cat
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)

                // Notes list
                if filteredNotes.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredNotes) { note in
                            Button { selected = note } label: {
                                NoteCard(note: note) {
                                    modelContext.delete(note)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 100)
            }
        }
        .background(Color.bg)
        .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showAdd) { AddNoteView() }
        .sheet(item: $selected) { note in
            NoteDetailSheet(note: note) {
                modelContext.delete(note)
                selected = nil
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 28))
                .foregroundStyle(Color.purpleStart.opacity(0.4))
                .frame(width: 64, height: 64)
                .background(Color.purpleStart.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            Text(notes.isEmpty ? "No notes yet" : "No matching notes")
                .font(.system(size: 15))
                .foregroundStyle(Color.mutedFg)
            Text(notes.isEmpty ? "Tap + to create your first note" : "Try a different search or category")
                .font(.system(size: 13))
                .foregroundStyle(Color.mutedFg.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .warmShadow()
        .padding(.horizontal, 20)
    }
}

// MARK: - Note Detail Sheet

struct NoteDetailSheet: View {
    let note: HealthNote
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false

    var body: some View {
        let style = CategoryStyle.forCategory(note.category)

        return NavigationStack {
            VStack(spacing: 0) {
                // Gradient accent
                LinearGradient(colors: style.gradient, startPoint: .leading, endPoint: .trailing)
                    .frame(height: 4)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            Text(note.title)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(Color.nearBlack)
                            Spacer()
                            Text(note.category)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(style.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(style.color.opacity(0.1))
                                .clipShape(Capsule())
                        }

                        Text(note.createdAt, format: .dateTime.weekday(.wide).month(.wide).day().year())
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mutedFg.opacity(0.6))

                        ZStack(alignment: .leading) {
                            // Left bar
                            LinearGradient(colors: style.gradient, startPoint: .top, endPoint: .bottom)
                                .frame(width: 4)
                                .clipShape(Capsule())
                                .frame(maxHeight: .infinity, alignment: .leading)

                            Text(note.content.isEmpty ? "(No content)" : note.content)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.nearBlack)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 14)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.bg)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(20)
                }

                Button {
                    onDelete()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                        Text("Delete Note")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.destructive)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.destructive.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color.cardBg)
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showEdit = true }
                }
            }
            .sheet(isPresented: $showEdit) {
                EditNoteView(note: note)
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(24)
    }
}

// MARK: - Edit Note Sheet

struct EditNoteView: View {
    let note: HealthNote
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var content: String
    @State private var category: String

    private let categories = ["Vitals", "Medications", "Lifestyle", "Questions", "Symptoms", "General"]

    init(note: HealthNote) {
        self.note = note
        _title = State(initialValue: note.title)
        _content = State(initialValue: note.content)
        _category = State(initialValue: note.category)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Note Info") {
                    TextField("Title", text: $title)
                }
                Section("Category") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            let style = CategoryStyle.forCategory(cat)
                            let isSelected = category == cat
                            Button { category = cat } label: {
                                Text(cat)
                                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                    .foregroundStyle(isSelected ? .white : Color.mutedFg)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        if isSelected {
                                            LinearGradient(colors: style.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                        } else {
                                            Color.mutedBg
                                        }
                                    }
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationCornerRadius(24)
    }

    private func save() {
        note.title = title.trimmingCharacters(in: .whitespaces)
        note.content = content.trimmingCharacters(in: .whitespaces)
        note.category = category
        dismiss()
    }
}

// MARK: - Add Note Sheet

struct AddNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var category = "General"

    private let categories = ["Vitals", "Medications", "Lifestyle", "Questions", "Symptoms", "General"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(LinearGradient(colors: [.purpleStart, .purpleEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        Text("New Note")
                            .font(.headline)
                    }
                }

                Section("Note Info") {
                    TextField("Title", text: $title)
                }

                Section("Category") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            let style = CategoryStyle.forCategory(cat)
                            let isSelected = category == cat
                            Button { category = cat } label: {
                                Text(cat)
                                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                    .foregroundStyle(isSelected ? .white : Color.mutedFg)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        if isSelected {
                                            LinearGradient(colors: style.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                        } else {
                                            Color.mutedBg
                                        }
                                    }
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationCornerRadius(24)
    }

    private func save() {
        modelContext.insert(HealthNote(
            title: title.trimmingCharacters(in: .whitespaces),
            content: content.trimmingCharacters(in: .whitespaces),
            category: category
        ))
        dismiss()
    }
}
