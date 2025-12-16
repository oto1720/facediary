import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {
    /// Convert date to string with specified format
    func formatted(as format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }

    /// Get date at start of day (midnight)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Check if same day as another date
    func isSameDay(as otherDate: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: otherDate)
    }

    /// Add specified number of days
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Get first day of month
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    /// Get last day of month
    var endOfMonth: Date {
        guard let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)),
              let end = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: start) else {
            return self
        }
        return end
    }
}

// MARK: - String Extensions

extension String {
    /// Check if string is blank (empty or whitespace only)
    var isBlank: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Truncate string to specified length
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        }
        return self
    }
}

// MARK: - Color Extensions

extension Color {
    /// Get color for mood
    static func color(for mood: Mood) -> Color {
        switch mood {
        case .happiness:
            return .yellow
        case .sadness:
            return .blue
        case .anger:
            return .red
        case .surprise:
            return .orange
        case .calm:
            return .green
        case .neutral:
            return .gray
        }
    }

    /// Create color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Array Extensions

extension Array where Element == DiaryEntry {
    /// Filter entries within date range
    func filtered(from startDate: Date, to endDate: Date) -> [DiaryEntry] {
        return filter { entry in
            entry.date >= startDate && entry.date <= endDate
        }
    }

    /// Filter entries by mood
    func filtered(by mood: Mood) -> [DiaryEntry] {
        return filter { entry in
            entry.primaryMood == mood
        }
    }

    /// Group entries by date
    func groupedByDate() -> [Date: [DiaryEntry]] {
        return Dictionary(grouping: self) { entry in
            entry.date.startOfDay
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply custom corner radius (iOS 13 compatible)
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Custom Shapes

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
