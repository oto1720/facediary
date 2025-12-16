
import Foundation
import AVFoundation
import Combine
import UIKit

/// カメラサービスに関するエラー
enum CameraError: Error {
    case permissionDenied
    case setupFailed(String)
    case captureFailed
}

/// カメラの制御と映像フレームの提供を行うサービス
class CameraService: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    /// カメラのプレビューを表示するためのレイヤー
    @Published var previewLayer: AVCaptureVideoPreviewLayer!

    /// 撮影した静止画を通知するためのPublisher
    let photoPublisher = PassthroughSubject<Data, Error>()

    /// 映像フレームをリアルタイムで通知するためのPublisher
    let framePublisher = PassthroughSubject<CVPixelBuffer, Never>()

    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        self.previewLayer.videoGravity = .resizeAspectFill
    }

    /// カメラのセットアップとセッションの開始
    func setupAndStart() throws {
        try checkPermissions()
        session.beginConfiguration()

        session.sessionPreset = .photo

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw CameraError.setupFailed("フロントカメラが見つかりません")
        }

        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoDeviceInput) else {
            throw CameraError.setupFailed("カメラ入力をセッションに追加できません")
        }
        session.addInput(videoDeviceInput)

        // 静止画用の出力
        guard session.canAddOutput(photoOutput) else {
            throw CameraError.setupFailed("静止画出力をセッションに追加できません")
        }
        session.addOutput(photoOutput)

        // 映像フレーム解析用の出力
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video_frames_queue"))
        guard session.canAddOutput(videoOutput) else {
            throw CameraError.setupFailed("映像フレーム出力をセッションに追加できません")
        }
        session.addOutput(videoOutput)

        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    /// セッションの停止
    func stop() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    /// 写真を撮影する
    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    /// カメラの使用許可を確認する
    private func checkPermissions() throws {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            // 権限リクエストの結果を同期的に待つ
            var permissionGranted = false
            let semaphore = DispatchSemaphore(value: 0)

            AVCaptureDevice.requestAccess(for: .video) { granted in
                permissionGranted = granted
                semaphore.signal()
            }

            semaphore.wait()

            if !permissionGranted {
                throw CameraError.permissionDenied
            }
        default:
            throw CameraError.permissionDenied
        }
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            framePublisher.send(pixelBuffer)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            photoPublisher.send(completion: .failure(error))
            return
        }

        guard let imageData = photo.fileDataRepresentation() else {
            photoPublisher.send(completion: .failure(CameraError.captureFailed))
            return
        }
        photoPublisher.send(imageData)
    }
}
