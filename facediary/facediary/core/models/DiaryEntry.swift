
import Foundation

/// 一つの日記エントリーを表す構造体
struct DiaryEntry: Identifiable, Codable {
    /// ユニークなID
    let id: UUID

    /// 作成日時
    var date: Date

    /// 日記の本文
    var text: String

    /// 撮影した写真のデータ
    /// Data型で保持し、ファイルシステムへの保存/読み込みは別途制御
    var photoData: Data?

    /// 分析された感情とその確信度
    /// 例: [.happiness: 0.8, .surprise: 0.2]
    var moodScores: [Mood: Double]

    /// 主要な感情を返す算出プロパティ
    var primaryMood: Mood? {
        moodScores.max(by: { $0.value < $1.value })?.key
    }

    init(id: UUID = UUID(), date: Date = Date(), text: String, photoData: Data?, moodScores: [Mood: Double]) {
        self.id = id
        self.date = date
        self.text = text
        self.photoData = photoData
        self.moodScores = moodScores
    }
}
