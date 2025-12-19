# Core Services

## 目次
1. [Overview（概要）](#overview)
2. [Swiftの基礎知識](#swiftの基礎知識)
3. [ファイル構成](#ファイル構成)
4. [詳細解説](#詳細解説)
5. [サービス間の連携](#サービス間の連携)
6. [実際の使用例](#実際の使用例)
7. [よくある質問](#よくある質問)

---

## Overview
アプリケーションのビジネスロジックや外部システム（カメラ、ファイルシステム、Keychain、Vision Framework）とのやり取りをカプセル化するサービスクラス群です。

各サービスはプロトコルによって抽象化されており、テスト容易性と疎結合性を高めています。

**サービス層とは？**
サービス層は、ViewModelと外部システムの間に位置し、複雑なビジネスロジックや外部APIとのやり取りをカプセル化します。
これにより、ViewModelがシンプルになり、コードの再利用性とテスト容易性が向上します。

---

## Swiftの基礎知識

### プロトコル指向プログラミング
Swiftでは、プロトコルを使って「契約」を定義し、実装の詳細を隠蔽します。

```swift
// プロトコル（契約書）
protocol DataPersistenceServiceProtocol {
    func save(entries: [DiaryEntry]) throws
    func load() throws -> [DiaryEntry]
}

// 実装（具体的な方法）
class FileSystemDataPersistenceService: DataPersistenceServiceProtocol {
    func save(entries: [DiaryEntry]) throws {
        // ファイルシステムに保存
    }

    func load() throws -> [DiaryEntry] {
        // ファイルシステムから読み込み
    }
}

// 使う側はプロトコルに依存
class ViewModel {
    let persistence: DataPersistenceServiceProtocol
    // FileSystemかUserDefaultsか、実装の詳細を知らなくて良い
}
```

**プロトコル指向の利点：**
- テスト時にモック実装と差し替え可能
- 実装を変更しても、使う側のコードは変更不要
- 複数の実装を簡単に切り替えられる

### エラーハンドリング
Swiftでは、`throws` キーワードでエラーが発生する可能性を示します。

```swift
// エラー型を定義
enum MyError: Error {
    case fileNotFound
    case invalidData
}

// エラーを投げる可能性がある関数
func loadData() throws -> Data {
    guard fileExists else {
        throw MyError.fileNotFound
    }
    return data
}

// エラーをキャッチ
do {
    let data = try loadData()
    print("成功")
} catch MyError.fileNotFound {
    print("ファイルが見つかりません")
} catch {
    print("その他のエラー: \(error)")
}
```

### Combine フレームワーク
Combineは、非同期イベントを処理するためのフレームワークです。

```swift
import Combine

// Publisher: イベントを発行する
let publisher = PassthroughSubject<String, Never>()

// Subscriber: イベントを受け取る
let cancellable = publisher.sink { value in
    print("受信: \(value)")
}

// イベントを発行
publisher.send("Hello")  // 出力: 受信: Hello
```

**Publisherの種類：**
- `PassthroughSubject`: 値を発行するたびに購読者に通知（値を保持しない）
- `CurrentValueSubject`: 最新の値を保持し、新しい購読者にも通知
- `@Published`: プロパティラッパーで、値が変更されたときに自動的に通知

### AVFoundation フレームワーク
AVFoundationは、カメラやマイクなどのメディアデバイスを制御するフレームワークです。

```swift
import AVFoundation

// カメラセッションの作成
let session = AVCaptureSession()

// カメラデバイスの取得
let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                     for: .video,
                                     position: .front)

// 入力を作成
let input = try AVCaptureDeviceInput(device: device!)

// セッションに追加
if session.canAddInput(input) {
    session.addInput(input)
}

// セッション開始
session.startRunning()
```

### Vision フレームワーク
Visionは、画像解析（顔検出、テキスト認識など）を行うフレームワークです。

```swift
import Vision

// 顔検出リクエスト
let request = VNDetectFaceLandmarksRequest { request, error in
    guard let observations = request.results as? [VNFaceObservation] else { return }
    // 検出された顔の情報
}

// リクエストを実行
let handler = VNImageRequestHandler(ciImage: image, options: [:])
try handler.perform([request])
```

### Keychain
Keychainは、iOSの安全な保存領域で、パスワードや暗号化キーなどを保存します。

```swift
import Security

// Keychainに保存
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "myAccount",
    kSecValueData as String: myData
]
let status = SecItemAdd(query as CFDictionary, nil)

// Keychainから読み込み
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "myAccount",
    kSecReturnData as String: true
]
var item: CFTypeRef?
let status = SecItemCopyMatching(query as CFDictionary, &item)
```

**Keychainの特徴：**
- アプリ削除後も残る（オプションで削除可能）
- セキュアな暗号化
- iCloudで同期可能（オプション）

---

## ファイル構成

```
core/services/
├── AnalyticsService.swift          # 日記データの統計分析
├── CameraService.swift              # カメラ制御と撮影
├── DataPersistenceService.swift    # 日記データの永続化
├── FaceRecognitionService.swift    # 顔認識と感情分析
└── SecurityService.swift            # 機密情報の安全な管理
```

---

## 詳細解説

### 1. AnalyticsService.swift
**ファイルパス**: `facediary/facediary/core/services/AnalyticsService.swift:1`

#### 役割
日記データに基づいた統計情報の計算を行います。
感情の分布、頻出感情、期間ごとの感情推移などを分析します。

#### データ構造

```swift
struct MoodStatistics {
    let moodDistribution: [Mood: Int]
    let totalEntries: Int
    let mostFrequentMood: Mood?
    let averageEntriesPerDay: Double
    let dateRange: (start: Date, end: Date)?
}
```

**各プロパティの説明：**
- `moodDistribution`: 各感情の出現回数を集計（例: [.happiness: 10, .sadness: 3]）
- `totalEntries`: 日記エントリーの総数
- `mostFrequentMood`: 最も頻繁に出現する感情
- `averageEntriesPerDay`: 1日あたりの平均エントリー数
- `dateRange`: 日記データの日付範囲（最古〜最新）

#### プロトコル

```swift
protocol AnalyticsServiceProtocol {
    func calculateStatistics(for entries: [DiaryEntry]) -> MoodStatistics
    func getMoodTrend(for entries: [DiaryEntry], period: AnalyticsPeriod) -> [Date: Mood]
}
```

#### 実装の詳細解説

**calculateStatistics メソッド**

```swift
func calculateStatistics(for entries: [DiaryEntry]) -> MoodStatistics {
    guard !entries.isEmpty else {
        return MoodStatistics(/* 空の統計 */)
    }
```
- `guard !entries.isEmpty`: エントリーが空の場合は早期リターン
- 空の場合は、全てのフィールドが初期値の統計を返す

```swift
var moodDistribution: [Mood: Int] = [:]
for entry in entries {
    if let primaryMood = entry.primaryMood {
        moodDistribution[primaryMood, default: 0] += 1
    }
}
```
- **感情分布の集計**
- `[primaryMood, default: 0]`: キーが存在しない場合は0で初期化
- 各エントリーの主要感情を集計

**例：**
```swift
// エントリー1: 喜び
// エントリー2: 喜び
// エントリー3: 悲しみ
// 結果: [.happiness: 2, .sadness: 1]
```

```swift
let mostFrequentMood = moodDistribution.max(by: { $0.value < $1.value })?.key
```
- **最頻出感情の特定**
- `max(by:)`: 辞書の要素を比較して最大値を取得
- `$0.value < $1.value`: 値（出現回数）で比較

```swift
let sortedDates = entries.map { $0.date }.sorted()
let dateRange: (start: Date, end: Date)? = sortedDates.isEmpty ? nil : (sortedDates.first!, sortedDates.last!)
```
- **日付範囲の計算**
- `map { $0.date }`: 全エントリーから日付だけを抽出
- `sorted()`: 日付を昇順にソート
- `(first!, last!)`: 最古と最新の日付を取得

```swift
var averageEntriesPerDay: Double = 0
if let dateRange = dateRange {
    let daysDifference = Calendar.current.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 0
    averageEntriesPerDay = daysDifference > 0 ? Double(entries.count) / Double(daysDifference + 1) : Double(entries.count)
}
```
- **1日あたりの平均エントリー数を計算**
- `dateComponents([.day], ...)`: 2つの日付間の日数を計算
- `daysDifference + 1`: 開始日を含めるため+1

**例：**
```swift
// 10個のエントリー、5日間
// 平均: 10 / (5 + 1) = 1.67エントリー/日
```

**getMoodTrend メソッド**

```swift
enum AnalyticsPeriod {
    case week
    case month
    case year
}
```
- 分析期間を定義する列挙型

```swift
func getMoodTrend(for entries: [DiaryEntry], period: AnalyticsPeriod) -> [Date: Mood] {
    let startDate: Date
    switch period {
    case .week:
        startDate = DateHelper.startOfWeek
    case .month:
        startDate = DateHelper.startOfMonth
    case .year:
        startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    }
```
- **期間に応じた開始日を設定**
- `.week`: 今週の開始日
- `.month`: 今月の開始日
- `.year`: 1年前

```swift
let filteredEntries = entries.filter { $0.date >= startDate }
```
- **指定期間内のエントリーのみをフィルタリング**

```swift
var moodTrend: [Date: Mood] = [:]
for entry in filteredEntries {
    let dayStart = entry.date.startOfDay
    if let primaryMood = entry.primaryMood {
        moodTrend[dayStart] = primaryMood
    }
}
```
- **日ごとの感情をマッピング**
- `dayStart`: 日付の時刻部分を00:00:00にする
- 同じ日に複数エントリーがある場合、最後のエントリーの感情で上書き

**戻り値：**
```swift
[
    2025-10-30 00:00:00: .happiness,
    2025-10-31 00:00:00: .sadness,
    2025-11-01 00:00:00: .happiness
]
```

#### 使用例

```swift
let analyticsService = AnalyticsService()

// 統計を計算
let statistics = analyticsService.calculateStatistics(for: diaryEntries)
print("総エントリー数: \(statistics.totalEntries)")
print("最頻出感情: \(statistics.mostFrequentMood?.rawValue ?? "なし")")
print("平均エントリー数/日: \(String(format: "%.2f", statistics.averageEntriesPerDay))")

// 感情推移を取得
let weekTrend = analyticsService.getMoodTrend(for: diaryEntries, period: .week)
for (date, mood) in weekTrend.sorted(by: { $0.key < $1.key }) {
    print("\(date.formatted(as: "yyyy/MM/dd")): \(mood.emoji)")
}
```

---

### 2. CameraService.swift
**ファイルパス**: `facediary/facediary/core/services/CameraService.swift:1`

#### 役割
AVFoundationを使用したカメラ制御を行います。
リアルタイムの映像フレーム配信と、静止画撮影機能を提供します。

#### エラー定義

```swift
enum CameraError: Error {
    case permissionDenied       // カメラ使用許可がない
    case setupFailed(String)    // セットアップ失敗（詳細メッセージ付き）
    case captureFailed          // 撮影失敗
}
```

#### クラスの構造

```swift
class CameraService: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
```

**継承・準拠しているプロトコル：**
- `NSObject`: Objective-Cのベースクラス（AVFoundationとの連携に必要）
- `ObservableObject`: SwiftUIで状態変化を監視可能
- `AVCaptureVideoDataOutputSampleBufferDelegate`: 映像フレームのコールバックを受け取る

#### プロパティの詳細

```swift
@Published var previewLayer: AVCaptureVideoPreviewLayer!
```
- **カメラプレビュー用のレイヤー**
- SwiftUIのビューに埋め込んでカメラ映像を表示
- `@Published`: 変更時にビューを自動更新

```swift
let photoPublisher = PassthroughSubject<Data, Error>()
```
- **撮影した静止画を通知するPublisher**
- `PassthroughSubject<Data, Error>`: Dataを成功値、Errorを失敗値として発行
- 撮影が完了すると、画像データ（JPEG形式）を発行

```swift
let framePublisher = PassthroughSubject<CVPixelBuffer, Never>()
```
- **リアルタイム映像フレームを通知するPublisher**
- `CVPixelBuffer`: 画像データのピクセルバッファ（Vision Frameworkで使用）
- `Never`: エラーが発生しない（エラーが出てもクラッシュしない）

```swift
private let session = AVCaptureSession()
private let photoOutput = AVCapturePhotoOutput()
private var videoOutput = AVCaptureVideoDataOutput()
```
- **AVFoundationの主要コンポーネント**
- `AVCaptureSession`: カメラセッションを管理
- `AVCapturePhotoOutput`: 静止画撮影用の出力
- `AVCaptureVideoDataOutput`: 映像フレーム取得用の出力

```swift
private var isSetup = false
```
- **セットアップ完了フラグ**
- 二重セットアップを防ぐ

#### 初期化

```swift
override init() {
    super.init()
    self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
    self.previewLayer.videoGravity = .resizeAspectFill
}
```
- プレビューレイヤーを作成
- `.resizeAspectFill`: アスペクト比を保ちながら画面全体に表示

#### setupAndStart メソッド

```swift
func setupAndStart() async throws {
```
- `async`: 非同期関数（awaitで待機可能）
- `throws`: エラーを投げる可能性がある

```swift
if isSetup {
    if !session.isRunning {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    return
}
```
- **既にセットアップ済みの場合**
- セッションが停止していれば開始するだけ
- バックグラウンドスレッドで実行（UIをブロックしない）

```swift
try await checkPermissions()
```
- **カメラ使用許可を確認**
- 許可がない場合は`CameraError.permissionDenied`を投げる

```swift
guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
    throw CameraError.setupFailed("フロントカメラが見つかりません")
}
```
- **フロントカメラを取得**
- `.builtInWideAngleCamera`: 標準的な広角カメラ
- `.front`: フロントカメラ（自撮り用）

```swift
guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
    throw CameraError.setupFailed("カメラ入力を作成できません")
}
```
- **カメラデバイスを入力として作成**

```swift
session.beginConfiguration()
```
- **セッション構成の開始**
- この間に設定を変更し、最後に`commitConfiguration()`で反映

```swift
session.sessionPreset = .high
```
- **映像品質を設定**
- `.high`: 高品質（ビデオ向け）

```swift
if session.canAddInput(videoDeviceInput) {
    session.addInput(videoDeviceInput)
} else {
    session.commitConfiguration()
    throw CameraError.setupFailed("カメラ入力をセッションに追加できません")
}
```
- **入力をセッションに追加**
- 追加できない場合はエラーを投げる前に構成をコミット（クリーンアップ）

```swift
if session.canAddOutput(photoOutput) {
    session.addOutput(photoOutput)
}
```
- **静止画出力を追加**

```swift
videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video_frames_queue"))
videoOutput.alwaysDiscardsLateVideoFrames = true
```
- **映像フレームのデリゲートを設定**
- 専用のキューで処理（メインスレッドをブロックしない）
- `alwaysDiscardsLateVideoFrames`: 遅延フレームを破棄（リアルタイム性を優先）

```swift
videoOutput.videoSettings = [
    kCVPixelFormatType_32BGRA as String: Int(kCVPixelFormatType_32BGRA)
]
```
- **ピクセルフォーマットを設定**
- `kCVPixelFormatType_32BGRA`: 32ビットBGRA形式（Vision Frameworkと互換性あり）

```swift
if let connection = videoOutput.connection(with: .video) {
    if connection.isVideoOrientationSupported {
        connection.videoOrientation = .portrait
    }
    if connection.isVideoMirroringSupported {
        connection.isVideoMirrored = true
    }
}
```
- **ビデオ接続の設定**
- `.portrait`: 縦向き
- `.isVideoMirrored`: 鏡像（フロントカメラで自然な表示）

```swift
session.commitConfiguration()
```
- **設定を確定**

```swift
isSetup = true

DispatchQueue.global(qos: .userInitiated).async {
    self.session.startRunning()
}
```
- セットアップ完了フラグを設定
- バックグラウンドスレッドでセッション開始

#### takePhoto メソッド

```swift
func takePhoto() {
    let settings = AVCapturePhotoSettings()
    photoOutput.capturePhoto(with: settings, delegate: self)
}
```
- 静止画を撮影
- デリゲートメソッド`photoOutput(_:didFinishProcessingPhoto:error:)`が呼ばれる

#### デリゲートメソッド

```swift
func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
        framePublisher.send(pixelBuffer)
    }
}
```
- **映像フレームが来るたびに呼ばれる**
- ピクセルバッファを抽出してPublisherで発行

```swift
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
```
- **撮影完了時に呼ばれる**
- エラーまたは画像データをPublisherで発行

---

### 3. DataPersistenceService.swift
**ファイルパス**: `facediary/facediary/core/services/DataPersistenceService.swift:1`

#### 役割
日記データをファイルシステムにJSON形式で保存・読み込みします。

#### エラー定義

```swift
enum PersistenceError: Error {
    case fileNotFound
    case encodingFailed(Error)
    case decodingFailed(Error)
    case writingFailed(Error)
    case readingFailed(Error)
}
```

#### プロトコル

```swift
protocol DataPersistenceServiceProtocol {
    func save(entries: [DiaryEntry]) throws
    func load() throws -> [DiaryEntry]
}
```

#### 実装の詳細

```swift
class FileSystemDataPersistenceService: DataPersistenceServiceProtocol {
```

**fileURL プロパティ**

```swift
private var fileURL: URL {
    do {
        let documentsDirectory = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return documentsDirectory.appendingPathComponent("diaryEntries.json")
    } catch {
        fatalError("ドキュメントディレクトリの取得に失敗しました: \(error)")
    }
}
```
- **保存先のファイルURLを生成**
- `.documentDirectory`: アプリのドキュメントディレクトリ
- `diaryEntries.json`: 保存ファイル名

**パス例：**
```
/Users/username/Library/Application Support/.../Documents/diaryEntries.json
```

**save メソッド**

```swift
func save(entries: [DiaryEntry]) throws {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
```
- `JSONEncoder`: Swiftオブジェクトをjsonに変換
- `.iso8601`: 日付をISO8601形式（2025-10-30T14:30:00Z）で保存

```swift
do {
    let data = try encoder.encode(entries)
    try data.write(to: fileURL, options: .atomic)
} catch {
    throw PersistenceError.writingFailed(error)
}
```
- `encode`: 配列をJSONデータに変換
- `.atomic`: 一時ファイルに書き込み後、リネームで保存（クラッシュ時の安全性）

**load メソッド**

```swift
func load() throws -> [DiaryEntry] {
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
        return []
    }
```
- ファイルが存在しない場合は空配列を返す（初回起動時）

```swift
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
```
- `.iso8601`: ISO8601形式の日付文字列をDate型に変換

```swift
do {
    let data = try Data(contentsOf: fileURL)
    let entries = try decoder.decode([DiaryEntry].self, from: data)
    return entries
} catch {
    throw PersistenceError.decodingFailed(error)
}
```
- ファイルを読み込んでデコード

---

### 4. FaceRecognitionService.swift
**ファイルパス**: `facediary/facediary/core/services/FaceRecognitionService.swift:1`

#### 役割
Vision Frameworkを使用した顔認識と感情分析を行います。

#### データ構造

```swift
struct FaceRecognitionResult {
    let isAuthenticated: Bool
    let moodScores: [Mood: Double]
}
```

#### エラー定義

```swift
enum FaceRecognitionError: Error {
    case faceNotDetected
    case featureExtractionFailed
    case recognitionFailed(Error)
    case invalidImage
}
```

#### プロトコル

```swift
protocol FaceRecognitionServiceProtocol {
    func generateFaceData(from image: CIImage) throws -> FaceData
    func recognizeFace(from image: CIImage, referenceFaceData: FaceData) throws -> FaceRecognitionResult
}
```

#### 実装の詳細

**generateFaceData メソッド**

```swift
func generateFaceData(from image: CIImage) throws -> FaceData {
    let request = VNDetectFaceLandmarksRequest()
    let handler = VNImageRequestHandler(ciImage: image, options: [:])

    try handler.perform([request])
```
- **顔のランドマーク（特徴点）を検出**
- ランドマーク: 目、鼻、口などの位置座標

```swift
guard let results = request.results as? [VNFaceObservation] else {
    throw FaceRecognitionError.faceNotDetected
}

guard let observation = results.first else {
    throw FaceRecognitionError.faceNotDetected
}

guard let landmarks = observation.landmarks else {
    throw FaceRecognitionError.faceNotDetected
}
```
- 検出結果から顔の観測データとランドマークを取得
- 顔が検出されなければエラー

```swift
let landmarkData = try NSKeyedArchiver.archivedData(withRootObject: landmarks, requiringSecureCoding: false)
```
- **ランドマークデータをData型にシリアライズ**
- Keychainに保存するためにData型に変換

```swift
return FaceData(userID: UUID(), faceObservations: landmarkData, createdAt: Date())
```
- FaceDataオブジェクトを返す

**recognizeFace メソッド**

```swift
func recognizeFace(from image: CIImage, referenceFaceData: FaceData) throws -> FaceRecognitionResult {
    // 1. 登録済みの顔の特徴をデコード
    guard let referenceLandmarks = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(referenceFaceData.faceObservations) as? VNFaceLandmarks2D else {
        throw FaceRecognitionError.featureExtractionFailed
    }
```
- 保存されているランドマークデータをデシリアライズ

```swift
// 2. 新しい画像から顔の特徴を抽出
let request = VNDetectFaceLandmarksRequest()
let handler = VNImageRequestHandler(ciImage: image, options: [:])
try handler.perform([request])

guard let results = request.results as? [VNFaceObservation],
      let currentObservation = results.first,
      let currentLandmarks = currentObservation.landmarks else {
    throw FaceRecognitionError.faceNotDetected
}
```
- 認証する画像から顔のランドマークを抽出

```swift
// 3. 顔の類似度を比較 (ダミー実装)
let isAuthenticated = true // 本来は類似度スコアで判定

// 4. 感情分析 (ダミー実装)
let moodScores: [Mood: Double] = [.happiness: 0.7, .neutral: 0.3]

return FaceRecognitionResult(isAuthenticated: isAuthenticated, moodScores: moodScores)
```
- **現在はダミー実装**
- 実際にはランドマーク間の距離を計算して類似度を判定
- 感情分析はCoreMLモデルで実装予定

---

### 5. SecurityService.swift
**ファイルパス**: `facediary/facediary/core/services/SecurityService.swift:1`

#### 役割
Keychainを使って顔データなどの機密情報を安全に管理します。

#### エラー定義

```swift
enum SecurityError: Error {
    case dataConversionError
    case keychainError(status: OSStatus)
}
```

#### プロトコル

```swift
protocol SecurityServiceProtocol {
    func save(faceData: FaceData) throws
    func loadFaceData() throws -> FaceData?
    func deleteFaceData() throws
}
```

#### 実装の詳細

```swift
class KeychainSecurityService: SecurityServiceProtocol {
    private let service = "com.example.facediary.FaceData"
    private let account = "currentUser"
```
- **Keychainアイテムの識別子**
- `service`: サービス名（アプリ固有）
- `account`: アカウント名（ユーザー識別）

```swift
private var baseQuery: [String: Any] {
    return [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account
    ]
}
```
- **Keychain操作のベースクエリ**
- `kSecClassGenericPassword`: 汎用パスワードとして保存
- この辞書にデータや検索条件を追加して使用

**save メソッド**

```swift
func save(faceData: FaceData) throws {
    guard let data = try? JSONEncoder().encode(faceData) else {
        throw SecurityError.dataConversionError
    }
```
- FaceDataをJSONエンコード

```swift
var query = baseQuery
query[kSecValueData as String] = data
```
- クエリにデータを追加

```swift
let deleteStatus = SecItemDelete(query as CFDictionary)
```
- **既存アイテムを削除**
- 更新ではなく削除→追加の流れ（Keychainの制限）

```swift
let status = SecItemAdd(query as CFDictionary, nil)
guard status == errSecSuccess else {
    throw SecurityError.keychainError(status: status)
}
```
- 新しいアイテムを追加
- `errSecSuccess`: 成功ステータスコード

**loadFaceData メソッド**

```swift
func loadFaceData() throws -> FaceData? {
    var query = baseQuery
    query[kSecReturnData as String] = kCFBooleanTrue
    query[kSecMatchLimit as String] = kSecMatchLimitOne
```
- `kSecReturnData`: データを返す
- `kSecMatchLimitOne`: 最大1件取得

```swift
var item: CFTypeRef?
let status = SecItemCopyMatching(query as CFDictionary, &item)

guard status != errSecItemNotFound else {
    return nil
}
```
- アイテムを取得
- 存在しない場合は`nil`を返す

```swift
guard status == errSecSuccess else {
    throw SecurityError.keychainError(status: status)
}

guard let data = item as? Data else {
    return nil
}

guard let faceData = try? JSONDecoder().decode(FaceData.self, from: data) else {
    throw SecurityError.dataConversionError
}

return faceData
```
- データをFaceDataにデコード

**deleteFaceData メソッド**

```swift
func deleteFaceData() throws {
    let status = SecItemDelete(baseQuery as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
        throw SecurityError.keychainError(status: status)
    }
}
```
- アイテムを削除
- `errSecItemNotFound`: 既に存在しない場合もエラーとしない

---

## サービス間の連携

### データフロー図

```
┌─────────────────┐
│  ユーザー操作    │
└────────┬────────┘
         ↓
┌────────────────────────────────────────────────┐
│              ViewModel                          │
│  (ビジネスロジックの調整役)                      │
└─────┬──────┬──────┬──────┬──────┬─────────────┘
      ↓      ↓      ↓      ↓      ↓
  ┌───────┬───────┬──────┬──────┬────────┐
  │Camera │Face   │Data  │Analy │Security│
  │Service│Recog  │Persis│tics  │Service │
  │       │Service│tence │Servic│        │
  │       │       │Servic│e     │        │
  │       │       │e     │      │        │
  └───┬───┴───┬───┴───┬──┴───┬──┴────┬───┘
      ↓       ↓       ↓      ↓       ↓
  ┌────────┬─────┬────────┬──────┬────────┐
  │AVFound │Visio│File    │Core  │Keychain│
  │ation   │n    │System  │Data  │        │
  └────────┴─────┴────────┴──────┴────────┘
     外部システム・フレームワーク
```

### 具体的な連携例

#### 1. 顔登録フロー

```
ユーザーが顔登録ボタンをタップ
    ↓
ViewModel
    ↓
CameraService.takePhoto()
    ↓ 写真データ
ViewModel
    ↓
FaceRecognitionService.generateFaceData()
    ↓ FaceData
ViewModel
    ↓
SecurityService.save()
    ↓ Keychainに保存
完了
```

#### 2. 日記作成フロー

```
ユーザーが日記を作成
    ↓
ViewModel
    ↓
CameraService.takePhoto()
    ↓ 写真データ
ViewModel
    ↓
FaceRecognitionService.recognizeFace()
    ↓ 感情スコア
ViewModel
    ├→ DiaryEntryを作成
    ↓
DataPersistenceService.save()
    ↓ ファイルシステムに保存
完了
```

#### 3. 統計表示フロー

```
ユーザーが統計画面を開く
    ↓
ViewModel
    ↓
DataPersistenceService.load()
    ↓ 全エントリー
ViewModel
    ↓
AnalyticsService.calculateStatistics()
    ↓ 統計情報
ViewModel
    ↓
ビューに表示
```

---

## 実際の使用例

### CameraServiceの使用例

```swift
import Combine

class CameraViewModel: ObservableObject {
    private let cameraService = CameraService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 写真撮影のPublisherを購読
        cameraService.photoPublisher
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("撮影完了")
                    case .failure(let error):
                        print("エラー: \(error)")
                    }
                },
                receiveValue: { photoData in
                    print("写真データを受信: \(photoData.count) bytes")
                    // 写真を保存または処理
                }
            )
            .store(in: &cancellables)

        // フレームのPublisherを購読
        cameraService.framePublisher
            .sink { pixelBuffer in
                // リアルタイムで顔認識などを実行
            }
            .store(in: &cancellables)
    }

    func startCamera() async {
        do {
            try await cameraService.setupAndStart()
        } catch {
            print("カメラ起動エラー: \(error)")
        }
    }

    func capturePhoto() {
        cameraService.takePhoto()
    }
}
```

### 全サービスを統合した例

```swift
class DiaryCreationViewModel: ObservableObject {
    private let cameraService = CameraService()
    private let faceRecognitionService = VisionFaceRecognitionService()
    private let dataPersistence = FileSystemDataPersistenceService()
    private let securityService = KeychainSecurityService()

    func createDiaryEntry(text: String) async {
        do {
            // 1. 写真を撮影
            cameraService.takePhoto()
            let photoData = await waitForPhoto()

            // 2. 顔データを読み込み
            guard let faceData = try securityService.loadFaceData() else {
                print("顔データが登録されていません")
                return
            }

            // 3. 顔認証と感情分析
            let ciImage = CIImage(data: photoData)!
            let result = try faceRecognitionService.recognizeFace(
                from: ciImage,
                referenceFaceData: faceData
            )

            guard result.isAuthenticated else {
                print("顔認証失敗")
                return
            }

            // 4. 日記エントリーを作成
            let entry = DiaryEntry(
                text: text,
                photoData: photoData,
                moodScores: result.moodScores
            )

            // 5. 既存エントリーを読み込んで追加
            var entries = try dataPersistence.load()
            entries.append(entry)

            // 6. 保存
            try dataPersistence.save(entries: entries)

            print("日記作成完了!")

        } catch {
            print("エラー: \(error)")
        }
    }
}
```

---

## よくある質問

### Q1: なぜプロトコルを使うのですか？
**A**: テストのしやすさと、実装の切り替えやすさのためです。

```swift
// プロトコル
protocol DataPersistenceServiceProtocol {
    func save(entries: [DiaryEntry]) throws
}

// 実装1: ファイルシステム
class FileSystemDataPersistenceService: DataPersistenceServiceProtocol { ... }

// 実装2: テスト用モック
class MockDataPersistenceService: DataPersistenceServiceProtocol {
    var savedEntries: [DiaryEntry] = []
    func save(entries: [DiaryEntry]) throws {
        savedEntries = entries  // 実際には保存しない
    }
}

// 使う側はプロトコルに依存
class ViewModel {
    let persistence: DataPersistenceServiceProtocol
    // テスト時はモックを注入できる
}
```

### Q2: async/awaitとは何ですか？
**A**: Swift 5.5で導入された非同期処理の仕組みです。

```swift
// 従来のコールバック方式
func loadData(completion: @escaping (Data) -> Void) {
    DispatchQueue.global().async {
        let data = // 重い処理
        completion(data)
    }
}

// async/await方式
func loadData() async -> Data {
    let data = // 重い処理
    return data
}

// 呼び出し
let data = await loadData()  // awaitで待機、その間UIはフリーズしない
```

### Q3: Combineの購読をキャンセルする必要がありますか？
**A**: はい、メモリリークを防ぐために必要です。

```swift
class MyClass {
    private var cancellables = Set<AnyCancellable>()

    func setup() {
        publisher
            .sink { value in
                print(value)
            }
            .store(in: &cancellables)
        // .store(in:)により、MyClassが破棄されるときに自動キャンセル
    }
}
```

### Q4: Keychainに保存したデータはアプリ削除後も残りますか？
**A**: デフォルトでは残ります。削除したい場合は設定が必要です。

```swift
query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
// ThisDeviceOnly: アプリ削除時に自動削除
```

### Q5: Vision Frameworkの精度はどのくらいですか？
**A**: 環境によって変わりますが、一般的に：
- 正面の顔: 95%以上
- 横顔: 70-80%
- 暗い場所: 50%以下

改善方法：
- 明るい場所で撮影
- カメラを正面に向ける
- 複数枚の顔データを登録

### Q6: JSONとCodableの関係は？
**A**: CodableはSwiftオブジェクトとJSON間の変換を簡単にするプロトコルです。

```swift
struct Person: Codable {
    var name: String
    var age: Int
}

// Swift → JSON
let person = Person(name: "太郎", age: 25)
let jsonData = try JSONEncoder().encode(person)
// {"name":"太郎","age":25}

// JSON → Swift
let decodedPerson = try JSONDecoder().decode(Person.self, from: jsonData)
```

### Q7: セッションの開始・停止を適切に管理する方法は？
**A**: アプリのライフサイクルに合わせて管理します。

```swift
class CameraViewModel: ObservableObject {
    private let cameraService = CameraService()

    func onAppear() {
        Task {
            try await cameraService.setupAndStart()
        }
    }

    func onDisappear() {
        cameraService.stop()
    }
}

// SwiftUIのビュー
.onAppear {
    viewModel.onAppear()
}
.onDisappear {
    viewModel.onDisappear()
}
```

### Q8: エラーハンドリングのベストプラクティスは？
**A**: エラーの種類に応じて適切に処理します。

```swift
do {
    try dataPersistence.save(entries: entries)
} catch PersistenceError.writingFailed(let error) {
    // 保存失敗: ユーザーに通知、リトライ
    showAlert("保存に失敗しました")
} catch PersistenceError.encodingFailed(let error) {
    // エンコード失敗: 開発者にログを送信
    logError(error)
} catch {
    // その他のエラー
    print("予期しないエラー: \(error)")
}
```

---

## まとめ

`core/services` ディレクトリは、FaceDiaryアプリの「業務部門」です：

1. **AnalyticsService**: 統計分析
2. **CameraService**: カメラ制御
3. **DataPersistenceService**: データ保存
4. **FaceRecognitionService**: 顔認識・感情分析
5. **SecurityService**: セキュリティ管理

これらのサービスは、プロトコル指向プログラミングにより疎結合で、テストしやすく、拡張しやすい設計になっています。

---

## 参考リンク
- [Apple公式: AVFoundation](https://developer.apple.com/documentation/avfoundation)
- [Apple公式: Vision Framework](https://developer.apple.com/documentation/vision)
- [Apple公式: Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [Apple公式: Combine](https://developer.apple.com/documentation/combine)
- [Swift by Sundell: Protocols](https://www.swiftbysundell.com/basics/protocols/)
