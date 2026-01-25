import Foundation
import SwiftUI

/// Constants for the app
enum Constants {

    // MARK: - App Info

    static let appName = "FaceDiary"
    static let bundleIdentifier = "com.example.facediary"

    // MARK: - Mood Analysis

    /// Minimum mood confidence (0.0 ~ 1.0)
    static let minimumMoodConfidence: Double = 0.3

    // MARK: - Storage

    /// Diary entries file name
    static let diaryEntriesFileName = "diaryEntries.json"

    // MARK: - UI

    /// Camera aspect ratio
    static let cameraAspectRatio: CGFloat = 3.0 / 4.0

    /// Default animation duration
    static let defaultAnimationDuration: Double = 0.3

    /// Default corner radius
    static let defaultCornerRadius: CGFloat = 10

    // MARK: - Date Formats

    static let dateFormat = "yyyy/MM/dd"
    static let timeFormat = "HH:mm"
    static let dateTimeFormat = "yyyy/MM/dd HH:mm"
}
