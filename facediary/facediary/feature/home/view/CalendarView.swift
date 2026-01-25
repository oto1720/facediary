import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: HomeViewModel
    let onDateSelected: (DiaryEntry) -> Void

    private let calendar = Calendar.current
    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 16) {
            // 月ナビゲーション
            monthNavigationHeader

            // 曜日ヘッダー
            weekdayHeader

            // カレンダーグリッド
            calendarGrid
        }
        .padding()
    }

    // MARK: - 月ナビゲーション

    private var monthNavigationHeader: some View {
        HStack {
            Button(action: {
                viewModel.previousMonth()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(Color.appTextPrimary)
                    .padding(8)
            }

            Spacer()

            Text(monthYearString)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.appTextPrimary)

            Spacer()

            Button(action: {
                viewModel.nextMonth()
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(Color.appTextPrimary)
                    .padding(8)
            }
        }
    }

    // MARK: - 曜日ヘッダー

    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(symbol == "日" ? .red : (symbol == "土" ? .blue : Color.appTextSecondary))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - カレンダーグリッド

    private var calendarGrid: some View {
        let days = generateDaysInMonth()

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    dayCell(for: date)
                } else {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }

    // MARK: - 日付セル

    private func dayCell(for date: Date) -> some View {
        let entry = viewModel.entryForDate(date)
        let isToday = calendar.isDateInToday(date)
        let dayNumber = calendar.component(.day, from: date)
        let weekday = calendar.component(.weekday, from: date)

        return Button(action: {
            if let entry = entry {
                onDateSelected(entry)
            }
        }) {
            VStack(spacing: 2) {
                Text("\(dayNumber)")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(dayTextColor(weekday: weekday, isToday: isToday))

                if let entry = entry, let mood = entry.primaryMood {
                    Text(mood.emoji)
                        .font(.system(size: 20))
                } else {
                    Text(" ")
                        .font(.system(size: 20))
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isToday ? Color.appAccent.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? Color.appAccent : Color.clear, lineWidth: 2)
            )
        }
        .disabled(entry == nil)
    }

    // MARK: - Helper Methods

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: viewModel.currentMonth)
    }

    private func dayTextColor(weekday: Int, isToday: Bool) -> Color {
        if isToday {
            return Color.appAccent
        }
        switch weekday {
        case 1: // 日曜日
            return .red
        case 7: // 土曜日
            return .blue
        default:
            return Color.appTextPrimary
        }
    }

    private func generateDaysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: viewModel.currentMonth) else {
            return []
        }

        var days: [Date?] = []

        // 月の最初の週の開始日から始める（前月の日を含む場合がある）
        let firstDayOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        // 月の最初の日までの空白を追加（日曜始まり: weekday 1 = 日曜日）
        for _ in 1..<firstWeekday {
            days.append(nil)
        }

        // 月の日数を取得
        guard let range = calendar.range(of: .day, in: .month, for: viewModel.currentMonth) else {
            return days
        }

        // 月の各日を追加
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }

        return days
    }
}

#Preview {
    CalendarView(viewModel: HomeViewModel()) { entry in
        print("Selected: \(entry.date)")
    }
}
