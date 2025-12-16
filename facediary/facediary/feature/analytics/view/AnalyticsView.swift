import SwiftUI

/// Analytics view
struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .padding()
                } else if let statistics = viewModel.statistics {
                    VStack(spacing: 24) {
                        // Overall Statistics
                        overallStatisticsView(statistics: statistics)

                        Divider()

                        // Mood Distribution
                        moodDistributionView(statistics: statistics)

                        Divider()

                        // Period Selector
                        periodSelectorView

                        // Mood Trend
                        moodTrendView
                    }
                    .padding()
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Subviews

    private func overallStatisticsView(statistics: MoodStatistics) -> some View {
        VStack(spacing: 16) {
            Text("Overall Statistics")
                .font(.headline)

            HStack(spacing: 20) {
                statCard(
                    title: "Total Entries",
                    value: "\(statistics.totalEntries)",
                    icon: "book.fill"
                )

                statCard(
                    title: "Avg. Entries/Day",
                    value: String(format: "%.1f", statistics.averageEntriesPerDay),
                    icon: "calendar"
                )
            }

            if let mostFrequentMood = statistics.mostFrequentMood {
                VStack {
                    Text("Most Frequent Mood")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        Text(mostFrequentMood.emoji)
                            .font(.system(size: 40))
                        Text(mostFrequentMood.rawValue)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.color(for: mostFrequentMood).opacity(0.2))
                .cornerRadius(15)
            }
        }
    }

    private func moodDistributionView(statistics: MoodStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Distribution")
                .font(.headline)

            if statistics.moodDistribution.isEmpty {
                Text("No mood data available")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                let sortedMoods = statistics.moodDistribution.sorted { $0.value > $1.value }
                ForEach(sortedMoods, id: \.key) { mood, count in
                    moodDistributionRow(mood: mood, count: count, total: statistics.totalEntries)
                }
            }
        }
    }

    private func moodDistributionRow(mood: Mood, count: Int, total: Int) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(mood.emoji)
                    .font(.title2)
                Text(mood.rawValue)
                    .font(.body)
                Spacer()
                Text("\(count)")
                    .font(.headline)
                Text("(\(String(format: "%.0f%%", Double(count) / Double(total) * 100)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.color(for: mood))
                        .frame(width: geometry.size.width * CGFloat(count) / CGFloat(total), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
    }

    private var periodSelectorView: some View {
        HStack(spacing: 12) {
            periodButton(title: "Week", period: .week)
            periodButton(title: "Month", period: .month)
            periodButton(title: "Year", period: .year)
        }
    }

    private func periodButton(title: String, period: AnalyticsPeriod) -> some View {
        Button(action: {
            viewModel.updatePeriod(period)
        }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(viewModel.selectedPeriod == period ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(viewModel.selectedPeriod == period ? Color.blue : Color(.systemGray6))
                .cornerRadius(8)
        }
    }

    private var moodTrendView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Trend")
                .font(.headline)

            if viewModel.moodTrend.isEmpty {
                Text("No mood trend data for the selected period")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                let sortedTrend = viewModel.moodTrend.sorted { $0.key < $1.key }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 8) {
                    ForEach(sortedTrend, id: \.key) { date, mood in
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.title3)
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color.color(for: mood).opacity(0.2))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.secondary)

            Text("No Data Available")
                .font(.title2)
                .fontWeight(.bold)

            Text("Create some diary entries to see your mood analytics")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
    }
}
