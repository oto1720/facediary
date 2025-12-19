# Core Utilities

## 目次
1. [Overview（概要）](#overview)
2. [Swiftの基礎知識](#swiftの基礎知識)
3. [ファイル構成](#ファイル構成)
4. [詳細解説](#詳細解説)
5. [実際の使用例](#実際の使用例)
6. [よくある質問](#よくある質問)

---

## Overview
アプリケーション全体で再利用される定数、拡張機能、ヘルパークラスをまとめたディレクトリです。

ユーティリティ層は、アプリのあらゆる場所から使用される「共通ツール箱」のような役割を果たします。
コードの重複を避け、一貫性を保つために重要です。

**ユーティリティとは？**
- **Constants（定数）**: マジックナンバーを避け、設定値を一箇所で管理
- **Extensions（拡張）**: 既存の型に新しい機能を追加
- **Helpers（ヘルパー）**: 特定の処理をカプセル化した便利関数

---

## Swiftの基礎知識

### Extension（拡張）
Swiftでは、既存の型（クラス、構造体、列挙型）に新しい機能を追加できます。

```swift
// Dateに新しいメソッドを追加
extension Date {
    func formatted(as format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

// 使用例
let date = Date()
let dateString = date.formatted(as: "yyyy/MM/dd")
```

**Extensionの利点：**
- 元のソースコードを変更せずに機能追加
- コードの見通しが良くなる
- 関連する機能をグループ化できる

**Extensionで追加できるもの：**
- 算出プロパティ（保存プロパティは不可）
- メソッド
- イニシャライザ
- サブスクリプト
- 入れ子の型

### Enum（列挙型）をネームスペースとして使う
Swiftでは、静的メソッドをグループ化するためにenumを使うことがあります。

```swift
enum ImageHelper {
    static func resize(image: UIImage, targetSize: CGSize) -> UIImage? {
        // リサイズ処理
    }

    static func compress(image: UIImage) -> Data? {
        // 圧縮処理
    }
}

// 使用例
let resized = ImageHelper.resize(image: myImage, targetSize: CGSize(width: 100, height: 100))
```

**なぜenumなのか？**
- インスタンス化を防げる（`private init() {}`を書く必要がない）
- 関連する機能をグループ化できる
- 名前空間として機能する

### Optional Chaining（オプショナルチェイニング）
`?`を使って、nilの可能性がある値を安全にアクセスできます。

```swift
let text: String? = "Hello"
let count = text?.count  // Optional<Int>
// textがnilなら、countもnil
// textに値があれば、countにはその文字数が入る
```

### Nil-Coalescing Operator（nil合体演算子）
`??`を使って、nilの場合のデフォルト値を指定できます。

```swift
let name: String? = nil
let displayName = name ?? "ゲスト"  // "ゲスト"
```

### Generic（ジェネリック）
型をパラメータ化して、再利用可能なコードを書けます。

```swift
func swap<T>(_ a: inout T, _ b: inout T) {
    let temp = a
    a = b
    b = temp
}

var x = 5
var y = 10
swap(&x, &y)  // x=10, y=5

var str1 = "Hello"
var str2 = "World"
swap(&str1, &str2)  // str1="World", str2="Hello"
```

---

## ファイル構成

```
core/utilities/
├── Constants.swift      # アプリ全体の定数管理
├── Extensions.swift     # 標準型の拡張機能
└── Helpers.swift        # 便利関数のコレクション
```

---

## 詳細解説

### 1. Constants.swift
**ファイルパス**: `facediary/facediary/core/utilities/Constants.swift:1`

#### 役割
アプリ全体で使用される定数を一箇所で管理します。
マジックナンバーやハードコードされた文字列を避けるための設計パターンです。

#### なぜ定数を使うのか？

**悪い例（マジックナンバー）：**
```swift
if confidence > 0.7 {  // 0.7って何？
    print("認証成功")
}

let filename = "diaryEntries.json"  // 他の場所で "diaryEntrie.json" とタイプミスする可能性
```

**良い例（定数を使用）：**
```swift
if confidence > Constants.minimumFaceMatchConfidence {  // 意味が明確
    print("認証成功")
}

let filename = Constants.diaryEntriesFileName  // タイプミスを防げる
```

#### 定数のカテゴリ別解説

**App Info（アプリ情報）**
```swift
static let appName = "FaceDiary"
static let bundleIdentifier = "com.example.facediary"
```
- **用途**: アプリ名やバンドルIDを参照
- **例**: ログ出力、アナリティクス、ディープリンクなど

**Face Recognition（顔認識）**
```swift
static let minimumFaceMatchConfidence: Double = 0.7
static let recommendedFaceRegistrationCount = 5
```
- `minimumFaceMatchConfidence`: 顔認証の最低信頼度（0.7 = 70%）
- `recommendedFaceRegistrationCount`: 推奨される顔登録回数

**なぜ複数回登録するのか？**
異なる角度や照明条件での顔データを登録することで、認証精度が向上します。

**Mood Analysis（感情分析）**
```swift
static let minimumMoodConfidence: Double = 0.3
```
- 感情スコアの最低閾値（30%未満は無視）

**Storage（保存関連）**
```swift
static let faceDataKeychainService = "com.example.facediary.FaceData"
static let faceDataKeychainAccount = "currentUser"
static let diaryEntriesFileName = "diaryEntries.json"
```
- Keychainのサービス名とアカウント名
- 日記データのファイル名

**UI（ユーザーインターフェース）**
```swift
static let cameraAspectRatio: CGFloat = 3.0 / 4.0
static let defaultAnimationDuration: Double = 0.3
static let defaultCornerRadius: CGFloat = 10
```
- `cameraAspectRatio`: カメラプレビューのアスペクト比（3:4）
- `defaultAnimationDuration`: アニメーションの標準時間（0.3秒）
- `defaultCornerRadius`: UIコンポーネントの角丸半径（10ポイント）

**Date Formats（日付フォーマット）**
```swift
static let dateFormat = "yyyy/MM/dd"
static let timeFormat = "HH:mm"
static let dateTimeFormat = "yyyy/MM/dd HH:mm"
```
- 日付を文字列に変換する際の標準フォーマット

**例：**
```swift
let date = Date()
let dateString = date.formatted(as: Constants.dateFormat)
// "2025/10/30"
```

#### 使用例

```swift
// 顔認証の信頼度をチェック
if faceMatchScore >= Constants.minimumFaceMatchConfidence {
    authenticateUser()
}

// アニメーション
withAnimation(.easeInOut(duration: Constants.defaultAnimationDuration)) {
    // UIの変更
}

// 角丸のボタン
Button("保存") { }
    .cornerRadius(Constants.defaultCornerRadius)
```

---

### 2. Extensions.swift
**ファイルパス**: `facediary/facediary/core/utilities/Extensions.swift:1`

#### 役割
Swiftの標準型やSwiftUIの型に便利な機能を追加します。

---

#### Date Extension

**formatted メソッド**
```swift
func formatted(as format: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter.string(from: self)
}
```
- 日付を指定したフォーマットで文字列に変換

**使用例：**
```swift
let date = Date()
print(date.formatted(as: "yyyy年MM月dd日"))  // "2025年10月30日"
print(date.formatted(as: "HH:mm"))  // "14:30"
```

**startOfDay プロパティ**
```swift
var startOfDay: Date {
    Calendar.current.startOfDay(for: self)
}
```
- 日付の時刻部分を00:00:00にする

**例：**
```swift
let now = Date()  // 2025-10-30 14:30:45
let start = now.startOfDay  // 2025-10-30 00:00:00
```

**用途：**
日付の比較や、日ごとのデータ集計に使用します。

**isSameDay メソッド**
```swift
func isSameDay(as otherDate: Date) -> Bool {
    Calendar.current.isDate(self, inSameDayAs: otherDate)
}
```
- 2つの日付が同じ日かどうかを判定

**例：**
```swift
let date1 = Date()  // 2025-10-30 14:30:00
let date2 = Date().addingTimeInterval(3600)  // 2025-10-30 15:30:00
date1.isSameDay(as: date2)  // true（同じ日）

let date3 = Date().addingTimeInterval(86400)  // 明日
date1.isSameDay(as: date3)  // false（異なる日）
```

**adding メソッド**
```swift
func adding(days: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
}
```
- 指定した日数を追加

**例：**
```swift
let today = Date()
let tomorrow = today.adding(days: 1)
let lastWeek = today.adding(days: -7)
```

**startOfMonth / endOfMonth プロパティ**
```swift
var startOfMonth: Date {
    let components = Calendar.current.dateComponents([.year, .month], from: self)
    return Calendar.current.date(from: components) ?? self
}

var endOfMonth: Date {
    guard let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)),
          let end = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: start) else {
        return self
    }
    return end
}
```
- 月の最初と最後の日を取得

**例：**
```swift
let date = Date()  // 2025-10-30
let monthStart = date.startOfMonth  // 2025-10-01 00:00:00
let monthEnd = date.endOfMonth  // 2025-10-31 23:59:59
```

---

#### String Extension

**isBlank プロパティ**
```swift
var isBlank: Bool {
    return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}
```
- 空文字列または空白のみかどうかを判定

**例：**
```swift
"".isBlank  // true
"   ".isBlank  // true
"Hello".isBlank  // false
" Hello ".isBlank  // false
```

**用途：**
ユーザー入力のバリデーションに使用します。

**truncated メソッド**
```swift
func truncated(to length: Int, trailing: String = "...") -> String {
    if self.count > length {
        return String(self.prefix(length)) + trailing
    }
    return self
}
```
- 文字列を指定した長さに切り詰める

**例：**
```swift
let text = "今日はとても楽しい一日でした。"
print(text.truncated(to: 10))  // "今日はとても楽し..."
print(text.truncated(to: 10, trailing: "…"))  // "今日はとても楽し…"
```

**用途：**
リスト表示で長いテキストを省略する際に使用します。

---

#### Color Extension

**color(for:) メソッド**
```swift
static func color(for mood: Mood) -> Color {
    switch mood {
    case .happiness: return .yellow
    case .sadness: return .blue
    case .anger: return .red
    case .surprise: return .orange
    case .calm: return .green
    case .neutral: return .gray
    }
}
```
- 感情に対応する色を返す

**使用例：**
```swift
let mood = Mood.happiness
let color = Color.color(for: mood)  // .yellow

Circle()
    .fill(Color.color(for: entry.primaryMood ?? .neutral))
```

**init(hex:) イニシャライザ**
```swift
init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    // RGB値を計算してColorを作成
}
```
- Hex文字列からColorを作成

**使用例：**
```swift
let red = Color(hex: "FF0000")
let blue = Color(hex: "#0000FF")
let green = Color(hex: "00FF00")
let transparent = Color(hex: "80FF0000")  // アルファ値付き
```

**サポートするフォーマット：**
- 3桁: `RGB` (例: "F00" → 赤)
- 6桁: `RRGGBB` (例: "FF0000" → 赤)
- 8桁: `AARRGGBB` (例: "80FF0000" → 半透明の赤)

---

#### Array<DiaryEntry> Extension

**filtered(from:to:) メソッド**
```swift
func filtered(from startDate: Date, to endDate: Date) -> [DiaryEntry] {
    return filter { entry in
        entry.date >= startDate && entry.date <= endDate
    }
}
```
- 日付範囲でエントリーをフィルタリング

**使用例：**
```swift
let entries: [DiaryEntry] = // ...
let weekStart = DateHelper.startOfWeek
let today = Date()
let thisWeekEntries = entries.filtered(from: weekStart, to: today)
```

**filtered(by:) メソッド**
```swift
func filtered(by mood: Mood) -> [DiaryEntry] {
    return filter { entry in
        entry.primaryMood == mood
    }
}
```
- 特定の感情でフィルタリング

**使用例：**
```swift
let happyEntries = entries.filtered(by: .happiness)
print("\(mood.emoji)の日記: \(happyEntries.count)件")
```

**groupedByDate() メソッド**
```swift
func groupedByDate() -> [Date: [DiaryEntry]] {
    return Dictionary(grouping: self) { entry in
        entry.date.startOfDay
    }
}
```
- 日付ごとにエントリーをグループ化

**使用例：**
```swift
let grouped = entries.groupedByDate()
// [
//   2025-10-30 00:00:00: [entry1, entry2],
//   2025-10-31 00:00:00: [entry3],
//   ...
// ]

for (date, dayEntries) in grouped.sorted(by: { $0.key > $1.key }) {
    print("\(date.formatted(as: "yyyy/MM/dd")): \(dayEntries.count)件")
}
```

---

#### View Extension

**cornerRadius(_:corners:) メソッド**
```swift
func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
}
```
- 特定の角だけを丸める

**使用例：**
```swift
Rectangle()
    .fill(Color.blue)
    .cornerRadius(20, corners: [.topLeft, .topRight])
    // 上の角だけ丸い
```

**標準の`.cornerRadius()`との違い：**
- 標準: 全ての角が丸くなる
- 拡張版: 指定した角だけ丸くなる

---

### 3. Helpers.swift
**ファイルパス**: `facediary/facediary/core/utilities/Helpers.swift:1`

#### 役割
特定の処理をカプセル化した便利関数を提供します。

---

#### ImageHelper

**image(from:) メソッド**
```swift
static func image(from data: Data?) -> UIImage? {
    guard let data = data else { return nil }
    return UIImage(data: data)
}
```
- DataをUIImageに変換

**使用例：**
```swift
let photoData: Data? = entry.photoData
if let image = ImageHelper.image(from: photoData) {
    // 画像を表示
}
```

**data(from:compressionQuality:) メソッド**
```swift
static func data(from image: UIImage, compressionQuality: CGFloat = 0.8) -> Data? {
    return image.jpegData(compressionQuality: compressionQuality)
}
```
- UIImageをJPEGデータに変換（圧縮）

**使用例：**
```swift
let image = UIImage(named: "photo")!
let data = ImageHelper.data(from: image, compressionQuality: 0.8)
// 0.8 = 80%品質（品質と容量のバランスが良い）
```

**compressionQualityの目安：**
- `1.0`: 最高品質（大きいファイルサイズ）
- `0.8`: 高品質（推奨）
- `0.5`: 中品質
- `0.3`: 低品質（小さいファイルサイズ）

**resize メソッド**
```swift
static func resize(image: UIImage, targetSize: CGSize) -> UIImage? {
    let size = image.size
    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height

    let newSize: CGSize
    if widthRatio > heightRatio {
        newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
        newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
    }

    let rect = CGRect(origin: .zero, size: newSize)

    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage
}
```
- 画像をリサイズ（アスペクト比を保つ）

**使用例：**
```swift
let originalImage = UIImage(named: "photo")!  // 4000x3000
let thumbnail = ImageHelper.resize(
    image: originalImage,
    targetSize: CGSize(width: 200, height: 200)
)  // 200x150（アスペクト比を保つ）
```

---

#### MoodAnalyzer

**primaryMood(from:) メソッド**
```swift
static func primaryMood(from scores: [Mood: Double]) -> Mood? {
    return scores.max(by: { $0.value < $1.value })?.key
}
```
- 最もスコアが高い感情を取得

**使用例：**
```swift
let scores: [Mood: Double] = [
    .happiness: 0.8,
    .surprise: 0.15,
    .neutral: 0.05
]
let primary = MoodAnalyzer.primaryMood(from: scores)  // .happiness
```

**sortedMoods(from:) メソッド**
```swift
static func sortedMoods(from scores: [Mood: Double]) -> [(mood: Mood, score: Double)] {
    return scores.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
}
```
- 感情をスコアの高い順にソート

**使用例：**
```swift
let sorted = MoodAnalyzer.sortedMoods(from: scores)
// [
//   (mood: .happiness, score: 0.8),
//   (mood: .surprise, score: 0.15),
//   (mood: .neutral, score: 0.05)
// ]

for (mood, score) in sorted {
    print("\(mood.emoji): \(MoodAnalyzer.percentageString(from: score))")
}
// 😄: 80%
// 😮: 15%
// 😐: 5%
```

**percentageString(from:) メソッド**
```swift
static func percentageString(from score: Double) -> String {
    return String(format: "%.0f%%", score * 100)
}
```
- スコアをパーセンテージ文字列に変換

---

#### DateHelper

**today / yesterday プロパティ**
```swift
static var today: Date {
    return Date()
}

static var yesterday: Date {
    return Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
}
```
- 今日と昨日の日付を取得

**startOfWeek / startOfMonth プロパティ**
```swift
static var startOfWeek: Date {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
    return calendar.date(from: components) ?? today
}

static var startOfMonth: Date {
    return today.startOfMonth
}
```
- 今週/今月の開始日を取得

**dateRange(from:to:) メソッド**
```swift
static func dateRange(from startDate: Date, to endDate: Date) -> [Date] {
    var dates: [Date] = []
    var currentDate = startDate

    while currentDate <= endDate {
        dates.append(currentDate)
        guard let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else {
            break
        }
        currentDate = nextDate
    }

    return dates
}
```
- 日付の範囲を配列で取得

**使用例：**
```swift
let start = DateHelper.startOfWeek
let end = Date()
let dates = DateHelper.dateRange(from: start, to: end)
// [今週の月曜日, 火曜日, ..., 今日]

for date in dates {
    print(date.formatted(as: "MM/dd"))
}
```

---

#### Validator

**isNotEmpty メソッド**
```swift
static func isNotEmpty(_ string: String) -> Bool {
    return !string.isBlank
}
```
- 文字列が空でないかチェック

**isValidDiaryText メソッド**
```swift
static func isValidDiaryText(_ text: String) -> Bool {
    return isNotEmpty(text) && text.count >= 1 && text.count <= 10000
}
```
- 日記のテキストが有効かチェック
- 条件: 空でない、1文字以上、10,000文字以下

**使用例：**
```swift
let userInput = textField.text ?? ""
if !Validator.isValidDiaryText(userInput) {
    showAlert("日記の内容を入力してください（1〜10,000文字）")
    return
}
```

**isValidImageData メソッド**
```swift
static func isValidImageData(_ data: Data?) -> Bool {
    guard let data = data else { return false }
    return data.count > 0 && data.count < 10_000_000 // 10MB
}
```
- 画像データが有効かチェック
- 条件: 存在する、0バイトより大きい、10MB未満

**使用例：**
```swift
if !Validator.isValidImageData(photoData) {
    showAlert("画像データが無効です（最大10MB）")
    return
}
```

---

#### HapticFeedback

Haptic Feedbackは、触覚フィードバックを提供する機能です。
ユーザーの操作に対して、振動で応答します。

**success() メソッド**
```swift
static func success() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)
}
```
- 成功の振動（短く軽い振動）

**使用例：**
```swift
// 日記保存成功時
try dataPersistence.save(entries: entries)
HapticFeedback.success()
showAlert("保存しました")
```

**error() メソッド**
```swift
static func error() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.error)
}
```
- エラーの振動（やや強めの振動）

**使用例：**
```swift
// 顔認証失敗時
if !result.isAuthenticated {
    HapticFeedback.error()
    showAlert("認証に失敗しました")
}
```

**warning() メソッド**
```swift
static func warning() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.warning)
}
```
- 警告の振動（中程度の振動）

**selection() メソッド**
```swift
static func selection() {
    let generator = UISelectionFeedbackGenerator()
    generator.selectionChanged()
}
```
- 選択の振動（非常に軽い振動）

**使用例：**
```swift
// ピッカーの選択時
Picker("感情", selection: $selectedMood) {
    ForEach(Mood.allCases, id: \.self) { mood in
        Text(mood.emoji)
    }
}
.onChange(of: selectedMood) { _ in
    HapticFeedback.selection()
}
```

**lightImpact() メソッド**
```swift
static func lightImpact() {
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
}
```
- 軽い衝撃の振動

**使用例：**
```swift
// ボタンタップ時
Button("保存") {
    HapticFeedback.lightImpact()
    save()
}
```

**Haptic Feedbackの使い分け：**
- `success`: 操作が成功したとき
- `error`: エラーが発生したとき
- `warning`: 注意が必要なとき
- `selection`: 選択肢を変更したとき
- `lightImpact`: ボタンをタップしたとき

---

## 実際の使用例

### 日記作成画面での使用例

```swift
struct DiaryCreationView: View {
    @State private var text = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    func saveDiary() {
        // バリデーション
        guard Validator.isValidDiaryText(text) else {
            HapticFeedback.error()
            alertMessage = "日記の内容を入力してください（1〜10,000文字）"
            showingAlert = true
            return
        }

        guard Validator.isValidImageData(photoData) else {
            HapticFeedback.error()
            alertMessage = "画像データが無効です"
            showingAlert = true
            return
        }

        // 保存処理
        do {
            let entry = DiaryEntry(
                text: text,
                photoData: photoData,
                moodScores: moodScores
            )
            var entries = try dataPersistence.load()
            entries.append(entry)
            try dataPersistence.save(entries: entries)

            HapticFeedback.success()
            alertMessage = "保存しました"
            showingAlert = true
        } catch {
            HapticFeedback.error()
            alertMessage = "保存に失敗しました"
            showingAlert = true
        }
    }

    var body: some View {
        VStack {
            TextEditor(text: $text)
                .cornerRadius(Constants.defaultCornerRadius)

            Button("保存") {
                HapticFeedback.lightImpact()
                saveDiary()
            }
            .cornerRadius(Constants.defaultCornerRadius)
        }
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("OK") { }
        }
    }
}
```

### 統計画面での使用例

```swift
struct StatisticsView: View {
    @State private var entries: [DiaryEntry] = []
    @State private var selectedPeriod: Period = .week

    var filteredEntries: [DiaryEntry] {
        let start: Date
        switch selectedPeriod {
        case .week:
            start = DateHelper.startOfWeek
        case .month:
            start = DateHelper.startOfMonth
        case .all:
            return entries
        }
        return entries.filtered(from: start, to: Date())
    }

    var moodDistribution: [Mood: Int] {
        var distribution: [Mood: Int] = [:]
        for entry in filteredEntries {
            if let mood = entry.primaryMood {
                distribution[mood, default: 0] += 1
            }
        }
        return distribution
    }

    var body: some View {
        VStack {
            Picker("期間", selection: $selectedPeriod) {
                Text("今週").tag(Period.week)
                Text("今月").tag(Period.month)
                Text("全期間").tag(Period.all)
            }
            .onChange(of: selectedPeriod) { _ in
                HapticFeedback.selection()
            }

            List(Mood.allCases, id: \.self) { mood in
                HStack {
                    Text(mood.emoji)
                    Text(mood.rawValue)
                    Spacer()
                    Text("\(moodDistribution[mood] ?? 0)件")
                }
                .padding()
                .background(Color.color(for: mood).opacity(0.2))
                .cornerRadius(Constants.defaultCornerRadius)
            }
        }
    }
}
```

### カレンダー表示の使用例

```swift
struct CalendarView: View {
    @State private var entries: [DiaryEntry] = []

    var entriesByDate: [Date: [DiaryEntry]] {
        entries.groupedByDate()
    }

    var body: some View {
        ScrollView {
            ForEach(DateHelper.dateRange(from: DateHelper.startOfMonth, to: Date()), id: \.self) { date in
                VStack(alignment: .leading) {
                    Text(date.formatted(as: "MM/dd（E）"))
                        .font(.headline)

                    if let dayEntries = entriesByDate[date.startOfDay] {
                        ForEach(dayEntries) { entry in
                            HStack {
                                if let mood = entry.primaryMood {
                                    Text(mood.emoji)
                                        .font(.largeTitle)
                                }
                                Text(entry.text.truncated(to: 50))
                                    .lineLimit(2)
                            }
                            .padding()
                            .background(
                                entry.primaryMood.map { Color.color(for: $0).opacity(0.2) } ?? Color.gray.opacity(0.2)
                            )
                            .cornerRadius(Constants.defaultCornerRadius)
                        }
                    } else {
                        Text("日記なし")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            }
        }
    }
}
```

---

## よくある質問

### Q1: Extensionで保存プロパティを追加できないのはなぜですか？
**A**: Swiftの設計上の制限です。

```swift
// これはエラー
extension Date {
    var cachedString: String = ""  // Error!
}

// 代わりに算出プロパティを使う
extension Date {
    var formattedString: String {
        formatted(as: "yyyy/MM/dd")
    }
}
```

保存プロパティが必要な場合は、ラッパークラスを作成します。

### Q2: enumをネームスペースとして使う理由は？
**A**: インスタンス化を防ぎ、静的メソッドをグループ化するためです。

```swift
// enumの場合
enum ImageHelper {
    static func resize(...) { }
}
let helper = ImageHelper()  // Error: Cannot instantiate

// structの場合
struct ImageHelper {
    private init() {}  // インスタンス化を防ぐために必要
    static func resize(...) { }
}
```

enumの方がシンプルで意図が明確です。

### Q3: Constantsファイルが大きくなりすぎた場合は？
**A**: カテゴリごとにファイルを分割します。

```swift
// Constants+UI.swift
extension Constants {
    enum UI {
        static let cornerRadius: CGFloat = 10
        static let animationDuration: Double = 0.3
    }
}

// Constants+API.swift
extension Constants {
    enum API {
        static let baseURL = "https://api.example.com"
        static let timeout: TimeInterval = 30
    }
}

// 使用
let radius = Constants.UI.cornerRadius
```

### Q4: Haptic Feedbackを使いすぎると問題ですか？
**A**: はい、ユーザー体験を損なう可能性があります。

**良い使い方：**
- 重要な操作の完了時（保存、削除など）
- エラーや警告
- 選択肢の変更

**悪い使い方：**
- スクロール中
- アニメーション中
- 頻繁に発生するイベント

**ガイドライン：**
1秒間に1回以下が目安です。

### Q5: String.truncated()とlineLimit()の違いは？
**A**:
- `truncated()`: 文字数でカット（String拡張）
- `lineLimit()`: 行数でカット（SwiftUIのView modifier）

```swift
// truncated()
let text = "とても長いテキストです。"
let short = text.truncated(to: 10)  // "とても長いテキ..."

// lineLimit()
Text("とても長いテキストです。")
    .lineLimit(2)  // 2行まで表示、それ以降は省略
```

### Q6: DateHelperとDate Extensionの使い分けは？
**A**:
- **Date Extension**: Dateインスタンスのメソッド（例: `date.startOfDay`）
- **DateHelper**: 静的な日付取得（例: `DateHelper.today`）

```swift
// Date Extension
let date = Date()
let start = date.startOfDay

// DateHelper
let today = DateHelper.today
let yesterday = DateHelper.yesterday
```

### Q7: 定数の命名規則は？
**A**: Swiftでは`lowerCamelCase`が一般的です。

```swift
// Good
static let minimumFaceMatchConfidence: Double = 0.7
static let defaultCornerRadius: CGFloat = 10

// Bad（Objective-Cスタイル）
static let MINIMUM_FACE_MATCH_CONFIDENCE: Double = 0.7
static let DEFAULT_CORNER_RADIUS: CGFloat = 10
```

### Q8: Validatorを使わずに直接チェックしても良いですか？
**A**: 可能ですが、Validatorを使う方が保守性が高いです。

```swift
// 直接チェック（悪い例）
if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || text.count > 10000 {
    // エラー
}

// Validator使用（良い例）
if !Validator.isValidDiaryText(text) {
    // エラー
}
```

Validatorを使うと：
- バリデーションロジックが一箇所に集約
- 変更が容易（条件を変える場合、1箇所だけ修正）
- テストが書きやすい

---

## まとめ

`core/utilities` ディレクトリは、FaceDiaryアプリの「道具箱」です：

1. **Constants**: 定数管理でマジックナンバーを排除
2. **Extensions**: 既存の型に便利な機能を追加
3. **Helpers**: 特定の処理をカプセル化した便利関数

これらのユーティリティを活用することで：
- コードの重複を避ける
- 一貫性を保つ
- 保守性を高める
- 可読性を向上させる

---

## 参考リンク
- [Apple公式: Swift Extensions](https://docs.swift.org/swift-book/LanguageGuide/Extensions.html)
- [Apple公式: UIFeedbackGenerator](https://developer.apple.com/documentation/uikit/uifeedbackgenerator)
- [Swift Style Guide](https://google.github.io/swift/)
- [Swift by Sundell: Extensions](https://www.swiftbysundell.com/basics/extensions/)
