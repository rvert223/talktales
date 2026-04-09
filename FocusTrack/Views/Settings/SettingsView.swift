import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddChild    = false
    @State private var editingChild: Child?
    @State private var showDeleteAlert = false
    @State private var childToDelete: Child?
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            List {

                // ── Account ───────────────────────────────────────────
                if let account = dataStore.account {
                    Section("My Account") {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(Color.blue.opacity(0.15))
                                Text(account.name.prefix(1).uppercased())
                                    .font(.title3.bold())
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 48, height: 48)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(account.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(account.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)

                        Button(role: .destructive) {
                            showLogoutAlert = true
                        } label: {
                            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }

                // ── Children ──────────────────────────────────────────
                Section {
                    ForEach(dataStore.children) { child in
                        ChildRow(child: child,
                                 isSelected: child.id == dataStore.selectedChildId) {
                            editingChild = child
                        } onSelect: {
                            dataStore.selectedChildId = child.id
                        }
                    }
                    Button {
                        showAddChild = true
                    } label: {
                        Label("Add Child Profile", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                } header: {
                    Text("Child Profiles")
                } footer: {
                    Text("Each profile stores its own session history.")
                }

                // ── About ─────────────────────────────────────────────
                Section("About FocusTrack") {
                    InfoRow(icon: "brain.head.profile", color: .blue,
                            label: "What We Track",
                            detail: "Response timing, touch patterns, task completion, and focus duration.")
                    InfoRow(icon: "lock.shield.fill", color: .green,
                            label: "Privacy",
                            detail: "All data is stored only on this device. Nothing is sent to the cloud.")
                    InfoRow(icon: "hand.raised.fill", color: .orange,
                            label: "Medical Disclaimer",
                            detail: "FocusTrack is a screening aid, not a diagnostic tool. Always consult a healthcare professional with concerns.")
                    InfoRow(icon: "info.circle", color: .purple,
                            label: "Version",
                            detail: "1.0 (MVP)")
                }

                // ── Danger zone ───────────────────────────────────────
                if !dataStore.children.isEmpty {
                    Section {
                        Button(role: .destructive) {
                            childToDelete  = dataStore.selectedChild
                            showDeleteAlert = true
                        } label: {
                            Label("Delete Selected Child's Data", systemImage: "trash")
                        }
                    } footer: {
                        Text("Permanently removes the selected child's profile and all session history.")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAddChild) {
                ChildFormView(mode: .add) { child in dataStore.addChild(child) }
            }
            .sheet(item: $editingChild) { child in
                ChildFormView(mode: .edit(child)) { updated in dataStore.updateChild(updated) }
            }
            .alert("Delete Profile?", isPresented: $showDeleteAlert, presenting: childToDelete) { child in
                Button("Delete", role: .destructive) { dataStore.deleteChild(id: child.id) }
                Button("Cancel", role: .cancel) {}
            } message: { child in
                Text("All sessions for \(child.name) will be permanently deleted.")
            }
            .alert("Log Out?", isPresented: $showLogoutAlert) {
                Button("Log Out", role: .destructive) { dataStore.logout() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need your password to log back in.")
            }
        }
    }
}

// MARK: - Child Row

private struct ChildRow: View {
    let child: Child
    let isSelected: Bool
    let onEdit: () -> Void
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    InitialsAvatar(initials: child.initials, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(child.name).font(.subheadline.weight(.semibold))
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                        }
                        Text("Age \(child.age)").font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil.circle")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let icon: String
    let color: Color
    let label: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(label).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Child Form (Add / Edit)

struct ChildFormView: View {
    enum Mode {
        case add
        case edit(Child)
    }

    let mode: Mode
    let onSave: (Child) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var age: Int
    @State private var showError = false

    init(mode: Mode, onSave: @escaping (Child) -> Void) {
        self.mode   = mode
        self.onSave = onSave
        switch mode {
        case .add:
            _name = State(initialValue: "")
            _age  = State(initialValue: 7)
        case .edit(let child):
            _name = State(initialValue: child.name)
            _age  = State(initialValue: child.age)
        }
    }

    private var title: String {
        switch mode { case .add: return "Add Child"; case .edit: return "Edit Profile" }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Child's Name") {
                    TextField("e.g. Alex", text: $name)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                }
                Section("Age") {
                    Picker("Age", selection: $age) {
                        ForEach(4...18, id: \.self) { Text("\($0) years old").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
                if showError {
                    Section {
                        Text("Please enter a name.").foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.bold()
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { showError = true; return }
        switch mode {
        case .add:
            onSave(Child(name: trimmed, age: age))
        case .edit(let existing):
            onSave(Child(id: existing.id, name: trimmed, age: age, dateAdded: existing.dateAdded))
        }
        dismiss()
    }
}
