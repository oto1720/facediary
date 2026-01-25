import SwiftUI

/// 認証状態
enum AuthenticationState {
    case ready // 認証準備
    case biometricAuth // 生体認証中
    case success // 認証成功
    case failed(String) // 認証失敗
}

class AuthenticationViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var authenticationState: AuthenticationState = .ready
    @Published var errorMessage: String?

    // MARK: - Services

    private let biometricAuthService: BiometricAuthenticationServiceProtocol

    // MARK: - Initialization

    init(
        biometricAuthService: BiometricAuthenticationServiceProtocol = BiometricAuthenticationService()
    ) {
        self.biometricAuthService = biometricAuthService
    }

    // MARK: - Public Methods

    /// Starts a biometric authentication flow and updates `authenticationState` based on the outcome.
    /// 
    /// In DEBUG builds this immediately sets `authenticationState` to `.success`. In non-DEBUG builds it sets `authenticationState` to `.biometricAuth`, invokes the biometric authenticator, and then:
    /// - sets `authenticationState` to `.success` when authentication succeeds,
    /// - sets `authenticationState` to `.failed(...)` with a user-facing message when authentication fails, mapping `BiometricAuthenticationError` cases to specific messages, or using a generic message that includes the error's `localizedDescription` for other errors.
    func authenticate() {
        // デバッグビルド時は認証をスキップ
        #if DEBUG
        authenticationState = .success
        return
        #endif

        authenticationState = .biometricAuth

        Task {
            do {
                let biometricSuccess = try await biometricAuthService.authenticate()

                await MainActor.run {
                    if biometricSuccess {
                        authenticationState = .success
                    } else {
                        authenticationState = .failed("生体認証に失敗しました。")
                    }
                }

            } catch let error as BiometricAuthenticationError {
                await MainActor.run {
                    switch error {
                    case .userCancel:
                        authenticationState = .failed("認証がキャンセルされました。")
                    case .biometryNotEnrolled:
                        authenticationState = .failed("生体認証が登録されていません。\n設定から登録してください。")
                    case .biometryLockout:
                        authenticationState = .failed("生体認証がロックされています。\nパスコードを入力してロックを解除してください。")
                    case .passcodeNotSet:
                        authenticationState = .failed("パスコードが設定されていません。")
                    case .notAvailable:
                        authenticationState = .failed("生体認証が利用できません。")
                    default:
                        authenticationState = .failed("生体認証に失敗しました。")
                    }
                }
            } catch {
                await MainActor.run {
                    authenticationState = .failed("認証中にエラーが発生しました。\n(\(error.localizedDescription))")
                }
            }
        }
    }

    /// Resets the authentication state to ready so a new authentication attempt can begin.
    func retry() {
        authenticationState = .ready
    }
}