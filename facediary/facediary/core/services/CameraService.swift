
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

    /// セッションへのアクセスを提供（プレビュー表示用）
    var captureSession: AVCaptureSession {
        return session
    }

    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var cancellables = Set<AnyCancellable>()
    private var isSetup = false
    private var firstFrameLogged = false

    override init() {
        super.init()
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        self.previewLayer.videoGravity = .resizeAspectFill
    }

    /// カメラのセットアップとセッションの開始
    func setupAndStart() async throws {
        print("[CameraService] setupAndStart called")

        // 既にセットアップ済みの場合はセッションを開始するだけ
        if isSetup {
            print("[CameraService] Already setup, just starting session")
            if !session.isRunning {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.session.startRunning()
                    print("[CameraService] Session started")
                }
            }
            return
        }

        try await checkPermissions()
        print("[CameraService] Permissions granted")

        // デバイスの取得を構成ブロックの外で行う
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("[CameraService] Front camera not found")
            throw CameraError.setupFailed("フロントカメラが見つかりません")
        }
        print("[CameraService] Camera device found: \(videoDevice.localizedName)")

        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
             print("[CameraService] Failed to create device input")
             throw CameraError.setupFailed("カメラ入力を作成できません")
        }
        print("[CameraService] Device input created successfully")

        session.beginConfiguration()
        // 構成ブロック内ではthrowしないようにする、あるいはdeferでcommitする
        // ここでは安全に構成できることがわかってからaddInput/Outputする

        // ビデオフレームをリアルタイムで取得するため、ビデオ向けのプリセットを使用
        session.sessionPreset = .high

        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
        } else {
            print("[CameraService] Failed to add input")
            session.commitConfiguration()
            throw CameraError.setupFailed("カメラ入力をセッションに追加できません")
        }

        // 静止画用の出力
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        } else {
            print("[CameraService] Failed to add photo output")
            session.commitConfiguration()
            throw CameraError.setupFailed("静止画出力をセッションに追加できません")
        }

        // 映像フレーム解析用の出力
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video_frames_queue"))
        videoOutput.alwaysDiscardsLateVideoFrames = true

        // ビデオ出力の形式を設定（kCVPixelFormatType_32BGRAは広くサポートされている）
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            print("[CameraService] Video output added successfully")

            // ビデオ接続の向きを設定
            if let connection = videoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = true
                }
                print("[CameraService] Video connection configured")
            }
        } else {
            print("[CameraService] Failed to add video output")
            session.commitConfiguration()
            throw CameraError.setupFailed("映像フレーム出力をセッションに追加できません")
        }

        session.commitConfiguration()
        print("[CameraService] Configuration committed")

        // セットアップ完了フラグを設定
        isSetup = true

        DispatchQueue.global(qos: .userInitiated).async {
            print("[CameraService] Starting session")
            self.session.startRunning()
            print("[CameraService] Session started")
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

        // フロントカメラの場合、ミラーリング設定を適用
        if let photoOutputConnection = photoOutput.connection(with: .video) {
            if photoOutputConnection.isVideoMirroringSupported {
                photoOutputConnection.isVideoMirrored = true
            }
            if photoOutputConnection.isVideoOrientationSupported {
                photoOutputConnection.videoOrientation = .portrait
            }
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    /// カメラの使用許可を確認する
    private func checkPermissions() async throws {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted {
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
            // 初回のフレームを受信したことをログに記録（頻繁なログを避けるため）
            if !firstFrameLogged {
                print("[CameraService] First video frame received")
                firstFrameLogged = true
            }
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
