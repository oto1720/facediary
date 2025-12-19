# Authentication Feature - 顔認証機能

## 目次
1. [概要](#概要)
2. [SwiftUIとAVFoundationの基礎知識](#swiftuiとavfoundationの基礎知識)
3. [ファイル構成](#ファイル構成)
4. [詳細解説](#詳細解説)
5. [連携・関係性](#連携関係性)
6. [実際の使用例](#実際の使用例)
7. [よくある質問](#よくある質問)
8. [まとめ](#まとめ)
9. [参考リンク](#参考リンク)

---

## 概要

**Authentication Feature**は、ユーザーの顔認証を行い、アプリへのアクセスを制御する機能です。Core機能として提供される`CameraService`と`FaceRecognitionService`を使用して、リアルタイムでの顔検出と照合を行います。

### 主な機能
- **リアルタイム顔認証**: カメラを使用してリアルタイムに顔を検出
- **セキュアな認証**: Keychainに保存された顔データとの照合
- **状態管理**: 認証プロセスの各段階を視覚的にフィードバック
- **エラーハンドリング**: 認証失敗時の再試行機能

### このFeatureの重要性
- ユーザーのプライバシー保護
- アプリへの不正アクセス防止
- 生体認証によるシームレスなユーザー体験

---

## SwiftUIとAVFoundationの基礎知識

### 1. Enum with Associated Values（関連値を持つ列挙型）
```swift
enum AuthenticationState {
    case ready
    case scanning
    case processing
    case success
    case failed(String)  // <- 関連値（エラーメッセージ）
}
```
- **関連値**: ケースごとに追加のデータを持つことができる
- `failed`ケースはエラーメッセージを持つ
- 状態とデータを一つの型で表現できる

### 2. Switch文でのパターンマッチング
```swift
switch viewModel.authenticationState {
case .ready, .scanning:
    scanningInstructionsView
case .processing:
    ProgressView("認証中...")
case .success:
    successView
case .failed(let message):  // <- 関連値を取り出す
    failedView(message: message)
}
```
- ケースごとに異なるビューを表示
- `let message`で関連値を取り出して使用

### 3. ZStack（重ねるレイアウト）
```swift
ZStack {
    CameraPreviewView(...)  // 背景（カメラ映像）
    VStack {                // 前景（UI要素）
        // ボタンやテキスト
    }
}
```
- **ZStack**: ビューを重ねて配置
- カメラプレビューの上にUIを表示するために使用

### 4. Combine Framework
```swift
cameraService.framePublisher
    .receive(on: DispatchQueue.main)
    .sink { [weak self] frame in
        self?.latestFrame = frame
    }
    .store(in: &cancellables)
```
- **Publisher**: データストリームの発行元
- **Sink**: データを受け取る購読者
- **Weak Self**: メモリリークを防ぐ
- **Cancellables**: 購読を保持して後でキャンセル可能にする

### 5. AVFoundation Basics
```swift
let session: AVCaptureSession
let previewLayer: AVCaptureVideoPreviewLayer
```
- **AVCaptureSession**: カメラセッションの管理
- **AVCaptureVideoPreviewLayer**: カメラ映像のプレビュー表示

### 6. CVPixelBuffer
```swift
private var latestFrame: CVPixelBuffer?
```
- **CVPixelBuffer**: カメラからのフレームデータ（画像バッファ）
- Core VideoフレームワークのデータタイプでVision frameworkで利用

---

## ファイル構成

```
feature/authentication/
├── view/
│   └── AuthenticationView.swift        # 認証画面のUI
├── viewmodels/
│   └── AuthenticationViewModel.swift   # 認証ロジック
└── README.md                            # このドキュメント
```

### 依存関係図
```
AuthenticationView
    ↓ @StateObject
AuthenticationViewModel
    ↓ 依存
    ├── CameraService (カメラ制御)
    ├── FaceRecognitionService (顔認識)
    └── SecurityService (顔データ読み込み)
```

---

## 詳細解説

### 1. AuthenticationView.swift

#### 役割
顔認証画面のUIを提供し、認証プロセスを視覚化する。

#### コード解説

##### (1) 基本構造
```swift
struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    var onAuthenticationSuccess: (() -> Void)?

    var body: some View {
        ZStack {
            // カメラプレビュー
            if let session = viewModel.cameraService.previewLayer.session {
                CameraPreviewView(session: session)
                    .ignoresSafeArea()
            }

            // UIオーバーレイ
            VStack {
                // 状態に応じたビュー
            }
        }
    }
}
```
**意味**:
- `onAuthenticationSuccess`: クロージャ（コールバック関数）
- 認証成功時に親Viewに通知するための仕組み
- `ZStack`でカメラの上にUIを重ねる

##### (2) コールバックパターン
```swift
var onAuthenticationSuccess: (() -> Void)?
```
**意味**:
- **Optional Closure**: 関数を変数として渡せる
- `() -> Void`: 引数なし、戻り値なしの関数型
- 認証成功時に`onAuthenticationSuccess?()`で呼び出す

**使用例**:
```swift
AuthenticationView(onAuthenticationSuccess: {
    print("認証成功！")
    // 画面遷移などの処理
})
```

##### (3) 状態に応じたビュー分岐
```swift
switch viewModel.authenticationState {
case .ready, .scanning:
    scanningInstructionsView
case .processing:
    ProgressView("認証中...")
        .progressViewStyle(CircularProgressViewStyle(tint: .white))
case .success:
    successView
case .failed(let message):
    failedView(message: message)
}
```
**意味**:
- 認証状態ごとに異なるUIを表示
- `case .ready, .scanning`: 複数ケースをまとめて処理
- `case .failed(let message)`: 関連値を取り出す

##### (4) スキャン指示ビュー
```swift
private var scanningInstructionsView: some View {
    VStack {
        Image(systemName: "faceid")
            .resizable()
            .scaledToFit()
            .frame(width: 60, height: 60)
            .foregroundColor(.white)
        Text("顔認証を開始してください")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.white)
    }
    .padding()
    .background(Color.black.opacity(0.5))
    .cornerRadius(15)
}
```
**意味**:
- SFSymbolsの`faceid`アイコンを使用
- 半透明の黒背景で視認性を向上
- ユーザーに次のアクションを明示

##### (5) 認証ボタン
```swift
private var authenticateButton: some View {
    Button(action: {
        viewModel.authenticate()
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
```
**意味**:
- iOSカメラアプリのシャッターボタンに似たデザイン
- 外側の円（枠線）と内側の円（塗りつぶし）を重ねる
- タップで`viewModel.authenticate()`を実行

##### (6) 成功ビュー with Delay
```swift
private var successView: some View {
    VStack {
        Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
        Text("認証成功")
    }
    .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onAuthenticationSuccess?()
        }
    }
}
```
**意味**:
- `onAppear`: ビューが表示された時に実行
- `asyncAfter`: 1秒後にコールバックを実行
- ユーザーに成功を確認させてから遷移

##### (7) ライフサイクル管理
```swift
.onAppear {
    viewModel.startCamera()
}
.onDisappear {
    viewModel.stopCamera()
}
```
**意味**:
- `onAppear`: 画面が表示される時
- `onDisappear`: 画面が閉じられる時
- カメラリソースの適切な管理

---

### 2. AuthenticationViewModel.swift

#### 役割
認証プロセスの制御と状態管理を担当。

#### コード解説

##### (1) 認証状態の定義
```swift
enum AuthenticationState {
    case ready
    case scanning
    case processing
    case success
    case failed(String)
}
```
**意味**:
- **ready**: 認証準備完了
- **scanning**: カメラスキャン中
- **processing**: 認証処理中
- **success**: 認証成功
- **failed(String)**: 認証失敗（エラーメッセージ付き）

##### (2) プロパティ定義
```swift
@Published var authenticationState: AuthenticationState = .ready
@Published var errorMessage: String?

let cameraService: CameraService
private let faceRecognitionService: FaceRecognitionServiceProtocol
private let securityService: SecurityServiceProtocol

private var cancellables = Set<AnyCancellable>()
private var latestFrame: CVPixelBuffer?
private var referenceFaceData: FaceData?
```
**意味**:
- `authenticationState`: 現在の認証状態
- `errorMessage`: エラーメッセージ（Optional）
- `cameraService`: `let`（publicプロパティ）でViewから参照可能
- `cancellables`: Combineの購読を管理
- `latestFrame`: 最新のカメラフレーム
- `referenceFaceData`: 登録済みの顔データ

##### (3) 初期化と準備
```swift
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
```
**意味**:
- 依存注入パターン（テスト可能な設計）
- `setupBindings()`: Combineのデータバインディング設定
- `loadReferenceFaceData()`: 登録済み顔データの読み込み

##### (4) カメラ起動（Async/Await）
```swift
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
```
**意味**:
- **Task**: 非同期処理を開始
- **async/await**: 非同期コードを同期的に書ける
- **MainActor.run**: UI更新をメインスレッドで実行
- エラー時に状態を`failed`に更新

##### (5) フレームデータのバインディング
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
**意味**:
- `framePublisher`: カメラサービスがフレームを配信
- `receive(on:)`: メインスレッドでデータを受け取る
- `[weak self]`: 循環参照を防ぐ
- `store(in:)`: 購読を保持（キャンセル可能）

**データフロー**:
```
CameraService
    ↓ framePublisher (CVPixelBuffer)
setupBindings()
    ↓ latestFrame に保存
authenticate() で使用
```

##### (6) 認証処理
```swift
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
            let result = try self.faceRecognitionService.recognizeFace(
                from: image,
                referenceFaceData: referenceFaceData
            )

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
```
**処理フロー**:
1. `latestFrame`が存在するか確認
2. `referenceFaceData`が存在するか確認
3. 状態を`processing`に更新
4. バックグラウンドスレッドで処理:
   - `CVPixelBuffer`を`CIImage`に変換
   - `FaceRecognitionService`で照合
5. メインスレッドで結果を反映:
   - 成功: `success`状態
   - 失敗: `failed`状態

##### (7) 参照顔データの読み込み
```swift
private func loadReferenceFaceData() {
    do {
        self.referenceFaceData = try securityService.loadFaceData()
    } catch {
        print("顔データの読み込みに失敗しました。\n(\(error.localizedDescription))")
    }
}
```
**意味**:
- Keychainから登録済み顔データを読み込む
- 失敗してもクラッシュせず、エラーログのみ出力
- 認証時に`guard`でチェック

---

## 連携・関係性

### 1. 他のFeatureとの連携

#### (1) App起動時の認証フロー
```
AppViewModel
    ↓ appState == .authentication
AuthenticationView (表示)
    ↓ 認証成功
onAuthenticationSuccess コールバック
    ↓
AppViewModel.appState = .home
    ↓
HomeView (表示)
```

#### (2) Onboarding Featureとの関係
```
初回起動
    ↓
Onboarding (顔登録)
    ↓ 顔データ保存
以降の起動
    ↓
Authentication (顔認証)
```

### 2. Servicesとの連携

#### (1) CameraService
```swift
let cameraService: CameraService
```
**役割**:
- カメラセッションの管理
- フレームデータの配信
- プレビュー表示のサポート

#### (2) FaceRecognitionService
```swift
let result = try faceRecognitionService.recognizeFace(
    from: image,
    referenceFaceData: referenceFaceData
)
```
**役割**:
- 顔の検出と特徴量抽出
- 登録済み顔データとの照合
- 認証結果の返却

#### (3) SecurityService
```swift
self.referenceFaceData = try securityService.loadFaceData()
```
**役割**:
- Keychainからの顔データ読み込み
- セキュアなデータ管理

### 3. データフロー図
```
カメラハードウェア
    ↓ 映像ストリーム
CameraService
    ↓ framePublisher (CVPixelBuffer)
AuthenticationViewModel
    ↓ latestFrame
authenticate() 実行
    ↓ CIImage変換
FaceRecognitionService
    ├─ SecurityService (参照データ取得)
    └─ Vision Framework (顔照合)
    ↓ 認証結果
AuthenticationState更新
    ↓ @Published
AuthenticationView
    ↓ UI更新
ユーザー画面
```

---

## 実際の使用例

### ケース1: アプリ起動時の認証

**シナリオ**: ユーザーがアプリを起動する

**処理フロー**:
1. `AppViewModel`が`appState`を判定
2. 顔データが登録済みなら`appState = .authentication`
3. `AuthenticationView`が表示される
4. `viewModel.startCamera()`が自動実行
5. カメラが起動し、`scanning`状態になる
6. ユーザーが認証ボタンをタップ
7. 顔認証が実行される
8. 成功すると`onAuthenticationSuccess`が呼ばれる
9. `HomeView`に遷移

**コード**:
```swift
// AppViewModel.swift
if hasFaceData {
    appState = .authentication
}

// ContentView.swift
case .authentication:
    AuthenticationView(onAuthenticationSuccess: {
        appViewModel.appState = .home
    })
```

---

### ケース2: 認証失敗と再試行

**シナリオ**: 顔認証が失敗する

**処理フロー**:
1. `authenticate()`が実行される
2. `FaceRecognitionService`が照合失敗を返す
3. `authenticationState = .failed("顔認証に失敗しました。")`
4. `failedView`が表示される
5. ユーザーが「再試行」ボタンをタップ
6. `viewModel.retry()`が実行される
7. `authenticationState = .scanning`に戻る
8. 再度認証を試みる

**コード**:
```swift
// AuthenticationViewModel.swift
func retry() {
    authenticationState = .scanning
}

// AuthenticationView.swift
Button("再試行") {
    viewModel.retry()
}
```

---

### ケース3: カメラ権限がない場合

**シナリオ**: ユーザーがカメラ権限を拒否

**処理フロー**:
1. `startCamera()`が実行される
2. `CameraService.setupAndStart()`でエラー発生
3. `catch`ブロックで`authenticationState = .failed(...)`
4. エラーメッセージが表示される

**コード**:
```swift
func startCamera() {
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
```

---

## よくある質問

### Q1. `enum`に関連値を持たせる理由は？
**A**:
```swift
case failed(String)  // エラーメッセージを持つ
```
- 失敗時のエラーメッセージを状態と一緒に保持できる
- 状態とデータが分離せず、型安全
- `switch`文で取り出せる: `case .failed(let message)`

---

### Q2. `[weak self]`の意味は？
**A**:
```swift
.sink { [weak self] frame in
    self?.latestFrame = frame
}
```
- **強参照サイクル**（メモリリーク）を防ぐ
- ViewModelがCancellableを保持し、CancellableがViewModelを参照すると循環参照
- `weak`により弱参照にしてメモリリークを防止

---

### Q3. なぜカメラ起動に`async/await`を使うの？
**A**:
```swift
try await cameraService.setupAndStart()
```
- カメラの初期化は時間がかかる可能性がある
- `async/await`で非同期処理を同期的に書ける
- エラーハンドリングが簡潔（`do-catch`）

---

### Q4. `MainActor.run`とは？
**A**:
```swift
await MainActor.run {
    authenticationState = .failed(...)
}
```
- **MainActor**: メインスレッドで実行することを保証
- UI更新は必ずメインスレッドで行う必要がある
- `async/await`コンテキストでメインスレッドに切り替える

---

### Q5. `CVPixelBuffer`と`CIImage`の違いは？
**A**:
- **CVPixelBuffer**: Core Videoの画像バッファ（カメラからの生データ）
- **CIImage**: Core Imageの画像オブジェクト（画像処理用）
- Vision frameworkは`CIImage`を使用するため変換が必要

---

### Q6. 認証ボタンをタップした後、すぐに結果が出ないのはなぜ？
**A**:
```swift
DispatchQueue.global(qos: .userInitiated).async {
    // 顔認証処理（時間がかかる）
}
```
- 顔認識処理は計算量が多い
- バックグラウンドスレッドで実行してUIをブロックしない
- 処理中は`ProgressView`を表示

---

### Q7. `onAuthenticationSuccess`クロージャの使い方は？
**A**:
```swift
// 定義
var onAuthenticationSuccess: (() -> Void)?

// 呼び出し
onAuthenticationSuccess?()

// 親Viewから渡す
AuthenticationView(onAuthenticationSuccess: {
    print("認証成功")
    // 画面遷移などの処理
})
```
- Optional Closureなので`?`で安全に呼び出し
- 親Viewが画面遷移などの処理を定義

---

### Q8. カメラリソースの管理方法は？
**A**:
```swift
.onAppear {
    viewModel.startCamera()
}
.onDisappear {
    viewModel.stopCamera()
}
```
- 画面表示時にカメラ起動
- 画面非表示時にカメラ停止
- バッテリー節約とリソース管理

---

## まとめ

### Authentication Featureの重要ポイント

1. **状態管理**
   - Enumで認証プロセスの状態を表現
   - 関連値でエラーメッセージを保持
   - `@Published`で自動UI更新

2. **非同期処理**
   - `async/await`でカメラ起動
   - バックグラウンドスレッドで顔認識
   - MainActorでUI更新

3. **Combineフレームワーク**
   - `framePublisher`でフレームデータ受信
   - `sink`でデータを処理
   - `weak self`でメモリリーク防止

4. **セキュリティ**
   - Keychainで顔データ保護
   - Vision frameworkで高精度認証
   - エラーハンドリングの徹底

5. **UX設計**
   - 状態ごとの適切なフィードバック
   - 再試行機能の提供
   - カメラリソースの適切な管理

### 学習の次のステップ

1. **Vision Framework**の詳細学習
2. **Combine Framework**のPublisher/Subscriber
3. **async/await**と並行処理
4. **Keychain Services**のセキュリティ

---

## 参考リンク

### 公式ドキュメント
- [Vision Framework - Apple](https://developer.apple.com/documentation/vision)
- [AVFoundation - Apple](https://developer.apple.com/av-foundation/)
- [Combine - Apple](https://developer.apple.com/documentation/combine)
- [Swift Concurrency - Apple](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

### SwiftUI Concepts
- [State Management](https://developer.apple.com/documentation/swiftui/state-and-data-flow)
- [ZStack](https://developer.apple.com/documentation/swiftui/zstack)
- [Optional Chaining](https://docs.swift.org/swift-book/LanguageGuide/OptionalChaining.html)

### Security
- [Keychain Services - Apple](https://developer.apple.com/documentation/security/keychain_services)
- [Face ID - Apple](https://developer.apple.com/design/human-interface-guidelines/face-id)

---

**このドキュメントについて**
作成日: 2025年
対象: Swift初心者〜中級者
バージョン: FaceDiary v1.0
