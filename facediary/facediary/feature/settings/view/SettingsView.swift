import SwiftUI

/// Settings view
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) var dismiss

    /// Callback for when face data is deleted
    var onFaceDataDeleted: (() -> Void)?

    var body: some View {
        NavigationStack {
            List {
                // App Info Section
                Section(header: Text("App Info")) {
                    HStack {
                        Text("App Name")
                        Spacer()
                        Text(Constants.appName)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.getAppVersion())
                            .foregroundColor(.secondary)
                    }
                }

                // Data Management Section
                Section(header: Text("Data Management")) {
                    Button(action: {
                        viewModel.showingExportSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Diary Entries")
                        }
                    }

                    Button(role: .destructive, action: {
                        viewModel.showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete All Diaries")
                        }
                    }
                }

                // Security Section
                Section(header: Text("Security")) {
                    Button(role: .destructive, action: {
                        viewModel.deleteFaceData()
                        onFaceDataDeleted?()
                    }) {
                        HStack {
                            Image(systemName: "faceid")
                            Text("Reset Face Data")
                        }
                    }
                }

                // About Section
                Section(header: Text("About")) {
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Image(systemName: "lock.shield")
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
                Button("OK") {
                    viewModel.successMessage = nil
                }
            } message: {
                if let successMessage = viewModel.successMessage {
                    Text(successMessage)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("Delete All Diaries", isPresented: $viewModel.showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    viewModel.deleteAllDiaries()
                }
            } message: {
                Text("Are you sure you want to delete all diary entries? This action cannot be undone.")
            }
            .sheet(isPresented: $viewModel.showingExportSheet) {
                if let exportData = viewModel.exportDiaries() {
                    ShareSheet(activityItems: [exportData])
                } else {
                    Text("Failed to export diaries")
                }
            }
        }
    }
}

/// Share sheet for exporting data
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
