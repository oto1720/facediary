# Onboarding Feature - 初回セットアップ機能

## 目次
1. [概要](#概要)
2. [ファイル構成](#ファイル構成)
3. [詳細解説](#詳細解説)
4. [よくある質問](#よくある質問)
5. [まとめ](#まとめ)

---

## 概要

**Onboarding Feature**は、アプリの初回起動時にユーザーの顔データを登録するための機能です。このプロセスにより、その後のAuthentication機能で使用される参照データが作成されます。

### 主な機能
- **顔の撮影**: カメラで自分の顔を撮影
- **顔データ生成**: Vision Frameworkで特徴量を抽出
- **セキュア保存**: Keychainに安全に保存
- **状態管理**: 登録プロセスの各段階を視覚化

---

## ファイル構成

```
feature/onboarding/
├── view/
│   ├── FaceRegistrationView.swift  # 顔登録画面（実装済み）
│   └── OnboardingView.swift        # (ほぼ空)
├── viewmodels/
│   └── OnboardingViewModel.swift   # 登録処理ViewModel
└── README.md
```

---

## 詳細解説

### 1. FaceRegistrationView.swift

#### 役割
顔登録のメイン画面。カメラプレビューと登録ボタンを表示し、登録プロセスを管理。

#### 重要なポイント

##### (1) 登録状態の管理
```swift
enum OnboardingRegistrationState {
    case initial        // 初期状態
    case capturing      // 撮影準備
    case processing     // 処理中
    case completed      // 完了
    case failed(Error)  // 失敗
}
```
- Enumで状態を明確に定義
- `failed`は関連値としてエラーを保持

##### (2) 状態に応じたUI
```swift
switch viewModel.registrationState {
case .initial, .capturing:
    captureInstructionsView  // 指示とボタン
case .processing:
    ProgressView("顔データを処理中...")
case .completed:
    completionView  // 成功メッセージと「次へ」ボタン
case .failed(let error):
    errorView(error: error)  // エラーと再試行ボタン
}
```
- 各状態で適切なフィードバック
- ユーザーに進行状況を明示

##### (3) カメラプレビュー
```swift
ZStack {
    CameraPreviewView(session: viewModel.cameraService.captureSession)
        .ignoresSafeArea()

    VStack {
        // UIオーバーレイ
    }
}
```
- 全画面でカメラプレビュー
- その上にUI要素を配置

##### (4) 完了時のコールバック
```swift
var onComplete: (() -> Void)?

Button(action: {
    onComplete?()
}) {
    Text("次へ")
}
```
- 登録完了後、親Viewに通知
- アプリの次の画面へ遷移

---

### 2. OnboardingViewModel.swift

#### 役割
顔登録プロセスの状態管理と実行を担当。

#### 重要なメソッド

##### (1) カメラ起動
```swift
func startCamera() {
    registrationState = .capturing
    Task {
        do {
            try await cameraService.setupAndStart()
        } catch {
            await MainActor.run {
                registrationState = .failed(error)
            }
        }
    }
}
```
- async/awaitでカメラセットアップ
- エラー時は`failed`状態に遷移

##### (2) 顔登録の実行
```swift
func registerFace() {
    guard let frame = latestFrame else {
        registrationState = .failed(FaceRecognitionError.invalidImage)
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
            }
        }
    }
}
```
**処理フロー**:
1. 最新フレームの存在確認
2. `processing`状態に更新
3. バックグラウンドで処理:
   - CVPixelBuffer → CIImage変換
   - 顔データ（特徴量）生成
   - Keychainに保存
4. 成功時は`completed`、失敗時は`failed`

##### (3) フレームバインディング
```swift
private func setupBindings() {
    cameraService.framePublisher
        .receive(on: DispatchQueue.main)
        .sink { [weak self] frame in
            self?.latestFrame = frame
        }
        .store(in: &cancellables)
}
```
- カメラサービスから最新フレームを受信
- 撮影ボタンが押された時に使用

---

## よくある質問

### Q1. なぜ初回のみ登録？
**A**:
- 一度登録すれば、以降は認証のみで使用可能
- 毎回登録する必要がない
- セキュリティと利便性のバランス

### Q2. 顔データは何を保存する？
**A**:
```swift
let faceData = try faceRecognitionService.generateFaceData(from: image)
```
- 写真そのものではなく「特徴量」
- Vision Frameworkが抽出した数値データ
- 元の写真に復元できない

### Q3. Keychainに保存する理由は？
**A**:
```swift
try securityService.save(faceData: faceData)
```
- iOS標準のセキュアストレージ
- 暗号化された状態で保存
- アプリ削除時も保持される（オプション）

### Q4. 登録失敗時の再試行は？
**A**:
```swift
Button("再試行") {
    viewModel.startCamera()  // 状態をリセットして再開
}
```
- `startCamera()`で状態を`capturing`に戻す
- もう一度撮影からやり直し

### Q5. 登録後の画面遷移は？
**A**:
```swift
// AppViewModel.swift または親View
FaceRegistrationView(onComplete: {
    // 認証画面やホーム画面へ遷移
    appViewModel.appState = .authentication  // または .home
})
```
- `onComplete`コールバックで親Viewが遷移を制御

### Q6. Debug用のログは？
**A**:
```swift
print("[OnboardingVM] Register face called")
print("[OnboardingVM] Frame available, starting registration")
```
- 開発中のデバッグ用
- 本番環境では削除推奨

---

## まとめ

### Onboarding Featureの重要ポイント

1. **初回セットアップ**
   - アプリの最初の体験
   - 顔データの登録
   - 以降の認証に使用

2. **状態管理**
   - Enumで明確な状態定義
   - 関連値でエラー情報保持
   - UI自動更新

3. **セキュリティ**
   - 特徴量のみ保存（写真は保存しない）
   - Keychainで暗号化保存
   - Vision Framework使用

4. **非同期処理**
   - async/await (カメラ起動)
   - DispatchQueue (顔データ生成)
   - Combine (フレーム受信)

5. **エラーハンドリング**
   - 各段階でのエラー処理
   - 再試行機能
   - ユーザーフレンドリーなメッセージ

### 学習の次のステップ
1. Vision Frameworkの顔認識
2. Keychain Servicesのセキュリティ
3. async/awaitとTask
4. オンボーディングUXのベストプラクティス

---

**このドキュメントについて**
作成日: 2025年
対象: Swift初心者〜中級者
バージョン: FaceDiary v1.0
