import Foundation
import UIKit
import SwiftUI

// MARK: - Image Helpers

/// Image helpers
enum ImageHelper {

    /// Convert Data to UIImage
    static func image(from data: Data?) -> UIImage? {
        guard let data = data else { return nil }
        return UIImage(data: data)
    }

    /// Convert UIImage to Data
    static func data(from image: UIImage, compressionQuality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: compressionQuality)
    }

    /// Resize the image to a target size
    static func resize(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        let rect = CGRect(origin: .zero, size: newSize)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

// MARK: - Mood Analysis Helpers

/// Mood analysis helpers
enum MoodAnalyzer {

    /// Get the primary mood from scores
    static func primaryMood(from scores: [Mood: Double]) -> Mood? {
        return scores.max(by: { $0.value < $1.value })?.key
    }

    /// Get the sorted moods from scores
    static func sortedMoods(from scores: [Mood: Double]) -> [(mood: Mood, score: Double)] {
        return scores.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    /// Get the percentage string from a score
    static func percentageString(from score: Double) -> String {
        return String(format: "%.0f%%", score * 100)
    }
}

// MARK: - Date Helpers

/// Date helpers
enum DateHelper {

    /// Get the today's date
    static var today: Date {
        return Date()
    }

    /// Get the yesterday's date
    static var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
    }

    /// Get the start of the week
    static var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        return calendar.date(from: components) ?? today
    }

    /// Get the start of the month
    static var startOfMonth: Date {
        return today.startOfMonth
    }

    /// Get the relative string for a date

    /// Get the date range from a start date to an end date
    static func dateRange(from startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate

        while currentDate <= endDate {
            dates.append(currentDate)
            guard let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return dates
    }
}

// MARK: - Validation Helpers

/// Validation helpers
enum Validator {

    /// Check if the string is not empty
    static func isNotEmpty(_ string: String) -> Bool {
        return !string.isBlank
    }

    /// Check if the diary text is valid
    static func isValidDiaryText(_ text: String) -> Bool {
        return isNotEmpty(text) && text.count >= 1 && text.count <= 10000
    }

    /// Check if the image data is valid
    static func isValidImageData(_ data: Data?) -> Bool {
        guard let data = data else { return false }
        return data.count > 0 && data.count < 10_000_000 // 10MB
    }
}

// MARK: - Haptic Feedback

/// Haptic feedback helpers
enum HapticFeedback {

    /// Trigger a success haptic feedback
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Trigger an error haptic feedback
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Trigger a warning haptic feedback
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Trigger a selection haptic feedback
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    /// Trigger a light impact haptic feedback
    static func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
