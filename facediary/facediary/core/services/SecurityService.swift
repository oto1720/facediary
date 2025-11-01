
import Foundation
import Security

/// セキュリティ関連のエラー
enum SecurityError: Error {
    case dataConversionError
    case keychainError(status: OSStatus)
}

/// 顔データなどの機密情報を安全に管理するプロトコル
protocol SecurityServiceProtocol {
    func save(faceData: FaceData) throws
    func loadFaceData() throws -> FaceData?
    func deleteFaceData() throws
}

/// Keychainを利用して機密情報を管理するクラス
class KeychainSecurityService: SecurityServiceProtocol {

    private let service = "com.example.facediary.FaceData"
    private let account = "currentUser"

    /// Keychain操作のベースとなるクエリ
    private var baseQuery: [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    /// 顔データをKeychainに保存または更新する
    func save(faceData: FaceData) throws {
        guard let data = try? JSONEncoder().encode(faceData) else {
            throw SecurityError.dataConversionError
        }

        var query = baseQuery
        query[kSecValueData as String] = data

        // 最初に既存のアイテムを削除しようと試みる
        SecItemDelete(query as CFDictionary)

        // 新しいアイテムを追加する
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecurityError.keychainError(status: status)
        }
    }

    /// Keychainから顔データを読み込む
    func loadFaceData() throws -> FaceData? {
        var query = baseQuery
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else {
            // データが存在しない場合はnilを返す
            return nil
        }

        guard status == errSecSuccess else {
            throw SecurityError.keychainError(status: status)
        }

        guard let data = item as? Data else {
            return nil
        }

        guard let faceData = try? JSONDecoder().decode(FaceData.self, from: data) else {
            throw SecurityError.dataConversionError
        }

        return faceData
    }

    /// Keychainから顔データを削除する
    func deleteFaceData() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecurityError.keychainError(status: status)
        }
    }
}
