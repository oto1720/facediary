import SwiftUI
import Combine

class HomeViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var diaryEntries: [DiaryEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentMonth: Date = Date()

    // MARK: - Services

    private let persistenceService: DataPersistenceServiceProtocol
    private let calendar = Calendar.current

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

    // MARK: - Calendar Methods

    func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    func entryForDate(_ date: Date) -> DiaryEntry? {
        diaryEntries.first { entry in
            calendar.isDate(entry.date, inSameDayAs: date)
        }
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
