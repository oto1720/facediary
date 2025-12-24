import SwiftUI

// MARK: - App Colors

extension Color {
    /// アプリのカラーパレット
    struct AppColors {
        // MARK: - Background Colors

        /// メインの背景色（薄明るい茶色/ベージュ）
        static let background = Color(hex: "#F5EDE0")

        /// セカンダリ背景色（少し濃いベージュ）
        static let backgroundSecondary = Color(hex: "#E8DCC8")

        /// カードやコンテナの背景（白に近いベージュ）
        static let surface = Color(hex: "#FFFBF5")

        // MARK: - Text Colors

        /// プライマリテキスト（ダークブラウン）
        static let textPrimary = Color(hex: "#3E2723")

        /// セカンダリテキスト（ミディアムブラウン）
        static let textSecondary = Color(hex: "#6D4C41")

        /// テキストの薄い色（グレーブラウン）
        static let textTertiary = Color(hex: "#A1887F")

        // MARK: - Accent Colors

        /// アクセントカラー（温かみのあるブラウン）
        static let accent = Color(hex: "#8D6E63")

        /// アクセントライト（明るいブラウン）
        static let accentLight = Color(hex: "#BCAAA4")

        /// アクセントダーク（濃いブラウン）
        static let accentDark = Color(hex: "#5D4037")

        // MARK: - UI Element Colors

        /// ボーダー/区切り線
        static let border = Color(hex: "#D7CCC8")

        /// シャドウ
        static let shadow = Color(hex: "#BCAAA4").opacity(0.3)

        /// 成功/ポジティブ（柔らかい緑）
        static let success = Color(hex: "#A5D6A7")

        /// エラー/ネガティブ（柔らかい赤）
        static let error = Color(hex: "#EF9A9A")

        /// 警告（柔らかいオレンジ）
        static let warning = Color(hex: "#FFCC80")
    }

    // MARK: - Convenience Accessors

    /// メインの背景色
    static var appBackground: Color { AppColors.background }

    /// セカンダリ背景色
    static var appBackgroundSecondary: Color { AppColors.backgroundSecondary }

    /// サーフェス（カード）色
    static var appSurface: Color { AppColors.surface }

    /// プライマリテキスト
    static var appTextPrimary: Color { AppColors.textPrimary }

    /// セカンダリテキスト
    static var appTextSecondary: Color { AppColors.textSecondary }

    /// アクセント色
    static var appAccent: Color { AppColors.accent }

    /// ボーダー色
    static var appBorder: Color { AppColors.border }
}
