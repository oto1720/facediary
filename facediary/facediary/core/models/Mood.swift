import Foundation

/// ユーザーの感情や気分を表す列挙型
public enum Mood: String, CaseIterable, Codable {
    case happiness = "喜び"
    case sadness = "悲しみ"
    case anger = "怒り"
    case surprise = "驚き"
    case calm = "穏やか"
    case neutral = "普通"

    /// 各感情に対応する絵文字
    public var emoji: String {
        switch self {
        case .happiness:
            return "😄"
        case .sadness:
            return "😢"
        case .anger:
            return "😠"
        case .surprise:
            return "😮"
        case .calm:
            return "😌"
        case .neutral:
            return "😐"
        }
    }
}
