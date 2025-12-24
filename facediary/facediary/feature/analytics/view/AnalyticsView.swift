import SwiftUI

/// Analytics view
struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                ScrollView {
                    if viewModel.isLoading {
                        ProgressView("読み込み中...")
                            .tint(Color.appAccent)
                            .padding()
                    } else if let statistics = viewModel.statistics {
                        VStack(spacing: 24) {
                            // Overall Statistics
                            overallStatisticsView(statistics: statistics)

                            Divider()
                                .background(Color.appBorder)

                            // Mood Distribution
                            moodDistributionView(statistics: statistics)

                            Divider()
                                .background(Color.appBorder)

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
            }
            .navigationTitle("分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appSurface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Subviews

    private func overallStatisticsView(statistics: MoodStatistics) -> some View {
        VStack(spacing: 16) {
            Text("全体の統計")
                .font(.headline)
                .foregroundColor(Color.appTextPrimary)

            HStack(spacing: 20) {
                statCard(
                    title: "合計エントリー数",
                    value: "\(statistics.totalEntries)",
                    icon: "book.fill"
                )

                statCard(
                    title: "1日平均",
                    value: String(format: "%.1f", statistics.averageEntriesPerDay),
                    icon: "calendar"
                )
            }

            if let mostFrequentMood = statistics.mostFrequentMood {
                VStack {
                    Text("最も多い気分")
                        .font(.subheadline)
                        .foregroundColor(Color.appTextSecondary)
                    HStack {
                        Text(mostFrequentMood.emoji)
                            .font(.system(size: 40))
                        Text(mostFrequentMood.rawValue)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.appTextPrimary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.color(for: mostFrequentMood).opacity(0.15))
                .cornerRadius(15)
            }
        }
    }

    private func moodDistributionView(statistics: MoodStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("気分の分布")
                .font(.headline)
                .foregroundColor(Color.appTextPrimary)

            if statistics.moodDistribution.isEmpty {
                Text("気分データがありません")
                    .foregroundColor(Color.appTextSecondary)
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
                    .foregroundColor(Color.appTextPrimary)
                Spacer()
                Text("\(count)")
                    .font(.headline)
                    .foregroundColor(Color.appTextPrimary)
                Text("(\(String(format: "%.0f%%", Double(count) / Double(total) * 100)))")
                    .font(.caption)
                    .foregroundColor(Color.appTextSecondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appBackgroundSecondary)
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
            periodButton(title: "週", period: .week)
            periodButton(title: "月", period: .month)
            periodButton(title: "年", period: .year)
        }
    }

    private func periodButton(title: String, period: AnalyticsPeriod) -> some View {
        Button(action: {
            viewModel.updatePeriod(period)
        }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(viewModel.selectedPeriod == period ? Color.appSurface : Color.appTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(viewModel.selectedPeriod == period ? Color.appAccent : Color.appBackgroundSecondary)
                .cornerRadius(8)
        }
    }

    private var moodTrendView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("気分の推移")
                .font(.headline)
                .foregroundColor(Color.appTextPrimary)

            if viewModel.moodTrend.isEmpty {
                Text("選択した期間の気分データがありません")
                    .foregroundColor(Color.appTextSecondary)
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
                                .foregroundColor(Color.appTextSecondary)
                        }
                        .padding(8)
                        .background(Color.color(for: mood).opacity(0.15))
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
                .foregroundColor(Color.appAccent)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.appTextPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.appSurface)
        .cornerRadius(15)
        .shadow(color: Color.AppColors.shadow, radius: 3, x: 0, y: 2)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(Color.appTextSecondary)

            Text("データがありません")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.appTextPrimary)

            Text("日記を作成して気分の分析を見ましょう")
                .font(.body)
                .foregroundColor(Color.appTextSecondary)
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
