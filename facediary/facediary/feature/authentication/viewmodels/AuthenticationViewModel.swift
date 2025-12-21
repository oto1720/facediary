import SwiftUI
import Combine
import AVFoundation

/// 認証状態
enum AuthenticationState {
    case ready // 認証準備
    case biometricAuth // 生体認証中
    case scanning // 顔スキャン中
    case processing // 顔認証処理中
    case success // 認証成功
    case failed(String) // 認証失敗
}

class AuthenticationViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var authenticationState: AuthenticationState = .ready
    @Published var errorMessage: String?

    // MARK: - Services

    let cameraService: CameraService
    private let faceRecognitionService: FaceRecognitionServiceProtocol
    private let securityService: SecurityServiceProtocol
    private let biometricAuthService: BiometricAuthenticationServiceProtocol

    private var cancellables = Set<AnyCancellable>()
    private var latestFrame: CVPixelBuffer?
    private var referenceFaceData: FaceData?

    // MARK: - Initialization

    init(
        cameraService: CameraService = CameraService(),
        faceRecognitionService: FaceRecognitionServiceProtocol = VisionFaceRecognitionService(),
        securityService: SecurityServiceProtocol = KeychainSecurityService(),
        biometricAuthService: BiometricAuthenticationServiceProtocol = BiometricAuthenticationService()
    ) {
        self.cameraService = cameraService
        self.faceRecognitionService = faceRecognitionService
        self.securityService = securityService
        self.biometricAuthService = biometricAuthService

        setupBindings()
        loadReferenceFaceData()
    }

    // MARK: - Public Methods

    /// カメラの起動
    func startCamera() {
        authenticationState = .scanning
        Task {
            do {
                try await cameraService.setupAndStart()
            } catch {
                await MainActor.run {
                    authenticationState = .failed("カメラの起動に失敗しました。\n(\(error.localizedDescription))")
                }
            }
        }
    }

    /// カメラの停止
    func stopCamera() {
        cameraService.stop()
    }

    /// 認証（生体認証 → 顔認証の2段階認証）
    func authenticate() {
        guard let referenceFaceData = referenceFaceData else {
            authenticationState = .failed("顔データがありません。")
            return
        }

        // まず生体認証（Face ID / Touch ID）を実行
        authenticationState = .biometricAuth

        Task {
            do {
                // 生体認証を実行
                let biometricSuccess = try await biometricAuthService.authenticate()

                guard biometricSuccess else {
                    await MainActor.run {
                        authenticationState = .failed("生体認証に失敗しました。")
                    }
                    return
                }

                // 生体認証成功後、顔認証を実行
                await MainActor.run {
                    authenticationState = .processing
                }

                // 顔認証を実行
                try await performFaceRecognition(referenceFaceData: referenceFaceData)

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

    /// 顔認証を実行
    private func performFaceRecognition(referenceFaceData: FaceData) async throws {
        guard let frame = latestFrame else {
            await MainActor.run {
                authenticationState = .failed("有効な画像フレームがありません。")
            }
            return
        }

        let image = CIImage(cvPixelBuffer: frame)
        let result = try faceRecognitionService.recognizeFace(from: image, referenceFaceData: referenceFaceData)

        await MainActor.run {
            if result.isAuthenticated {
                authenticationState = .success
            } else {
                authenticationState = .failed("顔認証に失敗しました。")
            }
        }
    }

    /// 認証の再試行
    func retry() {
        authenticationState = .scanning
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // カメラの映像フレームを受け取る
        cameraService.framePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] frame in
                self?.latestFrame = frame
            }
            .store(in: &cancellables)
    }

    private func loadReferenceFaceData() {
        do {
            self.referenceFaceData = try securityService.loadFaceData()
        } catch {
            print("顔データの読み込みに失敗しました。\n(\(error.localizedDescription))")
        }
    }
}
