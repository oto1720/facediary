# Settings Feature - 設定機能

## 目次
1. [概要](#概要)
2. [ファイル構成](#ファイル構成)
3. [詳細解説](#詳細解説)
4. [よくある質問](#よくある質問)
5. [まとめ](#まとめ)

---

## 概要

**Settings Feature**は、アプリの設定、データ管理、アプリ情報の表示を行う機能です。ユーザーデータの削除やエクスポート、顔認証データのリセットなどの管理機能を提供します。

### 主な機能
- **アプリ情報**: アプリ名とバージョン表示
- **データ管理**: 日記のエクスポートと一括削除
- **セキュリティ**: 顔データのリセット
- **About**: プライバシーポリシーと利用規約へのリンク

---

## ファイル構成

```
feature/settings/
├── view/
│   └── SettingsView.swift        # 設定画面UI
├── viewmodels/
│   └── SettingsViewModel.swift   # 設定操作ViewModel
└── README.md
```

---

## 詳細解説

### 1. SettingsView.swift

#### 役割
リスト形式の設定画面。各種設定項目とアクションボタンを提供。

#### セクション構成

##### (1) App Info（アプリ情報）
```swift
Section(header: Text("App Info")) {
    HStack {
        Text("App Name")
        Spacer()
        Text(Constants.appName)
    }

    HStack {
        Text("Version")
        Spacer()
        Text(viewModel.getAppVersion())
    }
}
```
- アプリ名: 定数から取得
- バージョン: Bundle情報から動的取得

##### (2) Data Management（データ管理）
```swift
Section(header: Text("Data Management")) {
    Button(action: {
        viewModel.showingExportSheet = true
    }) {
        HStack {
            Image(systemName: "square.and.arrow.up")
            Text("Export Diary Entries")
        }
    }

    Button(role: .destructive, action: {
        viewModel.showingDeleteConfirmation = true
    }) {
        HStack {
            Image(systemName: "trash")
            Text("Delete All Diaries")
        }
    }
}
```
- エクスポート: JSON形式で書き出し
- 削除: 確認アラート後に全削除

##### (3) Security（セキュリティ）
```swift
Section(header: Text("Security")) {
    Button(role: .destructive, action: {
        viewModel.deleteFaceData()
        onFaceDataDeleted?()
    }) {
        HStack {
            Image(systemName: "faceid")
            Text("Reset Face Data")
        }
    }
}
```
- 顔データの削除
- 削除後はOnboardingから再登録が必要

##### (4) About（アプリについて）
```swift
Section(header: Text("About")) {
    Link(destination: URL(string: "https://example.com/privacy")!) {
        HStack {
            Image(systemName: "lock.shield")
            Text("Privacy Policy")
            Spacer()
            Image(systemName: "arrow.up.right.square")
        }
    }

    Link(destination: URL(string: "https://example.com/terms")!) {
        HStack {
            Image(systemName: "doc.text")
            Text("Terms of Service")
            Spacer()
            Image(systemName: "arrow.up.right.square")
        }
    }
}
```
- 外部リンク（Safariで開く）
- プライバシーポリシーと利用規約

##### (5) アラート表示
```swift
.alert("Delete All Diaries", isPresented: $viewModel.showingDeleteConfirmation) {
    Button("Cancel", role: .cancel) {}
    Button("Delete", role: .destructive) {
        viewModel.deleteAllDiaries()
    }
} message: {
    Text("Are you sure you want to delete all diary entries? This action cannot be undone.")
}
```
- 破壊的な操作には確認アラート
- キャンセル可能

##### (6) ShareSheet（エクスポート用）
```swift
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
}
```
- UIKitの`UIActivityViewController`をSwiftUIで使用
- 共有シート（ファイル保存、メール送信など）

---

### 2. SettingsViewModel.swift

#### 役割
設定アクションの実行を担当。

#### 重要なメソッド

##### (1) 顔データの削除
```swift
func deleteFaceData() {
    do {
        try securityService.deleteFaceData()
        successMessage = "Face data has been deleted."
        HapticFeedback.success()
    } catch {
        errorMessage = "Failed to delete face data: \(error.localizedDescription)"
        HapticFeedback.error()
    }
}
```
- Keychainから顔データを削除
- 成功/失敗でHaptic Feedback
- メッセージをアラート表示

##### (2) 全日記の削除
```swift
func deleteAllDiaries() {
    do {
        try persistenceService.save(entries: [])
        successMessage = "All diary entries have been deleted."
        HapticFeedback.success()
    } catch {
        errorMessage = "Failed to delete diary entries: \(error.localizedDescription)"
        HapticFeedback.error()
    }
}
```
- 空配列を保存することで全削除
- シンプルな実装

##### (3) 日記のエクスポート
```swift
func exportDiaries() -> String? {
    do {
        let entries = try persistenceService.load()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(entries)
        return String(data: data, encoding: .utf8)
    } catch {
        errorMessage = "Failed to export diaries: \(error.localizedDescription)"
        return nil
    }
}
```
- 日記データをJSON形式に変換
- ISO 8601フォーマットで日付を出力
- Pretty Print（読みやすい形式）

##### (4) アプリバージョン取得
```swift
func getAppVersion() -> String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    return "Version \(version) (Build \(build))"
}
```
- Bundle情報からバージョンとビルド番号を取得
- 例: "Version 1.0 (Build 123)"

---

## よくある質問

### Q1. なぜ削除に確認アラートが必要？
**A**:
```swift
Button(role: .destructive, action: {
    viewModel.showingDeleteConfirmation = true
})
```
- 誤操作を防ぐ
- 破壊的な操作（取り消せない）
- ユーザー体験のベストプラクティス

### Q2. エクスポートしたデータの形式は？
**A**:
```swift
encoder.dateEncodingStrategy = .iso8601
encoder.outputFormatting = .prettyPrinted
```
- JSON形式
- 日付はISO 8601（標準形式）
- 人間が読みやすい形式（インデント付き）

### Q3. 顔データ削除後はどうなる？
**A**:
- Keychainから完全削除
- 次回起動時にOnboarding画面へ
- 再度顔登録が必要

### Q4. Haptic Feedbackの役割は？
**A**:
```swift
HapticFeedback.success()  // 成功時の振動
HapticFeedback.error()    // 失敗時の振動
```
- 触覚フィードバックで操作結果を伝える
- 視覚情報を補完
- アクセシビリティ向上

### Q5. ShareSheetで何ができる？
**A**:
- ファイルとして保存
- メール/メッセージで送信
- クラウドサービスにアップロード
- 他のアプリと共有

---

## まとめ

### Settings Featureの重要ポイント

1. **データ管理**
   - エクスポート（バックアップ）
   - 一括削除（リセット）
   - JSON形式

2. **セキュリティ**
   - 顔データの管理
   - 確認アラート
   - 取り消せない操作への配慮

3. **UI/UX**
   - リスト形式
   - セクション分け
   - 破壊的アクションの色分け（赤）

4. **エラーハンドリング**
   - try-catch
   - ユーザーフレンドリーなメッセージ
   - Haptic Feedback

5. **UIKit統合**
   - UIActivityViewController
   - UIViewControllerRepresentable
   - 既存のiOS機能を活用

### 学習の次のステップ
1. UIActivityViewController の詳細
2. Bundle と Info.plist
3. JSONEncoder/Decoder
4. Haptic Feedback の種類

---

**このドキュメントについて**
作成日: 2025年
対象: Swift初心者〜中級者
バージョン: FaceDiary v1.0
