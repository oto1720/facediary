import SwiftUI
import Combine

/// アプリ全体の状態を表す列挙型
enum AppState {
    case loading
    case authentication // 認証待ち
    case authenticated // 認証成功、メイン画面へ
}

/// アプリ全体の状態管理を行うViewModel
class AppViewModel: ObservableObject {

    @Published var appState: AppState = .loading

    init() {
        // 起動時は認証画面へ
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.appState = .authentication
        }
    }

    /// Transition the application state to authenticated.
    /// 
    /// Sets `appState` to `.authenticated`, indicating successful authentication and readiness to show the main interface.
    func onAuthenticationSucceeded() {
        appState = .authenticated
    }

    /// ログアウト処理（設定画面などから呼ばれることを想定）
    func logout() {
        appState = .authentication
    }
}