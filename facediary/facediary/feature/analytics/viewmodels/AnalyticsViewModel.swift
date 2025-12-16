import SwiftUI
import Combine

/// Analytics view model
class AnalyticsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var statistics: MoodStatistics?
    @Published var selectedPeriod: AnalyticsPeriod = .month
    @Published var moodTrend: [Date: Mood] = [:]
    @Published var isLoading = false

    // MARK: - Services

    private let analyticsService: AnalyticsServiceProtocol
    private let persistenceService: DataPersistenceServiceProtocol

    private var entries: [DiaryEntry] = []

    // MARK: - Initialization

    init(
        analyticsService: AnalyticsServiceProtocol = AnalyticsService(),
        persistenceService: DataPersistenceServiceProtocol = FileSystemDataPersistenceService()
    ) {
        self.analyticsService = analyticsService
        self.persistenceService = persistenceService
        loadData()
    }

    // MARK: - Public Methods

    /// Load diary entries and calculate statistics
    func loadData() {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let entries = try self.persistenceService.load()
                self.entries = entries

                let statistics = self.analyticsService.calculateStatistics(for: entries)
                let moodTrend = self.analyticsService.getMoodTrend(for: entries, period: self.selectedPeriod)

                DispatchQueue.main.async {
                    self.statistics = statistics
                    self.moodTrend = moodTrend
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }

    /// Update selected period
    func updatePeriod(_ period: AnalyticsPeriod) {
        selectedPeriod = period
        moodTrend = analyticsService.getMoodTrend(for: entries, period: period)
    }
}
