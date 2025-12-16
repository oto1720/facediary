import SwiftUI
import Combine

class HomeViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var diaryEntries: [DiaryEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Services

    private let persistenceService: DataPersistenceServiceProtocol

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(persistenceService: DataPersistenceServiceProtocol = FileSystemDataPersistenceService()) {
        self.persistenceService = persistenceService
        loadDiaryEntries()
    }

    // MARK: - Public Methods

    func loadDiaryEntries() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let entries = try self.persistenceService.load()
                DispatchQueue.main.async {
                    self.diaryEntries = entries.sorted { $0.date > $1.date }
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load diary entries: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    func addDiaryEntry(_ entry: DiaryEntry) {
        diaryEntries.insert(entry, at: 0)
        saveDiaryEntries()
    }

    func deleteDiaryEntry(at offsets: IndexSet) {
        diaryEntries.remove(atOffsets: offsets)
        saveDiaryEntries()
    }

    // MARK: - Private Methods

    private func saveDiaryEntries() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.persistenceService.save(entries: self.diaryEntries)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to save diary entries: \(error.localizedDescription)"
                }
            }
        }
    }
}
