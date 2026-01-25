import SwiftUI

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()

    /// 認証成功時のコールバック
    var onAuthenticationSuccess: (() -> Void)?

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // 状態に応じたビューを表示
                switch viewModel.authenticationState {
                case .ready:
                    readyView
                case .biometricAuth:
                    ProgressView("認証中...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .foregroundColor(.primary)
                        .padding()
                case .success:
                    successView
                case .failed(let message):
                    failedView(message: message)
                }

                Spacer()
            }
            .padding()
        }
        .onAppear {
            // 画面表示時に自動で認証開始
            viewModel.authenticate()
        }
    }

    // MARK: - Subviews

    private var readyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "faceid")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)

            Text("Face IDで認証")
                .font(.title2)
                .fontWeight(.bold)

            Button(action: {
                viewModel.authenticate()
            }) {
                Text("認証する")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }

    private var successView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)

            Text("認証成功")
                .font(.title2)
                .fontWeight(.bold)
        }
        .onAppear {
            // 0.5秒後に認証成功時のコールバックを呼ぶ
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onAuthenticationSuccess?()
            }
        }
    }

    private func failedView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.red)

            Text("認証失敗")
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: {
                viewModel.retry()
                viewModel.authenticate()
            }) {
                Text("再試行")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
