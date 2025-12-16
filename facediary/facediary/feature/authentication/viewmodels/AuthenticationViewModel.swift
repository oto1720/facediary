import SwiftUI
import Combine
import AVFoundation

/// 認証状態
enum AuthenticationState {
    case ready // 認証準備
    case scanning // 認証中
    case processing // 認証中
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

    private var cancellables = Set<AnyCancellable>()
    private var latestFrame: CVPixelBuffer?
    private var referenceFaceData: FaceData?

    // MARK: - Initialization

    init(
        cameraService: CameraService = CameraService(),
        faceRecognitionService: FaceRecognitionServiceProtocol = VisionFaceRecognitionService(),
        securityService: SecurityServiceProtocol = KeychainSecurityService()
    ) {
        self.cameraService = cameraService
        self.faceRecognitionService = faceRecognitionService
        self.securityService = securityService

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

    /// 認証
    func authenticate() {
        guard let frame = latestFrame else {
            authenticationState = .failed("有効な画像フレームがありません。")
            return
        }

        guard let referenceFaceData = referenceFaceData else {
            authenticationState = .failed("顔データがありません。")
            return
        }

        authenticationState = .processing

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let image = CIImage(cvPixelBuffer: frame)
                let result = try self.faceRecognitionService.recognizeFace(from: image, referenceFaceData: referenceFaceData)

                DispatchQueue.main.async {
                    if result.isAuthenticated {
                        self.authenticationState = .success
                    } else {
                        self.authenticationState = .failed("顔認証に失敗しました。")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.authenticationState = .failed("認証中にエラーが発生しました。\n(\(error.localizedDescription))")
                }
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
