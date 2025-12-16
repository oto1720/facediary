import Foundation

/// Analytics statistics
struct MoodStatistics {
    /// Mood distribution (count per mood)
    let moodDistribution: [Mood: Int]

    /// Total diary entries
    let totalEntries: Int

    /// Most frequent mood
    let mostFrequentMood: Mood?

    /// Entries per day (average)
    let averageEntriesPerDay: Double

    /// Date range
    let dateRange: (start: Date, end: Date)?
}

/// Analytics service protocol
protocol AnalyticsServiceProtocol {
    func calculateStatistics(for entries: [DiaryEntry]) -> MoodStatistics
    func getMoodTrend(for entries: [DiaryEntry], period: AnalyticsPeriod) -> [Date: Mood]
}

/// Analytics period
enum AnalyticsPeriod {
    case week
    case month
    case year
}

/// Analytics service implementation
class AnalyticsService: AnalyticsServiceProtocol {

    /// Calculate overall statistics
    func calculateStatistics(for entries: [DiaryEntry]) -> MoodStatistics {
        guard !entries.isEmpty else {
            return MoodStatistics(
                moodDistribution: [:],
                totalEntries: 0,
                mostFrequentMood: nil,
                averageEntriesPerDay: 0,
                dateRange: nil
            )
        }

        // Calculate mood distribution
        var moodDistribution: [Mood: Int] = [:]
        for entry in entries {
            if let primaryMood = entry.primaryMood {
                moodDistribution[primaryMood, default: 0] += 1
            }
        }

        // Find most frequent mood
        let mostFrequentMood = moodDistribution.max(by: { $0.value < $1.value })?.key

        // Calculate date range
        let sortedDates = entries.map { $0.date }.sorted()
        let dateRange: (start: Date, end: Date)? = sortedDates.isEmpty ? nil : (sortedDates.first!, sortedDates.last!)

        // Calculate average entries per day
        var averageEntriesPerDay: Double = 0
        if let dateRange = dateRange {
            let daysDifference = Calendar.current.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 0
            averageEntriesPerDay = daysDifference > 0 ? Double(entries.count) / Double(daysDifference + 1) : Double(entries.count)
        }

        return MoodStatistics(
            moodDistribution: moodDistribution,
            totalEntries: entries.count,
            mostFrequentMood: mostFrequentMood,
            averageEntriesPerDay: averageEntriesPerDay,
            dateRange: dateRange
        )
    }

    /// Get mood trend over time
    func getMoodTrend(for entries: [DiaryEntry], period: AnalyticsPeriod) -> [Date: Mood] {
        let startDate: Date
        switch period {
        case .week:
            startDate = DateHelper.startOfWeek
        case .month:
            startDate = DateHelper.startOfMonth
        case .year:
            startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        }

        let filteredEntries = entries.filter { $0.date >= startDate }

        var moodTrend: [Date: Mood] = [:]
        for entry in filteredEntries {
            let dayStart = entry.date.startOfDay
            if let primaryMood = entry.primaryMood {
                moodTrend[dayStart] = primaryMood
            }
        }

        return moodTrend
    }
}
