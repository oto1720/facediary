import SwiftUI

struct FaceRegistrationView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    /// 登録完了時のコールバック
    var onComplete: (() -> Void)?

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
                switch viewModel.registrationState {
                case .initial, .capturing:
                    captureInstructionsView
                case .processing:
                    ProgressView("顔データを処理中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                case .completed:
                    completionView
                case .failed(let error):
                    errorView(error: error)
                }

                Spacer()

                // 撮影ボタンエリア
                if case .capturing = viewModel.registrationState {
                    captureButton
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
        .navigationTitle("顔の登録")
        .navigationBarHidden(true)
    }

    // MARK: - Subviews

    private var captureInstructionsView: some View {
        VStack {
            Text("顔を登録します")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text("画面の枠内に顔を合わせてください")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 8)
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(15)
    }

    private var captureButton: some View {
        Button(action: {
            viewModel.registerFace()
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

    private var completionView: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)
            Text("登録が完了しました！")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top)

            Button(action: {
                onComplete?()
            }) {
                Text("次へ")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .padding(30)
        .background(Color.black.opacity(0.6))
        .cornerRadius(20)
    }

    private func errorView(error: Error) -> some View {
        VStack {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.red)
            Text("登録に失敗しました")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top)
            Text(viewModel.errorMessage ?? "不明なエラーです")
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()

            Button("再試行") {
                viewModel.startCamera() // 状態をリセットして再開
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

struct FaceRegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        FaceRegistrationView()
    }
}
