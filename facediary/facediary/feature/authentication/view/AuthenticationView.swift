import SwiftUI

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()

    /// 認証成功時のコールバック
    var onAuthenticationSuccess: (() -> Void)?

    var body: some View {
        ZStack {
            // カメラプレビュー
            if let session = viewModel.cameraService.previewLayer.session {
                CameraPreviewView(session: session)
                    .ignoresSafeArea()
            }

            // UIオーバーレイ
            VStack {
                Spacer()

                // 状態に応じたビューを表示
                switch viewModel.authenticationState {
                case .ready, .scanning:
                    scanningInstructionsView
                case .biometricAuth:
                    ProgressView("Face ID認証中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                case .processing:
                    ProgressView("顔認証中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                case .success:
                    successView
                case .failed(let message):
                    failedView(message: message)
                }

                Spacer()

                // 認証中の場合のみボタンを表示
                if case .scanning = viewModel.authenticationState {
                    authenticateButton
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            viewModel.startCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
    }

    // MARK: - Subviews

    private var scanningInstructionsView: some View {
        VStack {
            Image(systemName: "faceid")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.white)
            Text("顔認証を開始してください")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 8)
            Text("顔をカメラに合わせてください")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(15)
    }

    private var authenticateButton: some View {
        Button(action: {
            viewModel.authenticate()
        }) {
            ZStack {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 4)
                    .frame(width: 70, height: 70)
                Circle()
                    .fill(Color.white)
                    .frame(width: 60, height: 60)
            }
        }
    }

    private var successView: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)
            Text("認証成功")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top)
        }
        .padding(30)
        .background(Color.black.opacity(0.6))
        .cornerRadius(20)
        .onAppear {
            // 1秒後に認証成功時のコールバックを呼ぶ
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onAuthenticationSuccess?()
            }
        }
    }

    private func failedView(message: String) -> some View {
        VStack {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.red)
            Text("認証失敗")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top)
            Text(message)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()

            Button("再試行") {
                viewModel.retry()
            }
            .padding()
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(10)
        }
        .padding(30)
        .background(Color.black.opacity(0.6))
        .cornerRadius(20)
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
