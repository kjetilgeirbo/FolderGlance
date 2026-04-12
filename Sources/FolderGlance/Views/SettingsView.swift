import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var selectedFolderID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            folderListSection
            Divider()
            if let id = selectedFolderID,
               let index = appState.folders.firstIndex(where: { $0.id == id }) {
                folderSettingsSection(index: index)
            } else {
                Text("Select a folder to configure")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Divider()
            generalSettingsSection
        }
        .frame(width: 480, height: 520)
    }

    // MARK: - Folder List

    private var folderListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Folders")
                .font(.headline)

            List(selection: $selectedFolderID) {
                ForEach(appState.folders) { folder in
                    HStack {
                        Image(systemName: folder.icon)
                            .frame(width: 20)
                        VStack(alignment: .leading) {
                            Text(folder.displayName)
                            Text(folder.url.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(folder.displayMode == .separate ? "separate" : "grouped")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary)
                            .clipShape(Capsule())
                        Toggle("", isOn: Binding(
                            get: { folder.isEnabled },
                            set: { newValue in
                                if let i = appState.folders.firstIndex(where: { $0.id == folder.id }) {
                                    appState.folders[i].isEnabled = newValue
                                    appState.save()
                                }
                            }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()
                    }
                    .tag(folder.id)
                }
                .onDelete(perform: deleteFolders)
            }
            .frame(height: 160)

            HStack {
                Button("Add Folder…") { addFolder() }
                Spacer()
                Button(role: .destructive) {
                    if let id = selectedFolderID {
                        appState.folders.removeAll { $0.id == id }
                        selectedFolderID = nil
                        appState.save()
                    }
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(selectedFolderID == nil)
            }
        }
        .padding()
    }

    // MARK: - Per-Folder Settings

    private func folderSettingsSection(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Folder Settings")
                .font(.headline)

            LabeledContent("Display Name") {
                TextField("Name", text: $appState.folders[index].displayName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .onChange(of: appState.folders[index].displayName) { _, _ in appState.save() }
            }

            LabeledContent("Icon (SF Symbol)") {
                TextField("folder", text: $appState.folders[index].icon)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .onChange(of: appState.folders[index].icon) { _, _ in appState.save() }
            }

            LabeledContent("Sort By") {
                HStack {
                    Picker("", selection: $appState.folders[index].sortOrder) {
                        Text("Name").tag(FolderSortOrder.name)
                        Text("Date Modified").tag(FolderSortOrder.dateModified)
                        Text("Date Created").tag(FolderSortOrder.dateCreated)
                        Text("Size").tag(FolderSortOrder.size)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                    .onChange(of: appState.folders[index].sortOrder) { _, _ in appState.save() }

                    Button {
                        appState.folders[index].sortAscending.toggle()
                        appState.save()
                    } label: {
                        Image(systemName: appState.folders[index].sortAscending ? "arrow.up" : "arrow.down")
                    }
                }
            }

            LabeledContent("Display Mode") {
                Picker("", selection: $appState.folders[index].displayMode) {
                    Text("Separate icon").tag(DisplayMode.separate)
                    Text("Grouped menu").tag(DisplayMode.grouped)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
                .onChange(of: appState.folders[index].displayMode) { _, _ in appState.save() }
            }
        }
        .padding()
    }

    // MARK: - General Settings

    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General")
                .font(.headline)

            Toggle("Show hidden files", isOn: $appState.showHiddenFiles)
                .onChange(of: appState.showHiddenFiles) { _, _ in appState.save() }

            LabeledContent("Grouped menu icon") {
                TextField("tray.2.fill", text: $appState.groupedMenuIcon)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .onChange(of: appState.groupedMenuIcon) { _, _ in appState.save() }
            }
        }
        .padding()
    }

    // MARK: - Actions

    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder to add to FolderGlance"

        if panel.runModal() == .OK, let url = panel.url {
            let folder = FolderModel(url: url)
            appState.folders.append(folder)
            appState.save()
            selectedFolderID = folder.id
        }
    }

    private func deleteFolders(at offsets: IndexSet) {
        appState.folders.remove(atOffsets: offsets)
        appState.save()
    }
}
