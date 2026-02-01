import SwiftUI
import Combine

/// Settings view model
class SettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var showingDeleteConfirmation = false
    @Published var showingExportSheet = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // MARK: - Services

    private let persistenceService: DataPersistenceServiceProtocol

    // MARK: - Initialization

    init(
        persistenceService: DataPersistenceServiceProtocol = FileSystemDataPersistenceService()
    ) {
        self.persistenceService = persistenceService
    }

    // MARK: - Public Methods

    /// Delete all diary entries
    func deleteAllDiaries() {
        do {
            try persistenceService.save(entries: [])
            successMessage = "すべての日記を削除しました。"
            HapticFeedback.success()
        } catch {
            errorMessage = "日記の削除に失敗しました: \(error.localizedDescription)"
            HapticFeedback.error()
        }
    }

    /// Export diary entries as JSON
    func exportDiaries() -> String? {
        do {
            let entries = try persistenceService.load()
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(entries)
            return String(data: data, encoding: .utf8)
        } catch {
            errorMessage = "日記のエクスポートに失敗しました: \(error.localizedDescription)"
            return nil
        }
    }

    /// Get app version
    func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "不明"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "不明"
        return "\(version) (ビルド \(build))"
    }
}
