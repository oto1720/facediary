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

    private let securityService: SecurityServiceProtocol
    private let persistenceService: DataPersistenceServiceProtocol

    // MARK: - Initialization

    init(
        securityService: SecurityServiceProtocol = KeychainSecurityService(),
        persistenceService: DataPersistenceServiceProtocol = FileSystemDataPersistenceService()
    ) {
        self.securityService = securityService
        self.persistenceService = persistenceService
    }

    // MARK: - Public Methods

    /// Delete all face data
    func deleteFaceData() {
        do {
            try securityService.deleteFaceData()
            successMessage = "Face data has been deleted."
            HapticFeedback.success()
        } catch {
            errorMessage = "Failed to delete face data: \(error.localizedDescription)"
            HapticFeedback.error()
        }
    }

    /// Delete all diary entries
    func deleteAllDiaries() {
        do {
            try persistenceService.save(entries: [])
            successMessage = "All diary entries have been deleted."
            HapticFeedback.success()
        } catch {
            errorMessage = "Failed to delete diary entries: \(error.localizedDescription)"
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
            errorMessage = "Failed to export diaries: \(error.localizedDescription)"
            return nil
        }
    }

    /// Get app version
    func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "Version \(version) (Build \(build))"
    }
}
