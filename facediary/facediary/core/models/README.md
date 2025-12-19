# Core Models

## 目次
1. [Overview（概要）](#overview)
2. [Swiftの基礎知識](#swiftの基礎知識)
3. [ファイル構成](#ファイル構成)
4. [詳細解説](#詳細解説)
5. [モデル間の関係](#モデル間の関係)
6. [実際の使用例](#実際の使用例)
7. [よくある質問](#よくある質問)

---

## Overview
アプリケーション全体で使用されるデータモデルを定義するディレクトリです。
これらのモデルは、`Codable` に準拠しており、JSON形式での保存や読み込みに対応しています。

データモデルは、アプリが扱う「データの形」を定義する設計図のようなものです。
例えば、日記エントリーには何が含まれるか（日付、テキスト、写真など）を定義します。

---

## Swiftの基礎知識

### struct（構造体）とは
`struct` は、関連するデータをまとめて1つの型として定義するための仕組みです。

```swift
struct Person {
    var name: String
    var age: Int
}

let person = Person(name: "太郎", age: 25)
print(person.name) // "太郎"
```

**structの特徴：**
- **値型（Value Type）**: コピーされると完全に別のインスタンスになります
- **イミュータブル**: `let` で定義すると、プロパティを変更できません
- **軽量**: メモリ効率が良く、高速

**classとの違い：**
| 特徴 | struct（値型） | class（参照型） |
|------|---------------|----------------|
| コピー | 値がコピーされる | 参照（ポインタ）がコピーされる |
| 継承 | できない | できる |
| 変更追跡 | 簡単 | 複雑 |
| 用途 | データモデル | 複雑なオブジェクト |

**Swiftのベストプラクティス：**
データモデルには `struct` を使うことが推奨されます。なぜなら：
- 予期しない変更を防げる
- スレッドセーフ（並行処理でも安全）
- Swiftの標準ライブラリもstructを多用している

### protocol（プロトコル）とは
`protocol` は、型が実装すべきメソッドやプロパティを定義する「契約書」のようなものです。

```swift
protocol Drawable {
    func draw()
}

struct Circle: Drawable {
    func draw() {
        print("円を描く")
    }
}
```

このディレクトリでは、`Identifiable`、`Codable`、`CaseIterable` などのプロトコルを使用しています。

### enum（列挙型）とは
`enum` は、関連する値のグループを定義するための型です。

```swift
enum Direction {
    case north
    case south
    case east
    case west
}

let heading = Direction.north
```

**enumの利点：**
- タイプセーフ（存在しない値を防げる）
- switch文で全ケースを網羅しているかチェックできる
- 関連する値をグループ化できる

### Codableプロトコル
`Codable` は、データを簡単にJSON形式に変換したり、JSON形式からデータを復元したりするためのプロトコルです。

`Codable` は実際には、`Encodable`（エンコード可能）と `Decodable`（デコード可能）の2つのプロトコルを組み合わせたものです。

```swift
struct Person: Codable {
    var name: String
    var age: Int
}

// JSON形式に変換（エンコード）
let person = Person(name: "太郎", age: 25)
let jsonData = try JSONEncoder().encode(person)
// {"name":"太郎","age":25}

// JSON形式から復元（デコード）
let decodedPerson = try JSONDecoder().decode(Person.self, from: jsonData)
```

**Codableの利点：**
- データの永続化（保存）が簡単
- ネットワーク通信でのデータ送受信が簡単
- 自動的にシリアライズ・デシリアライズを行ってくれる

### Identifiableプロトコル
`Identifiable` は、オブジェクトが一意のID（識別子）を持つことを保証するプロトコルです。

```swift
struct DiaryEntry: Identifiable {
    let id: UUID  // Identifiableプロトコルで要求される
    var text: String
}
```

SwiftUIの `List` や `ForEach` で使用する際に、各要素を一意に識別するために使われます。

```swift
List(diaryEntries) { entry in
    Text(entry.text)
}
// idプロパティがあるため、各エントリーを一意に識別できる
```

### UUIDとは
UUID（Universally Unique Identifier）は、世界中で一意な識別子を生成する仕組みです。

```swift
let id1 = UUID() // 例: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"
let id2 = UUID() // 例: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
// id1とid2は絶対に同じ値にならない
```

**UUIDの特徴：**
- ランダムに生成される
- 重複の可能性が極めて低い（実質的にゼロ）
- データベースの主キーとして最適

### Dataとは
`Data` 型は、バイナリデータ（0と1の並び）を表すSwiftの標準型です。

```swift
let text = "こんにちは"
let data = text.data(using: .utf8)!
// textをバイトの配列に変換

let image = UIImage(named: "photo")
let imageData = image?.jpegData(compressionQuality: 0.8)
// 画像をJPEG形式のバイトデータに変換
```

**Dataの用途：**
- 画像、音声、動画などのバイナリファイル
- ネットワーク通信でのデータ送受信
- ファイルの読み書き

### 算出プロパティ（Computed Property）とは
算出プロパティは、値を保存せず、必要なときに計算して返すプロパティです。

```swift
struct Rectangle {
    var width: Double
    var height: Double

    // 算出プロパティ
    var area: Double {
        return width * height
    }
}

let rect = Rectangle(width: 10, height: 5)
print(rect.area) // 50（毎回計算される）
```

**通常のプロパティとの違い：**
| 特徴 | 通常のプロパティ | 算出プロパティ |
|------|----------------|---------------|
| 値の保存 | メモリに保存される | 保存されず、毎回計算 |
| 定義 | `var name: String` | `var area: Double { ... }` |
| パフォーマンス | 高速（既に保存済み） | 計算が必要 |
| メモリ | 使う | 使わない |

**算出プロパティを使う理由：**
- データの一貫性を保つ（widthやheightが変わると、areaも自動的に変わる）
- メモリの節約（保存する必要がない値は保存しない）
- コードの読みやすさ（`rect.area` と書くだけで面積が得られる）

---

## ファイル構成

```
core/models/
├── DiaryEntry.swift    # 日記エントリーのデータモデル
├── Mood.swift          # 感情の種類を表す列挙型
└── FaceData.swift      # 顔認証データのモデル
```

---

## 詳細解説

### 1. DiaryEntry.swift
**ファイルパス**: `facediary/facediary/core/models/DiaryEntry.swift`

#### 役割
日記の1エントリー（1つの記録）を表すデータモデルです。
日記のテキスト、撮影した写真、感情分析の結果などを保持します。

#### コードの詳細解説

```swift
import Foundation
```
- Foundationフレームワークをインポートしています
- `UUID`、`Date`、`Data` などの基本的な型を使うために必要

```swift
struct DiaryEntry: Identifiable, Codable {
```
- `DiaryEntry` という名前の構造体を定義
- `Identifiable`: この構造体が一意のIDを持つことを保証（SwiftUIのListなどで使用）
- `Codable`: JSON形式への変換・復元が可能

#### プロパティの詳細

```swift
let id: UUID
```
- **型**: UUID（一意識別子）
- **用途**: 各日記エントリーを一意に識別するためのID
- **不変（let）**: 一度作成されたら変更されない
- **Identifiableプロトコルの要件**: このプロパティがあることで、SwiftUIが各エントリーを区別できる

**なぜUUIDを使うのか？**
```swift
let entry1 = DiaryEntry(...)  // id: "A1B2C3D4-..."
let entry2 = DiaryEntry(...)  // id: "E5F6G7H8-..."
// 絶対に重複しないため、データベースや配列で確実に識別できる
```

```swift
var date: Date
```
- **型**: Date（日付と時刻）
- **用途**: 日記エントリーが作成された日時
- **可変（var）**: 後で変更可能
- **例**: `2025-10-30 14:30:00`

```swift
var text: String
```
- **型**: String（文字列）
- **用途**: 日記の本文（ユーザーが入力したテキスト）
- **例**: "今日はとても楽しい一日でした。"

```swift
var photoData: Data?
```
- **型**: Data?（オプショナル型のData）
- **用途**: 撮影した写真をバイナリデータとして保存
- **オプショナル（?）**: 写真がない場合は `nil` になる
- **なぜData型なのか？**: 画像をそのままメモリに保存すると重いため、バイト列として保存

**Data型の扱い方：**
```swift
// 画像をDataに変換
let image = UIImage(named: "photo")
let photoData = image?.jpegData(compressionQuality: 0.8)

// Dataを画像に変換
if let data = entry.photoData {
    let image = UIImage(data: data)
}
```

```swift
var moodScores: [Mood: Double]
```
- **型**: Dictionary（辞書）、キーが `Mood` 型、値が `Double` 型
- **用途**: 感情分析の結果を保存（各感情とそのスコアの組み合わせ）
- **例**:
  ```swift
  [
      .happiness: 0.8,  // 80%の確率で喜び
      .surprise: 0.15,  // 15%の確率で驚き
      .neutral: 0.05    // 5%の確率で普通
  ]
  ```

**辞書（Dictionary）とは？**
キーと値のペアを格納するデータ構造です。
```swift
var scores = [Mood: Double]()
scores[.happiness] = 0.8  // キー: .happiness、値: 0.8
scores[.sadness] = 0.2    // キー: .sadness、値: 0.2

print(scores[.happiness])  // Optional(0.8)
```

#### 算出プロパティ

```swift
var primaryMood: Mood? {
    moodScores.max(by: { $0.value < $1.value })?.key
}
```
- **型**: Mood?（オプショナル型のMood）
- **用途**: 最もスコアが高い感情を返す
- **算出プロパティ**: 値を保存せず、毎回計算して返す

**詳細解説：**
```swift
// 例: moodScores = [.happiness: 0.8, .surprise: 0.15, .neutral: 0.05]

moodScores.max(by: { $0.value < $1.value })
// maxメソッド: 辞書の中で最大の要素を見つける
// by: { $0.value < $1.value } - 値（スコア）を比較する
// 結果: (.happiness, 0.8) のタプル

?.key
// オプショナルチェイニング: nilでない場合のみkeyを取得
// 結果: .happiness
```

**なぜオプショナル（?）なのか？**
`moodScores` が空の場合、`max` は `nil` を返すため、`primaryMood` も `nil` になります。

#### イニシャライザ（初期化メソッド）

```swift
init(id: UUID = UUID(), date: Date = Date(), text: String, photoData: Data?, moodScores: [Mood: Double]) {
    self.id = id
    self.date = date
    self.text = text
    self.photoData = photoData
    self.moodScores = moodScores
}
```

**パラメータの解説：**
- `id: UUID = UUID()`: デフォルト値あり。指定しなければ自動生成
- `date: Date = Date()`: デフォルト値あり。指定しなければ現在日時
- `text: String`: デフォルト値なし。必須パラメータ
- `photoData: Data?`: オプショナル。nilも可
- `moodScores: [Mood: Double]`: 必須パラメータ

**使用例：**
```swift
// 最小限のパラメータで作成
let entry1 = DiaryEntry(
    text: "今日は楽しかった",
    photoData: nil,
    moodScores: [.happiness: 1.0]
)
// idとdateは自動生成される

// 全てのパラメータを指定
let entry2 = DiaryEntry(
    id: UUID(),
    date: Date(),
    text: "今日は楽しかった",
    photoData: imageData,
    moodScores: [.happiness: 0.8, .surprise: 0.2]
)
```

#### Codableの実装

```swift
enum CodingKeys: String, CodingKey {
    case id
    case date
    case text
    case photoData
    case moodScores
}
```

**CodingKeysとは？**
- JSON形式に変換するときのキー名を定義します
- ここでは、プロパティ名とJSON のキー名が同じなので、明示的に定義しています

**なぜ明示的に定義するのか？**
- 将来的にJSONのキー名を変更したい場合に対応しやすくする
- 例: `case id = "diary_id"` とすれば、JSONでは "diary_id" というキー名になる

```swift
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    date = try container.decode(Date.self, forKey: .date)
    text = try container.decode(String.self, forKey: .text)
    photoData = try container.decodeIfPresent(Data.self, forKey: .photoData)
    moodScores = try container.decode([Mood: Double].self, forKey: .moodScores)
}
```

**デコード処理の詳細：**
1. `decoder.container(keyedBy: CodingKeys.self)`: JSONデータのコンテナを取得
2. `container.decode(型.self, forKey: .キー)`: 指定したキーの値を取得してデコード
3. `container.decodeIfPresent(型.self, forKey: .キー)`: オプショナル型の値をデコード（nilも許可）
4. `throws`: エラーが発生する可能性があることを示す

**実際の動作：**
```swift
// JSON文字列
let json = """
{
  "id": "A1B2C3D4-...",
  "date": "2025-10-30T14:30:00Z",
  "text": "今日は楽しかった",
  "photoData": null,
  "moodScores": {
    "喜び": 0.8,
    "驚き": 0.2
  }
}
"""

// DiaryEntryオブジェクトに変換
let decoder = JSONDecoder()
let entry = try decoder.decode(DiaryEntry.self, from: json.data(using: .utf8)!)
```

```swift
func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(date, forKey: .date)
    try container.encode(text, forKey: .text)
    try container.encode(photoData, forKey: .photoData)
    try container.encode(moodScores, forKey: .moodScores)
}
```

**エンコード処理の詳細：**
1. `encoder.container(keyedBy: CodingKeys.self)`: エンコード用のコンテナを作成
2. `container.encode(値, forKey: .キー)`: 値をエンコードして指定したキーで保存

**実際の動作：**
```swift
let entry = DiaryEntry(
    text: "今日は楽しかった",
    photoData: nil,
    moodScores: [.happiness: 0.8]
)

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let jsonData = try encoder.encode(entry)
print(String(data: jsonData, encoding: .utf8)!)
// 上記のJSON文字列が出力される
```

---

### 2. Mood.swift
**ファイルパス**: `facediary/facediary/core/models/Mood.swift`

#### 役割
ユーザーの感情や気分を表す列挙型です。
顔認識や感情分析の結果を、定義された感情のカテゴリーに分類します。

#### コードの詳細解説

```swift
import Foundation
```
- Foundationフレームワークをインポート

```swift
public enum Mood: String, CaseIterable, Codable {
```
- `public`: 他のモジュールからもアクセス可能
- `enum`: 列挙型として定義
- `String`: 各caseの生の値（rawValue）が文字列
- `CaseIterable`: 全てのcaseを配列として取得できる
- `Codable`: JSON形式への変換・復元が可能

#### 各caseの詳細

```swift
case happiness = "喜び"
case sadness = "悲しみ"
case anger = "怒り"
case surprise = "驚き"
case calm = "穏やか"
case neutral = "普通"
```

**生の値（rawValue）とは？**
各caseに関連付けられた値です。
```swift
let mood = Mood.happiness
print(mood.rawValue)  // "喜び"

// 逆に、生の値からenumを作成
let mood2 = Mood(rawValue: "悲しみ")  // Mood.sadness
```

**なぜString型なのか？**
- UI表示で使いやすい
- デバッグがしやすい
- JSONに保存するときに人間が読める形式になる

**CaseIterableの使い方：**
```swift
// 全てのcaseを配列として取得
let allMoods = Mood.allCases
// [.happiness, .sadness, .anger, .surprise, .calm, .neutral]

// ループで全てを処理
for mood in Mood.allCases {
    print(mood.emoji)
}
// 😄😢😠😮😌😐
```

#### emojiプロパティ

```swift
public var emoji: String {
    switch self {
    case .happiness:
        return "😄"
    case .sadness:
        return "😢"
    case .anger:
        return "😠"
    case .surprise:
        return "😮"
    case .calm:
        return "😌"
    case .neutral:
        return "😐"
    }
}
```

**詳細解説：**
- 算出プロパティ（値を保存せず、毎回計算して返す）
- `self`: 現在のenumのcase（例: `.happiness`）
- `switch`: 全てのcaseに対応する必要がある（網羅性チェック）

**使用例：**
```swift
let mood = Mood.happiness
print(mood.emoji)  // "😄"

// UIに表示
Text(mood.emoji)
```

**なぜemojiを別プロパティにしているのか？**
- rawValueと分離することで、柔軟性が高まる
- 将来的に絵文字を変更しても、他のコードに影響がない
- 複数の表現方法を持てる（emoji、rawValue、英語名など）

---

### 3. FaceData.swift
**ファイルパス**: `facediary/facediary/core/models/FaceData.swift`

#### 役割
顔認証に使用される参照データを保持する構造体です。
ユーザーの顔の特徴点データを保存し、認証時に比較します。

#### コードの詳細解説

```swift
import Foundation
```
- Foundationフレームワークをインポート

```swift
struct FaceData: Codable {
```
- `FaceData` という名前の構造体を定義
- `Codable`: JSON形式への変換・復元が可能
- **注意**: `Identifiable` は実装していない（複数の顔データを持つ想定ではないため）

#### プロパティの詳細

```swift
var userID: UUID
```
- **型**: UUID（一意識別子）
- **用途**: ユーザーを一意に識別するためのID
- **例**: 将来的に複数ユーザーをサポートする場合に使用

```swift
var faceObservations: Data
```
- **型**: Data（バイナリデータ）
- **用途**: Vision Frameworkから抽出された顔の特徴点データを保存
- **内容**: VNFaceObservationオブジェクトをシリアライズしたデータ

**Vision Frameworkとは？**
AppleのAIフレームワークで、画像から顔を検出し、特徴点を抽出できます。
```swift
import Vision

// 顔の検出と特徴点抽出
let request = VNDetectFaceRectanglesRequest { request, error in
    guard let observations = request.results as? [VNFaceObservation] else { return }
    // observationsに顔の特徴点が含まれる
}
```

**なぜData型なのか？**
`VNFaceObservation` はそのままKeychainに保存できないため、`Data` 型に変換する必要があります。

```swift
var createdAt: Date
```
- **型**: Date（日付と時刻）
- **用途**: 顔データが登録された日時
- **例**: `2025-10-30 14:30:00`

**なぜ登録日時が必要なのか？**
- セキュリティ監査（いつ登録されたかを記録）
- 古いデータの更新判断
- デバッグやトラブルシューティング

#### このファイルの重要性
顔認証のセキュリティの核心部分です。
このデータがKeychainに安全に保存されることで、ユーザーのプライバシーが保護されます。

---

## モデル間の関係

### データフロー図

```
ユーザー
   ↓ 顔を登録
FaceData (Keychain に保存)
   ├─ userID: UUID
   ├─ faceObservations: Data
   └─ createdAt: Date
   ↓ 認証成功
日記を作成
   ↓
DiaryEntry (ファイルシステムに保存)
   ├─ id: UUID
   ├─ date: Date
   ├─ text: String
   ├─ photoData: Data?
   ├─ moodScores: [Mood: Double] ←─── Mood enum
   │     ├─ .happiness: 0.8
   │     ├─ .surprise: 0.15
   │     └─ .neutral: 0.05
   └─ primaryMood: Mood? (算出) ───→ .happiness
         ↓
      UI表示: "😄"
```

### 関連性の説明

1. **FaceData と DiaryEntry の関係**
   - FaceDataは認証に使用され、認証成功後にDiaryEntryを作成できる
   - 直接的な関連はないが、アプリのフローで繋がっている

2. **Mood と DiaryEntry の関係**
   - DiaryEntryは、MoodをキーとするDictionaryを持つ
   - DiaryEntryのprimaryMoodは、Mood型
   - Mood enumがなければ、DiaryEntryは機能しない（強い依存関係）

3. **データの永続化**
   - **FaceData**: Keychainに保存（セキュアな保存領域）
   - **DiaryEntry**: ファイルシステムまたはCore Dataに保存
   - **Mood**: 保存されない（列挙型の定義のみ）

---

## 実際の使用例

### DiaryEntryの作成と保存

```swift
// 1. 日記エントリーを作成
let entry = DiaryEntry(
    text: "今日は友達とカフェに行った。とても楽しかった！",
    photoData: capturedPhotoData,
    moodScores: [
        .happiness: 0.85,
        .surprise: 0.10,
        .neutral: 0.05
    ]
)

// 2. 主要な感情を取得
if let primaryMood = entry.primaryMood {
    print("主な感情: \(primaryMood.rawValue) \(primaryMood.emoji)")
    // "主な感情: 喜び 😄"
}

// 3. JSON形式に変換して保存
let encoder = JSONEncoder()
let jsonData = try encoder.encode(entry)
try jsonData.write(to: fileURL)

// 4. JSON形式から復元
let loadedData = try Data(contentsOf: fileURL)
let decoder = JSONDecoder()
let loadedEntry = try decoder.decode(DiaryEntry.self, from: loadedData)
```

### Moodの使用

```swift
// 全ての感情を表示
ForEach(Mood.allCases, id: \.self) { mood in
    HStack {
        Text(mood.emoji)
        Text(mood.rawValue)
    }
}
// 😄 喜び
// 😢 悲しみ
// 😠 怒り
// 😮 驚き
// 😌 穏やか
// 😐 普通

// 感情スコアの可視化
ForEach(entry.moodScores.sorted(by: { $0.value > $1.value }), id: \.key) { mood, score in
    HStack {
        Text(mood.emoji)
        ProgressView(value: score)
        Text("\(Int(score * 100))%")
    }
}
```

### FaceDataの作成と保存

```swift
// 1. Vision Frameworkで顔の特徴を抽出
let faceObservation: VNFaceObservation = ... // Vision APIから取得

// 2. FaceDataを作成
let faceData = FaceData(
    userID: UUID(),
    faceObservations: try NSKeyedArchiver.archivedData(
        withRootObject: faceObservation,
        requiringSecureCoding: true
    ),
    createdAt: Date()
)

// 3. Keychainに保存（SecurityServiceを使用）
try securityService.saveFaceData(faceData)

// 4. Keychainから読み込み
if let loadedFaceData = try securityService.loadFaceData() {
    print("顔データが登録されています: \(loadedFaceData.createdAt)")
}
```

---

## よくある質問

### Q1: なぜクラスではなく構造体（struct）を使うのですか？
**A**: データモデルにはstructを使うのがSwiftのベストプラクティスです。
- **値型**: コピーされると完全に別のインスタンスになるため、予期しない変更を防げる
- **スレッドセーフ**: 並行処理でも安全
- **軽量**: メモリ効率が良い
- **Swiftの標準**: String、Array、Dictionaryなども全てstruct

### Q2: Codableはどうやって動いているのですか？
**A**: Swiftコンパイラが自動的にエンコード・デコードコードを生成します。
```swift
struct Person: Codable {
    var name: String
    var age: Int
}
// コンパイラが自動的にencode/decodeメソッドを生成
```

ただし、カスタマイズが必要な場合（例: キー名を変更、特殊な変換）は、
`CodingKeys` や `init(from:)`、`encode(to:)` を自分で実装します。

### Q3: オプショナル型（?）はいつ使うのですか？
**A**: 値が存在しない可能性がある場合に使います。
```swift
var photoData: Data?  // 写真がない場合はnil
var primaryMood: Mood?  // moodScoresが空の場合はnil
```

**オプショナルを使わないとどうなる？**
```swift
var photoData: Data  // 常に値が必要
// 写真がない場合でも、何かしらのData値を入れなければならない
// これは不自然で、バグの原因になる
```

### Q4: 算出プロパティと通常のプロパティの使い分けは？
**A**:
- **通常のプロパティ**: 値を保存する必要がある場合
  ```swift
  var text: String  // 日記の本文は保存が必要
  ```
- **算出プロパティ**: 他のプロパティから計算できる場合
  ```swift
  var primaryMood: Mood? {
      // moodScoresから毎回計算
  }
  ```

算出プロパティのメリット：
- データの一貫性が保たれる（元データが変わると、自動的に結果も変わる）
- メモリの節約（保存しないため）
- Codableで自動的にエンコード・デコードから除外される

### Q5: enumにメソッドを追加できますか？
**A**: はい、できます！
```swift
enum Mood: String, CaseIterable, Codable {
    case happiness = "喜び"
    case sadness = "悲しみ"

    var emoji: String {
        // 算出プロパティ
    }

    func description() -> String {
        return "\(emoji) \(rawValue)"
    }

    func opposite() -> Mood {
        switch self {
        case .happiness: return .sadness
        case .sadness: return .happiness
        default: return .neutral
        }
    }
}

let mood = Mood.happiness
print(mood.description())  // "😄 喜び"
print(mood.opposite())     // Mood.sadness
```

### Q6: Dictionaryのキーに独自の型を使えるのはなぜですか？
**A**: `Mood` enumが `Hashable` プロトコルに準拠しているためです。
```swift
var moodScores: [Mood: Double]
// MoodはHashableなので、Dictionaryのキーとして使える
```

`String` や `Int` などの基本型は自動的に `Hashable` です。
独自の型も、適切に実装すれば `Hashable` にできます。

**Hashableとは？**
値をハッシュ値（数値）に変換できることを保証するプロトコルです。
DictionaryやSetのキーとして使うために必要です。

### Q7: JSONに保存するときの日付形式は？
**A**: `Date` 型は、デフォルトで「1970年1月1日からの秒数」として保存されます。
```swift
let date = Date()
// JSON: 1730284800.0
```

人間が読める形式にしたい場合は、DateFormatterを使います。
```swift
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
// JSON: "2025-10-30T14:30:00Z"
```

### Q8: photoDataはどのくらいのサイズですか？
**A**: 画像の解像度と圧縮率によりますが、一般的に：
- 圧縮なし: 数MB〜数十MB
- JPEG圧縮（0.8品質）: 数百KB〜数MB

```swift
// 圧縮して保存
let photoData = image.jpegData(compressionQuality: 0.8)
// compressionQuality: 0.0（最低品質）〜 1.0（最高品質）
```

---

## まとめ

`core/models` ディレクトリは、FaceDiaryアプリの「データの設計図」です：

1. **DiaryEntry**: 日記の内容を保持する中心的なモデル
2. **Mood**: 感情の種類を定義し、DiaryEntryで使用される
3. **FaceData**: 顔認証データを安全に保存するためのモデル

これらのモデルは、`Codable` により簡単に保存・読み込みができ、
`struct` を使用することで安全性とパフォーマンスを両立しています。

---

## 参考リンク
- [Apple公式: Swift Programming Language](https://docs.swift.org/swift-book/)
- [Apple公式: Encoding and Decoding Custom Types](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types)
- [Apple公式: Vision Framework](https://developer.apple.com/documentation/vision)
- [Swift by Sundell: Codable](https://www.swiftbysundell.com/basics/codable/)
