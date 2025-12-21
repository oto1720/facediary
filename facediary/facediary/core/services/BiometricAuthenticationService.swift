import Foundation
import LocalAuthentication

/// 生体認証に関するエラー
enum BiometricAuthenticationError: Error {
    case notAvailable
    case authenticationFailed(Error)
    case userCancel
    case userFallback
    case biometryNotEnrolled
    case biometryLockout
    case passcodeNotSet
}

/// 生体認証サービスプロトコル
protocol BiometricAuthenticationServiceProtocol {
    /// 生体認証が利用可能かチェック
    func isBiometricAvailable() -> Bool

    /// 生体認証を実行
    func authenticate() async throws -> Bool
}

/// LocalAuthenticationフレームワークを利用した生体認証サービス
class BiometricAuthenticationService: BiometricAuthenticationServiceProtocol {

    private let context = LAContext()

    /// 生体認証が利用可能かチェック
    func isBiometricAvailable() -> Bool {
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if let error = error {
            print("[BiometricAuth] Biometric not available: \(error.localizedDescription)")
            return false
        }

        return canEvaluate
    }

    /// 生体認証を実行
    func authenticate() async throws -> Bool {
        let context = LAContext()
        var error: NSError?

        // 生体認証が利用可能かチェック
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                print("[BiometricAuth] Cannot evaluate policy: \(error.localizedDescription)")

                switch error.code {
                case LAError.biometryNotEnrolled.rawValue:
                    throw BiometricAuthenticationError.biometryNotEnrolled
                case LAError.passcodeNotSet.rawValue:
                    throw BiometricAuthenticationError.passcodeNotSet
                case LAError.biometryLockout.rawValue:
                    throw BiometricAuthenticationError.biometryLockout
                default:
                    throw BiometricAuthenticationError.notAvailable
                }
            }
            throw BiometricAuthenticationError.notAvailable
        }

        // 生体認証を実行
        do {
            let reason = "FaceDiaryにログインするために認証が必要です"
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)

            print("[BiometricAuth] Authentication success: \(success)")
            return success
        } catch let error as LAError {
            print("[BiometricAuth] Authentication failed: \(error.localizedDescription)")

            switch error.code {
            case .userCancel:
                throw BiometricAuthenticationError.userCancel
            case .userFallback:
                throw BiometricAuthenticationError.userFallback
            case .biometryLockout:
                throw BiometricAuthenticationError.biometryLockout
            default:
                throw BiometricAuthenticationError.authenticationFailed(error)
            }
        } catch {
            print("[BiometricAuth] Unexpected error: \(error.localizedDescription)")
            throw BiometricAuthenticationError.authenticationFailed(error)
        }
    }
}
