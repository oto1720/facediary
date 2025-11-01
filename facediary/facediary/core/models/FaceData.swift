
import Foundation

/// 顔認証データや分析結果を保持する構造体
struct FaceData: Codable {
    /// ユーザーを一位に識別するためのID
    var userID: UUID

    /// 顔の特徴点を表すデータ
    /// Vision FrameworkのVNFaceObservationから取得したデータを保存することを想定
    var faceObservations: Data

    /// 登録日時
    var createdAt: Date
}
