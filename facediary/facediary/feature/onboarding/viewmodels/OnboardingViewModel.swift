
import SwiftUI
import Combine
import AVFoundation

/// 顔登録プロセスの状態を表す
enum OnboardingRegistrationState {
    case initial
    case capturing
    case processing
    case completed
    case failed(Error)
}

class OnboardingViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var registrationState: OnboardingRegistrationState = .initial
    @Published var errorMessage: String?

    // MARK: - Services

    let cameraService: CameraService
    private let faceRecognitionService: FaceRecognitionServiceProtocol
    private let securityService: SecurityServiceProtocol

    private var cancellables = Set<AnyCancellable>()
    private var latestFrame: CVPixelBuffer?

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
    }

    // MARK: - Public Methods

    /// カメラのセットアップと起動
    func startCamera() {
        registrationState = .capturing
        do {
            try cameraService.setupAndStart()
        } catch {
            registrationState = .failed(error)
            errorMessage = "カメラの起動に失敗しました。\n(\(error.localizedDescription))"
        }
    }

    /// カメラの停止
    func stopCamera() {
        cameraService.stop()
    }

    /// 顔登録を実行する
    func registerFace() {
        guard let frame = latestFrame else {
            registrationState = .failed(FaceRecognitionError.invalidImage)
            errorMessage = "有効な画像フレームがありません。"
            return
        }

        registrationState = .processing

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let image = CIImage(cvPixelBuffer: frame)
                let faceData = try self.faceRecognitionService.generateFaceData(from: image)
                try self.securityService.save(faceData: faceData)

                DispatchQueue.main.async {
                    self.registrationState = .completed
                }
            } catch {
                DispatchQueue.main.async {
                    self.registrationState = .failed(error)
                    self.errorMessage = "顔の登録に失敗しました。\n(\(error.localizedDescription))"
                }
            }
        }
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // カメラサービスから最新の映像フレームを受け取る
        cameraService.framePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] frame in
                self?.latestFrame = frame
            }
            .store(in: &cancellables)
    }
}
