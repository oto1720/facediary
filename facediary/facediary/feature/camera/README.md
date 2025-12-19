# Camera Feature - カメラ機能基盤

## 目次
1. [概要](#概要)
2. [SwiftUIとUIKitの連携](#swiftuiとuikitの連携)
3. [ファイル構成](#ファイル構成)
4. [詳細解説](#詳細解説)
5. [連携・関係性](#連携関係性)
6. [実際の使用例](#実際の使用例)
7. [よくある質問](#よくある質問)
8. [まとめ](#まとめ)

---

## 概要

**Camera Feature**は、アプリ全体で使用されるカメラ機能の基盤を提供します。AVFoundationを使用したカメラセッションの管理と、SwiftUIでのプレビュー表示を担当します。

### 主な機能
- **カメラプレビューの表示**: `AVCaptureVideoPreviewLayer`をSwiftUIで表示
- **再利用可能なコンポーネント**: 他のfeatureから利用可能
- **UIKit-SwiftUI ブリッジ**: `UIViewRepresentable`による統合

### このFeatureの重要性
- 他のfeature（Authentication、DiaryEntry、Onboarding）にカメラ機能を提供
- インフラストラクチャとしての役割
- カメラUIの一貫性を保つ

**注意**: このfeatureは主に`CameraPreviewView.swift`のみで構成されています。実際のカメラ制御ロジックは`core/services/CameraService.swift`に実装されています。

---

## SwiftUIとUIKitの連携

### 1. UIViewRepresentable
```swift
struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> VideoPreviewView {
        // UIKitのViewを作成
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        // Viewの更新
    }
}
```
**意味**:
- **UIViewRepresentable**: UIKitのViewをSwiftUIで使えるようにするプロトコル
- `makeUIView`: Viewの初期化（一度だけ呼ばれる）
- `updateUIView`: Viewの更新（状態変更時に呼ばれる）

### 2. AVCaptureVideoPreviewLayer
```swift
view.videoPreviewLayer.session = session
view.videoPreviewLayer.videoGravity = .resizeAspectFill
view.videoPreviewLayer.connection?.videoOrientation = .portrait
```
**意味**:
- **session**: カメラセッションを関連付け
- **videoGravity**: 映像の表示方法（アスペクト比維持して画面を埋める）
- **videoOrientation**: 映像の向き（縦向き）

### 3. Layer Classのオーバーライド
```swift
class VideoPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}
```
**意味**:
- UIViewのlayerを`AVCaptureVideoPreviewLayer`に変更
- これによりViewにカメラ映像を直接描画できる

---

## ファイル構成

```
feature/camera/
├── view/
│   ├── CameraPreviewView.swift    # カメラプレビュー表示（実装済み）
│   └── CameraView.swift           # カメラ単体画面（未実装）
├── viewmodels/
│   └── CameraViewModel.swift      # カメラ制御ViewModel（未実装）
└── README.md                       # このドキュメント
```

**注意**:
- `CameraView.swift`と`CameraViewModel.swift`は現在ほぼ空です
- 実際のカメラ制御は`core/services/CameraService.swift`に実装
- このfeatureは主にUIコンポーネントを提供

### 依存関係図
```
他のFeature (Authentication, DiaryEntry, Onboarding)
    ↓ 利用
CameraPreviewView
    ↓ 表示
AVCaptureVideoPreviewLayer
    ↓ 映像取得
CameraService (core/services)
    ↓ 制御
AVCaptureSession (AVFoundation)
```

---

## 詳細解説

### CameraPreviewView.swift

#### 役割
`AVCaptureVideoPreviewLayer`をSwiftUIで表示するためのラッパービュー。

#### コード解説

##### (1) 全体構造
```swift
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.connection?.videoOrientation = .portrait
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}
```

**プロパティ**:
- `session`: 外部から渡されるカメラセッション

**makeUIView**:
1. `VideoPreviewView`のインスタンスを作成
2. 背景色を黒に設定
3. `session`を`videoPreviewLayer`に関連付け
4. `videoGravity`で映像の表示方法を設定
5. `videoOrientation`で向きを縦に設定

**updateUIView**:
- `session`が変更された時に呼ばれる
- Preview layerのsessionを更新

##### (2) VideoPreviewView の定義
```swift
class VideoPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}
```

**意味**:
- **layerClass**: UIViewが使用するCALayerのクラスを指定
- デフォルトでは`CALayer`だが、`AVCaptureVideoPreviewLayer`に変更
- これによりViewに直接カメラ映像を描画できる

**videoPreviewLayer**:
- 便利プロパティ
- `layer`を`AVCaptureVideoPreviewLayer`型にキャスト
- 型安全にプレビューレイヤーにアクセス可能

##### (3) Video Gravity（映像の表示方法）
```swift
view.videoPreviewLayer.videoGravity = .resizeAspectFill
```

**オプション**:
- **resizeAspectFill**: アスペクト比を維持して画面を埋める（一部切れる可能性）
- **resizeAspect**: アスペクト比を維持して画面に収める（黒帯が出る）
- **resize**: アスペクト比を無視して引き伸ばす

このアプリでは`.resizeAspectFill`を使用してフルスクリーン表示。

---

## 連携・関係性

### 1. 他のFeatureでの使用

#### (1) AuthenticationView
```swift
// AuthenticationView.swift
if let session = viewModel.cameraService.previewLayer.session {
    CameraPreviewView(session: session)
        .ignoresSafeArea()
}
```
- 顔認証画面でカメラプレビューを表示
- 全画面表示（`.ignoresSafeArea()`）

#### (2) DiaryEntryCreateView
```swift
// DiaryEntryCreateView.swift
if let session = viewModel.cameraService.previewLayer.session {
    CameraPreviewView(session: session)
        .ignoresSafeArea()
}
```
- 日記作成画面でカメラプレビューを表示
- 写真撮影用のプレビュー

#### (3) FaceRegistrationView (Onboarding)
```swift
// FaceRegistrationView.swift
CameraPreviewView(session: viewModel.cameraService.captureSession)
    .ignoresSafeArea()
```
- 顔登録画面でカメラプレビューを表示
- 初回登録用のプレビュー

### 2. CameraServiceとの連携

```
CameraService (core/services)
    ↓ captureSession / previewLayer.session
CameraPreviewView
    ↓ 表示
画面
```

**データフロー**:
1. ViewModelが`CameraService`を所有
2. `CameraService`が`AVCaptureSession`を管理
3. ViewModelからsessionを取得
4. `CameraPreviewView`にsessionを渡す
5. プレビューが表示される

---

## 実際の使用例

### ケース1: 認証画面でのプレビュー表示

**シナリオ**: ユーザーが認証画面を開く

**処理フロー**:
1. `AuthenticationView`が表示される
2. `viewModel.startCamera()`が実行される
3. `CameraService`がカメラセッションを起動
4. `previewLayer.session`が利用可能になる
5. `CameraPreviewView`が表示される
6. カメラ映像がリアルタイムで表示される

**コード**:
```swift
ZStack {
    if let session = viewModel.cameraService.previewLayer.session {
        CameraPreviewView(session: session)
            .ignoresSafeArea()
    }

    // UIオーバーレイ
    VStack {
        // ボタンやテキスト
    }
}
```

---

### ケース2: 日記作成画面での使用

**シナリオ**: ユーザーが写真を撮影する

**処理フロー**:
1. `DiaryEntryCreateView`が表示される
2. カメラプレビューが表示される
3. ユーザーが撮影ボタンをタップ
4. `viewModel.capturePhotoAndAnalyze()`が実行される
5. 写真が撮影される（`CameraService`経由）
6. プレビューは継続して表示される

---

## よくある質問

### Q1. なぜ`UIViewRepresentable`を使うの？
**A**:
- SwiftUIは`AVCaptureVideoPreviewLayer`を直接サポートしていない
- `UIViewRepresentable`でUIKitのViewをSwiftUIで使えるようにする
- 既存のAVFoundation APIを活用できる

---

### Q2. `makeUIView`と`updateUIView`の違いは？
**A**:
- **makeUIView**: Viewの初期化時に一度だけ呼ばれる
- **updateUIView**: SwiftUIの状態が変わるたびに呼ばれる（更新用）

---

### Q3. `layerClass`をオーバーライドする理由は？
**A**:
```swift
override class var layerClass: AnyClass {
    AVCaptureVideoPreviewLayer.self
}
```
- UIViewのlayerを`AVCaptureVideoPreviewLayer`に変更
- カメラ映像を直接Viewに描画できる
- パフォーマンスが向上する

---

### Q4. `.ignoresSafeArea()`の役割は？
**A**:
```swift
CameraPreviewView(session: session)
    .ignoresSafeArea()
```
- Safe Areaを無視してフルスクリーン表示
- ノッチやホームインジケーターの領域まで表示
- カメラプレビューは全画面表示が一般的

---

### Q5. CameraServiceとの違いは？
**A**:
- **CameraService** (`core/services`): カメラのビジネスロジック（セッション管理、写真撮影など）
- **CameraPreviewView** (`feature/camera`): UI表示のみ（プレビュー表示）
- 責務の分離（Service層とView層）

---

### Q6. なぜCameraView.swiftは空なの？
**A**:
- `CameraPreviewView`が再利用可能なコンポーネントとして十分機能している
- 独立したカメラ画面が現時点では不要
- 必要に応じて将来実装可能

---

## まとめ

### Camera Featureの重要ポイント

1. **UIKit-SwiftUI統合**
   - `UIViewRepresentable`でブリッジ
   - AVFoundationをSwiftUIで利用
   - 再利用可能なコンポーネント

2. **責務の分離**
   - View: プレビュー表示のみ
   - Service: カメラ制御ロジック
   - 明確な役割分担

3. **再利用性**
   - Authentication、DiaryEntry、Onboardingで共用
   - sessionを渡すだけで使用可能
   - 一貫したカメラUI

4. **シンプルな設計**
   - 最小限の実装
   - 理解しやすいコード
   - 保守性の高さ

### 学習の次のステップ

1. **AVFoundation**の詳細学習
2. **UIViewRepresentable**の深掘り
3. **CameraService**の実装確認（`core/services`）
4. カスタムカメラUIの実装

---

## 参考リンク

### 公式ドキュメント
- [AVFoundation - Apple](https://developer.apple.com/av-foundation/)
- [UIViewRepresentable - Apple](https://developer.apple.com/documentation/swiftui/uiviewrepresentable)
- [AVCaptureVideoPreviewLayer - Apple](https://developer.apple.com/documentation/avfoundation/avcapturevideopreviewlayer)

### チュートリアル
- [SwiftUI + AVFoundation](https://developer.apple.com/documentation/avfoundation/capture_setup)
- [Custom Camera in SwiftUI](https://www.hackingwithswift.com/quick-start/swiftui/how-to-wrap-a-custom-uiview-for-swiftui)

---

**このドキュメントについて**
作成日: 2025年
対象: Swift初心者〜中級者
バージョン: FaceDiary v1.0
