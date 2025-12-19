import Foundation
import Vision
import CoreML
import UIKit

/// 顔認識と感情分析の結果
struct FaceRecognitionResult {
    /// 本人であるかどうかの認証結果
    let isAuthenticated: Bool
    /// 分析された感情スコア
    let moodScores: [Mood: Double]
}

/// 顔認識と感情分析に関するエラー
enum FaceRecognitionError: Error {
    case faceNotDetected
    case featureExtractionFailed
    case recognitionFailed(Error)
    case invalidImage
}

/// 顔認識と感情分析サービスプロトコル
protocol FaceRecognitionServiceProtocol {
    /// 画像から顔データを生成する（初期登録用）
    func generateFaceData(from image: CIImage) throws -> FaceData

    /// 画像から顔認証と感情分析を行う
    func recognizeFace(from image: CIImage, referenceFaceData: FaceData) throws -> FaceRecognitionResult
}

/// Visionフレームワークを利用した顔認識サービスクラス
class VisionFaceRecognitionService: FaceRecognitionServiceProtocol {

    /// 画像から顔の特徴（ランドマーク）を抽出するリクエスト
    private func createFaceLandmarksRequest() -> VNDetectFaceLandmarksRequest {
        return VNDetectFaceLandmarksRequest()
    }

    /// Visionリクエストを実行する共通ハンドラ
    private func performVisionRequest(on image: CIImage, requests: [VNRequest]) throws -> [Any]? {
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        try handler.perform(requests)
        return requests.flatMap { $0.results }
    }

    /// 顔登録のために、画像からFaceDataを生成する
    func generateFaceData(from image: CIImage) throws -> FaceData {
        print("[FaceRecognition] Starting face data generation")
        print("[FaceRecognition] Image size: \(image.extent)")

        let request = createFaceLandmarksRequest()
        let handler = VNImageRequestHandler(ciImage: image, options: [:])

        do {
            try handler.perform([request])
            print("[FaceRecognition] Vision request performed successfully")
        } catch {
            print("[FaceRecognition] Vision request failed: \(error)")
            throw FaceRecognitionError.recognitionFailed(error)
        }

        guard let results = request.results as? [VNFaceObservation] else {
            print("[FaceRecognition] Failed to get face observations from results")
            throw FaceRecognitionError.faceNotDetected
        }

        print("[FaceRecognition] Found \(results.count) face(s)")

        guard let observation = results.first else {
            print("[FaceRecognition] No faces detected")
            throw FaceRecognitionError.faceNotDetected
        }

        guard let landmarks = observation.landmarks else {
            print("[FaceRecognition] No landmarks found")
            throw FaceRecognitionError.faceNotDetected
        }

        print("[FaceRecognition] Face detected successfully, archiving landmarks")

        // ランドマークデータをData型に変換して保存
        let landmarkData = try NSKeyedArchiver.archivedData(withRootObject: landmarks, requiringSecureCoding: false)
        print("[FaceRecognition] Landmarks archived, size: \(landmarkData.count) bytes")

        return FaceData(userID: UUID(), faceObservations: landmarkData, createdAt: Date())
    }

    /// 顔認証と感情分析を行う
    func recognizeFace(from image: CIImage, referenceFaceData: FaceData) throws -> FaceRecognitionResult {
        // 1. 登録済みの顔の特徴をデコード
        guard let referenceLandmarks = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(referenceFaceData.faceObservations) as? VNFaceLandmarks2D else {
            throw FaceRecognitionError.featureExtractionFailed
        }

        // 2. 新しい画像から顔の特徴を抽出
        let request = createFaceLandmarksRequest()
        let handler = VNImageRequestHandler(ciImage: image, options: [:])

        try handler.perform([request])

        guard let results = request.results as? [VNFaceObservation],
              let currentObservation = results.first,
              let currentLandmarks = currentObservation.landmarks else {
            throw FaceRecognitionError.faceNotDetected
        }

        // 3. 顔の類似度を比較 (ダミー実装)
        // VisionのVNFaceObservationの比較機能や、ランドマーク間の距離計算などで実装
        // ここでは単純に検出できればOKとする
        let isAuthenticated = true // 本来は類似度スコアで判定

        // 4. 感情分析 (ダミー実装)
        // CoreMLモデルが利用可能になったら、ここで分析処理を呼び出す
        // 現時点では固定の値を返す
        let moodScores: [Mood: Double] = [.happiness: 0.7, .neutral: 0.3]

        return FaceRecognitionResult(isAuthenticated: isAuthenticated, moodScores: moodScores)
    }
}
