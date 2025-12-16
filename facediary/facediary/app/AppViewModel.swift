import SwiftUI
import Combine

/// アプリ全体の状態を表す列挙型
enum AppState {
    case loading
    case onboarding // 顔未登録
    case authentication // 顔登録済み、認証待ち
    case authenticated // 認証成功、メイン画面へ
}

/// アプリ全体の状態管理を行うViewModel
class AppViewModel: ObservableObject {

    @Published var appState: AppState = .loading

    private let securityService: SecurityServiceProtocol

    init(securityService: SecurityServiceProtocol = KeychainSecurityService()) {
        self.securityService = securityService
        checkInitialState()
    }

    /// アプリ起動時に顔データが登録されているかチェック
    func checkInitialState() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let faceData = try self.securityService.loadFaceData()
                DispatchQueue.main.async {
                    if faceData != nil {
                        // 顔データが登録済み → 認証画面へ
                        self.appState = .authentication
                    } else {
                        // 顔データが未登録 → オンボーディング画面へ
                        self.appState = .onboarding
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    // エラーが発生した場合もオンボーディングへ
                    self.appState = .onboarding
                }
            }
        }
    }

    /// 顔登録が完了した時の処理
    func onFaceRegistrationCompleted() {
        appState = .authentication
    }

    /// 顔認証が成功した時の処理
    func onAuthenticationSucceeded() {
        appState = .authenticated
    }

    /// ログアウト処理（設定画面などから呼ばれることを想定）
    func logout() {
        appState = .authentication
    }
}
