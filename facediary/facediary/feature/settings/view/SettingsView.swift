import SwiftUI

/// Settings view
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                List {
                    // App Info Section
                    Section(header: Text("アプリ情報")
                        .foregroundColor(Color.appTextSecondary)) {
                        HStack {
                            Text("アプリ名")
                                .foregroundColor(Color.appTextPrimary)
                            Spacer()
                            Text(Constants.appName)
                                .foregroundColor(Color.appTextSecondary)
                        }
                        .listRowBackground(Color.appSurface)

                        HStack {
                            Text("バージョン")
                                .foregroundColor(Color.appTextPrimary)
                            Spacer()
                            Text(viewModel.getAppVersion())
                                .foregroundColor(Color.appTextSecondary)
                        }
                        .listRowBackground(Color.appSurface)
                    }

                    // Data Management Section
                    Section(header: Text("データ管理")
                        .foregroundColor(Color.appTextSecondary)) {
                        Button(action: {
                            viewModel.showingExportSheet = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(Color.appAccent)
                                Text("日記をエクスポート")
                                    .foregroundColor(Color.appTextPrimary)
                            }
                        }
                        .listRowBackground(Color.appSurface)

                        Button(role: .destructive, action: {
                            viewModel.showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("すべての日記を削除")
                            }
                        }
                        .listRowBackground(Color.appSurface)
                    }

                    // About Section
                    Section(header: Text("その他")
                        .foregroundColor(Color.appTextSecondary)) {
                        Link(destination: URL(string: "https://example.com/privacy")!) {
                            HStack {
                                Image(systemName: "lock.shield")
                                    .foregroundColor(Color.appAccent)
                                Text("プライバシーポリシー")
                                    .foregroundColor(Color.appTextPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundColor(Color.appTextSecondary)
                            }
                        }
                        .listRowBackground(Color.appSurface)

                        Link(destination: URL(string: "https://example.com/terms")!) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(Color.appAccent)
                                Text("利用規約")
                                    .foregroundColor(Color.appTextPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundColor(Color.appTextSecondary)
                            }
                        }
                        .listRowBackground(Color.appSurface)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(Color.appAccent)
                }
            }
            .alert("成功", isPresented: .constant(viewModel.successMessage != nil)) {
                Button("OK") {
                    viewModel.successMessage = nil
                }
            } message: {
                if let successMessage = viewModel.successMessage {
                    Text(successMessage)
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("すべての日記を削除", isPresented: $viewModel.showingDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    viewModel.deleteAllDiaries()
                }
            } message: {
                Text("すべての日記を削除しますか？この操作は取り消せません。")
            }
            .sheet(isPresented: $viewModel.showingExportSheet) {
                if let exportData = viewModel.exportDiaries() {
                    ShareSheet(activityItems: [exportData])
                } else {
                    Text("日記のエクスポートに失敗しました")
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
