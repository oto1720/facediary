
import Foundation

/// データ永続化に関するエラー
enum PersistenceError: Error {
    case fileNotFound
    case encodingFailed(Error)
    case decodingFailed(Error)
    case writingFailed(Error)
    case readingFailed(Error)
}

/// 日記データの永続化を管理するプロトコル
protocol DataPersistenceServiceProtocol {
    func save(entries: [DiaryEntry]) throws
    func load() throws -> [DiaryEntry]
}

/// ファイルシステムを利用して日記データをJSON形式で保存・管理するクラス
class FileSystemDataPersistenceService: DataPersistenceServiceProtocol {

    private var fileURL: URL {
        do {
            let documentsDirectory = try FileManager.default.url(for: .documentDirectory,
                                                                 in: .userDomainMask,
                                                                 appropriateFor: nil,
                                                                 create: true)
            return documentsDirectory.appendingPathComponent("diaryEntries.json")
        } catch {
            // 本来はエラーハンドリングが必要だが、ここでは強制的にクラッシュさせる
            fatalError("ドキュメントディレクトリの取得に失敗しました: \(error)")
        }
    }

    /// 日記エントリーの配列をファイルに保存する
    /// - Parameter entries: 保存する日記エントリーの配列
    func save(entries: [DiaryEntry]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(entries)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw PersistenceError.writingFailed(error)
        }
    }

    /// ファイルから日記エントリーの配列を読み込む
    /// - Returns: 読み込んだ日記エントリーの配列
    func load() throws -> [DiaryEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            // ファイルが存在しない場合は空の配列を返す
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let data = try Data(contentsOf: fileURL)
            let entries = try decoder.decode([DiaryEntry].self, from: data)
            return entries
        } catch {
            throw PersistenceError.decodingFailed(error)
        }
    }
}
