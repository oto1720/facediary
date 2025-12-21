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
        print("[FaceRecognition] Starting face recognition")

        // 1. 登録済みの顔の特徴をデコード
        guard let referenceLandmarks = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(referenceFaceData.faceObservations) as? VNFaceLandmarks2D else {
            print("[FaceRecognition] Failed to decode reference landmarks")
            throw FaceRecognitionError.featureExtractionFailed
        }

        // 2. 新しい画像から顔の特徴を抽出
        let request = createFaceLandmarksRequest()
        let handler = VNImageRequestHandler(ciImage: image, options: [:])

        try handler.perform([request])

        guard let results = request.results as? [VNFaceObservation],
              let currentObservation = results.first,
              let currentLandmarks = currentObservation.landmarks else {
            print("[FaceRecognition] No face detected in current image")
            throw FaceRecognitionError.faceNotDetected
        }

        print("[FaceRecognition] Face detected, calculating similarity")

        // 3. 顔の類似度を計算
        let similarity = calculateFaceSimilarity(
            reference: referenceLandmarks,
            current: currentLandmarks
        )

        print("[FaceRecognition] Similarity score: \(similarity)")

        // 閾値: 0.85以上で本人と判定（調整可能）
        let threshold: Double = 0.85
        let isAuthenticated = similarity >= threshold

        print("[FaceRecognition] Authentication result: \(isAuthenticated)")

        // 4. 感情分析（ランドマークベース）
        let moodScores = analyzeEmotion(from: currentLandmarks)
        print("[FaceRecognition] Mood scores: \(moodScores)")

        return FaceRecognitionResult(isAuthenticated: isAuthenticated, moodScores: moodScores)
    }

    /// 顔の類似度を計算する
    /// - Parameters:
    ///   - reference: 登録済みの顔のランドマーク
    ///   - current: 現在の顔のランドマーク
    /// - Returns: 類似度スコア（0.0〜1.0）
    private func calculateFaceSimilarity(reference: VNFaceLandmarks2D, current: VNFaceLandmarks2D) -> Double {
        var totalScore: Double = 0.0
        var featureCount: Double = 0.0

        // 主要な特徴点を比較
        let features: [(VNFaceLandmarkRegion2D?, VNFaceLandmarkRegion2D?, Double)] = [
            (reference.leftEye, current.leftEye, 2.0),           // 左目（重要度高）
            (reference.rightEye, current.rightEye, 2.0),         // 右目（重要度高）
            (reference.nose, current.nose, 1.5),                 // 鼻（重要度中）
            (reference.outerLips, current.outerLips, 1.5),       // 外側の唇（重要度中）
            (reference.faceContour, current.faceContour, 1.0),   // 顔の輪郭（重要度低）
            (reference.leftEyebrow, current.leftEyebrow, 1.0),   // 左眉（重要度低）
            (reference.rightEyebrow, current.rightEyebrow, 1.0)  // 右眉（重要度低）
        ]

        for (refFeature, currFeature, weight) in features {
            guard let ref = refFeature, let curr = currFeature else {
                continue
            }

            // 特徴点間の距離を計算
            let distance = calculateLandmarkDistance(ref, curr)

            // 距離を類似度スコアに変換（距離が小さいほどスコアが高い）
            // 距離の範囲を0.0〜0.2と仮定し、0.2以上は類似度0とする
            let normalizedDistance = min(distance, 0.2)
            let similarity = 1.0 - (normalizedDistance / 0.2)

            totalScore += similarity * weight
            featureCount += weight
        }

        // 平均スコアを計算
        return featureCount > 0 ? totalScore / featureCount : 0.0
    }

    /// ランドマーク間の距離を計算する
    /// - Parameters:
    ///   - landmark1: ランドマーク1
    ///   - landmark2: ランドマーク2
    /// - Returns: ユークリッド距離の平均
    private func calculateLandmarkDistance(_ landmark1: VNFaceLandmarkRegion2D, _ landmark2: VNFaceLandmarkRegion2D) -> Double {
        let points1 = landmark1.normalizedPoints
        let points2 = landmark2.normalizedPoints

        // ポイント数が異なる場合は、少ない方に合わせる
        let minCount = min(points1.count, points2.count)
        guard minCount > 0 else { return 1.0 }

        var totalDistance: Double = 0.0

        for i in 0..<minCount {
            let p1 = points1[i]
            let p2 = points2[i]

            // ユークリッド距離を計算
            let dx = Double(p1.x - p2.x)
            let dy = Double(p1.y - p2.y)
            let distance = sqrt(dx * dx + dy * dy)

            totalDistance += distance
        }

        // 平均距離を返す
        return totalDistance / Double(minCount)
    }

    /// 顔のランドマークから感情を分析する
    /// - Parameter landmarks: 顔のランドマーク
    /// - Returns: 各感情のスコア（合計が1.0になるように正規化）
    private func analyzeEmotion(from landmarks: VNFaceLandmarks2D) -> [Mood: Double] {
        var scores: [Mood: Double] = [
            .happiness: 0.0,
            .sadness: 0.0,
            .anger: 0.0,
            .surprise: 0.0,
            .calm: 0.0,
            .neutral: 0.0
        ]

        // 1. 笑顔の検出（口角の上がり具合）
        if let outerLips = landmarks.outerLips {
            let smileScore = detectSmile(from: outerLips)
            scores[.happiness] = smileScore
        }

        // 2. 眉の角度から感情を推測
        if let leftEyebrow = landmarks.leftEyebrow,
           let rightEyebrow = landmarks.rightEyebrow {
            let eyebrowScore = analyzeEyebrows(left: leftEyebrow, right: rightEyebrow)

            // 眉が上がっている場合は驚き
            if eyebrowScore > 0.6 {
                scores[.surprise] = eyebrowScore
            }
            // 眉が下がっている場合は怒りや悲しみ
            else if eyebrowScore < -0.3 {
                scores[.anger] = abs(eyebrowScore) * 0.5
                scores[.sadness] = abs(eyebrowScore) * 0.5
            }
        }

        // 3. 口の開き具合から驚きを検出
        if let outerLips = landmarks.outerLips,
           let innerLips = landmarks.innerLips {
            let mouthOpenness = detectMouthOpenness(outer: outerLips, inner: innerLips)

            if mouthOpenness > 0.7 {
                scores[.surprise] = max(scores[.surprise] ?? 0.0, mouthOpenness)
            }
        }

        // 4. スコアの合計を計算
        let totalScore = scores.values.reduce(0.0, +)

        // 5. 感情が検出されなかった場合は穏やかまたは普通
        if totalScore < 0.2 {
            scores[.calm] = 0.7
            scores[.neutral] = 0.3
        } else {
            // スコアを正規化（合計が1.0になるように）
            for mood in scores.keys {
                scores[mood] = (scores[mood] ?? 0.0) / totalScore
            }
        }

        // スコアが低すぎる感情を除外（閾値: 0.1）
        return scores.filter { $0.value > 0.1 }
    }

    /// 口角の上がり具合から笑顔を検出する
    /// - Parameter lips: 外側の唇のランドマーク
    /// - Returns: 笑顔のスコア（0.0〜1.0）
    private func detectSmile(from lips: VNFaceLandmarkRegion2D) -> Double {
        let points = lips.normalizedPoints
        guard points.count >= 4 else { return 0.0 }

        // 口角の位置（左右）
        let leftCorner = points[0]
        let rightCorner = points[points.count / 2]

        // 口の中央（上下）
        let topCenter = points[points.count / 4]
        let bottomCenter = points[3 * points.count / 4]

        // 口角が上がっているかチェック
        let mouthCenterY = (topCenter.y + bottomCenter.y) / 2.0
        let cornerY = (leftCorner.y + rightCorner.y) / 2.0

        // 口角が中央より上にある場合は笑顔
        let smileDelta = Double(cornerY - mouthCenterY)

        // -0.02〜0.02の範囲を0.0〜1.0にマッピング
        let normalizedSmile = (smileDelta + 0.02) / 0.04
        return max(0.0, min(1.0, normalizedSmile))
    }

    /// 眉の角度を分析する
    /// - Parameters:
    ///   - left: 左眉のランドマーク
    ///   - right: 右眉のランドマーク
    /// - Returns: 眉のスコア（-1.0〜1.0、正の値は上がっている、負の値は下がっている）
    private func analyzeEyebrows(left: VNFaceLandmarkRegion2D, right: VNFaceLandmarkRegion2D) -> Double {
        let leftPoints = left.normalizedPoints
        let rightPoints = right.normalizedPoints

        guard leftPoints.count >= 2, rightPoints.count >= 2 else { return 0.0 }

        // 眉の内側と外側の高さの差を計算
        let leftInner = leftPoints[leftPoints.count - 1]
        let leftOuter = leftPoints[0]
        let rightInner = rightPoints[0]
        let rightOuter = rightPoints[rightPoints.count - 1]

        // 眉の傾きを計算
        let leftSlope = Double(leftOuter.y - leftInner.y)
        let rightSlope = Double(rightInner.y - rightOuter.y)

        // 平均傾き（-0.05〜0.05の範囲を-1.0〜1.0にマッピング）
        let averageSlope = (leftSlope + rightSlope) / 2.0
        return averageSlope / 0.05
    }

    /// 口の開き具合を検出する
    /// - Parameters:
    ///   - outer: 外側の唇のランドマーク
    ///   - inner: 内側の唇のランドマーク
    /// - Returns: 口の開き具合（0.0〜1.0）
    private func detectMouthOpenness(outer: VNFaceLandmarkRegion2D, inner: VNFaceLandmarkRegion2D) -> Double {
        let outerPoints = outer.normalizedPoints
        let innerPoints = inner.normalizedPoints

        guard outerPoints.count >= 4, innerPoints.count >= 4 else { return 0.0 }

        // 口の高さを計算（上下の距離）
        let topOuter = outerPoints[outerPoints.count / 4]
        let bottomOuter = outerPoints[3 * outerPoints.count / 4]

        let mouthHeight = Double(abs(bottomOuter.y - topOuter.y))

        // 0.0〜0.1の範囲を0.0〜1.0にマッピング
        let normalizedOpenness = mouthHeight / 0.1
        return max(0.0, min(1.0, normalizedOpenness))
    }
}
