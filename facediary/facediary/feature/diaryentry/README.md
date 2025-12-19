# DiaryEntry Feature - 日記作成・表示機能

## 目次
1. [概要](#概要)
2. [ファイル構成](#ファイル構成)
3. [詳細解説](#詳細解説)
4. [よくある質問](#よくある質問)
5. [まとめ](#まとめ)

---

## 概要

**DiaryEntry Feature**は、新しい日記を作成し、閲覧する機能です。写真撮影による感情分析と、テキスト入力、気分の手動選択を組み合わせた日記作成フローを提供します。

### 主な機能
- **写真撮影と感情分析**: カメラで自分の顔を撮影し、AIが感情を分析
- **気分の選択**: 分析された感情または手動で気分を選択
- **日記の記入**: テキストエディタで日記本文を入力
- **詳細表示**: 作成済み日記の閲覧

---

## ファイル構成

```
feature/diaryentry/
├── view/
│   ├── DiaryEntryCreateView.swift    # 日記作成画面
│   └── DiaryEntryDetailView.swift    # 日記詳細画面
├── viewmodels/
│   └── DiaryEntryViewModel.swift     # 日記作成ViewModel
└── README.md
```

---

## 詳細解説

### 1. DiaryEntryCreateView.swift

#### 役割
日記作成のウィザード形式UIを提供。カメラ撮影→感情分析→テキスト入力の流れを管理。

#### 重要なポイント

##### (1) 2段階のUI
```swift
if viewModel.capturedPhotoData == nil {
    cameraView  // Step 1: 撮影
} else {
    diaryInputView  // Step 2: 入力
}
```
- 写真撮影前: カメラプレビュー + 撮影ボタン
- 撮影後: 写真プレビュー + 気分選択 + テキスト入力

##### (2) 感情スコア表示
```swift
let sortedMoods = MoodAnalyzer.sortedMoods(from: viewModel.moodScores)
ForEach(sortedMoods, id: \.mood) { item in
    moodCard(mood: item.mood, score: item.score)
}
```
- AIが分析した感情をスコア順に表示
- ユーザーが任意の気分を選択可能

##### (3) コールバックパターン
```swift
var onComplete: (() -> Void)?

.onChange(of: viewModel.saveSucceeded) { succeeded in
    if succeeded {
        onComplete?()
        dismiss()
    }
}
```
- 保存成功時に親Viewに通知
- 自動的に画面を閉じる

---

### 2. DiaryEntryViewModel.swift

#### 役割
日記作成プロセスの制御、写真撮影、感情分析、データ保存を担当。

#### 重要なメソッド

##### (1) 写真撮影と分析
```swift
func capturePhotoAndAnalyze() {
    isProcessing = true
    cameraService.takePhoto()
}
```
**処理フロー**:
1. `takePhoto()`でカメラ撮影
2. `photoPublisher`経由で写真データを受信
3. `analyzeFaceAndMood()`で感情分析
4. `moodScores`を更新

##### (2) 顔認識と感情分析
```swift
private func analyzeFaceAndMood(from photoData: Data) {
    let result = try faceRecognitionService.recognizeFace(
        from: ciImage,
        referenceFaceData: referenceFaceData
    )

    if result.isAuthenticated {
        self.moodScores = result.moodScores
        self.selectedMood = MoodAnalyzer.primaryMood(from: result.moodScores)
    }
}
```
- 登録済み顔データと照合
- 認証成功時のみ感情スコアを取得
- 主要な感情を自動選択

##### (3) 日記の保存
```swift
func saveDiary(completion: @escaping (Bool) -> Void) {
    var entries = try persistenceService.load()

    let newEntry = DiaryEntry(
        date: Date(),
        text: diaryText,
        photoData: photoData,
        moodScores: moodScores
    )

    entries.insert(newEntry, at: 0)
    try persistenceService.save(entries: entries)

    saveSucceeded = true
    HapticFeedback.success()
}
```
- 既存の日記配列を読み込み
- 新しいエントリを先頭に追加
- ファイルシステムに保存
- Haptic Feedbackで触覚フィードバック

---

### 3. DiaryEntryDetailView.swift

#### 役割
作成済み日記の詳細を表示。

#### 表示内容
- 日付と時刻
- 撮影した写真
- 主要な感情（絵文字と名前）
- 感情スコア（複数ある場合）
- 日記本文

#### 編集・削除機能
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
            Button("Edit") { showingEditSheet = true }
            Button("Delete", role: .destructive) { showingDeleteAlert = true }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
```
- ツールバーのメニューから編集・削除
- 削除時は確認アラート表示

---

## よくある質問

### Q1. 撮影した写真はどこに保存される？
**A**: `DiaryEntry`の`photoData: Data?`プロパティとしてメモリ上に保持され、`DataPersistenceService`経由でファイルシステムに保存されます。

### Q2. なぜ顔認証が必要なの？
**A**: 
- 登録済みユーザー本人の顔であることを確認
- 本人の表情から正確に感情を分析するため
- セキュリティとプライバシー保護

### Q3. 感情分析が失敗したら？
**A**: 
```swift
if result.isAuthenticated {
    // 感情スコア取得
} else {
    self.errorMessage = "Face not recognized"
    self.capturedPhotoData = nil  // 撮影からやり直し
}
```
- 認証失敗時はエラーメッセージを表示
- 写真をクリアして撮影からやり直し

### Q4. 気分を後から変更できる？
**A**: 
```swift
ForEach(Mood.allCases, id: \.self) { mood in
    Button(action: { viewModel.updateMood(mood) }) {
        // 気分選択ボタン
    }
}
```
- 保存前なら全ての気分から選択可能
- AIの分析結果を上書きできる

### Q5. Combineのバインディングは？
**A**:
```swift
cameraService.photoPublisher
    .receive(on: DispatchQueue.main)
    .sink(receiveValue: { [weak self] photoData in
        self?.capturedPhotoData = photoData
        self?.analyzeFaceAndMood(from: photoData)
    })
    .store(in: &cancellables)
```
- `photoPublisher`から写真データを受信
- 自動的に感情分析を開始
- Reactive Programming パターン

---

## まとめ

### DiaryEntry Featureの重要ポイント

1. **2段階のワークフロー**
   - Step 1: 写真撮影
   - Step 2: 感情選択 + テキスト入力

2. **AI感情分析**
   - Vision Frameworkによる顔認識
   - 感情スコアの自動算出
   - 手動上書き可能

3. **Combineフレームワーク**
   - Reactive なデータフロー
   - `photoPublisher`による非同期処理
   - メモリリーク防止（weak self）

4. **バリデーション**
   - 顔認証による本人確認
   - テキスト入力の検証
   - エラーハンドリング

### 学習の次のステップ
1. Vision Framework の詳細
2. Combine Framework の Publisher/Subscriber
3. Haptic Feedback の実装
4. データ永続化の仕組み

---

**このドキュメントについて**
作成日: 2025年
対象: Swift初心者〜中級者
バージョン: FaceDiary v1.0
