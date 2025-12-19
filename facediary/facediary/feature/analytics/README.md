# Analytics Feature - 統計分析機能

## 目次
1. [概要](#概要)
2. [SwiftUIの基礎知識](#swiftuiの基礎知識)
3. [ファイル構成](#ファイル構成)
4. [詳細解説](#詳細解説)
5. [連携・関係性](#連携関係性)
6. [実際の使用例](#実際の使用例)
7. [よくある質問](#よくある質問)
8. [まとめ](#まとめ)
9. [参考リンク](#参考リンク)

---

## 概要

**Analytics Feature**は、ユーザーが記録した日記データを分析し、感情の傾向や統計情報を視覚化する機能です。期間（週、月、年）ごとのフィルタリングや、感情分布のグラフ表示を提供します。

### 主な機能
- **総合統計の表示**: 総エントリー数、1日あたりの平均エントリー数、最も頻繁な感情を表示
- **感情分布の可視化**: 各感情の割合をバーチャートで表示
- **感情トレンドの表示**: カレンダー形式で日ごとの感情推移を表示
- **期間フィルタ**: 週、月、年単位での統計表示

### このFeatureの重要性
- ユーザーが自分の感情パターンを理解できる
- 長期的な気分の変化を可視化する
- データドリブンな自己理解をサポートする

---

## SwiftUIの基礎知識

### 1. @StateObject vs @ObservedObject
```swift
@StateObject private var viewModel = AnalyticsViewModel()
```
- **@StateObject**: Viewがオブジェクトの「オーナー」になる（Viewのライフサイクル全体で保持される）
- **@ObservedObject**: 外部から渡されたオブジェクトを監視する
- ここでは`AnalyticsView`が`AnalyticsViewModel`を**作成して所有**するため`@StateObject`を使用

### 2. ScrollViewとVStack
```swift
ScrollView {
    VStack(spacing: 24) {
        // コンテンツ
    }
}
```
- **ScrollView**: コンテンツがスクリーンに収まらない場合にスクロール可能にする
- **VStack**: 縦方向にビューを並べるレイアウトコンテナ
- `spacing: 24`でビュー間の間隔を指定

### 3. プログレスビュー（ローディング表示）
```swift
if viewModel.isLoading {
    ProgressView("Loading...")
}
```
- データ読み込み中にインジケータを表示
- ユーザーに処理中であることを視覚的に伝える

### 4. GeometryReader（動的レイアウト）
```swift
GeometryReader { geometry in
    RoundedRectangle(cornerRadius: 4)
        .frame(width: geometry.size.width * CGFloat(count) / CGFloat(total))
}
```
- **GeometryReader**: 親ビューのサイズを取得してレイアウトを動的に調整
- プログレスバーの幅を割合に応じて計算

### 5. LazyVGrid（グリッドレイアウト）
```swift
LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 8) {
    ForEach(sortedTrend, id: \.key) { date, mood in
        // カレンダー風のグリッド表示
    }
}
```
- **LazyVGrid**: 列を自動調整するグリッドレイアウト
- `.adaptive(minimum: 40)`: 最小幅40で可能な限り多くの列を表示

### 6. DispatchQueue（非同期処理）
```swift
DispatchQueue.global(qos: .userInitiated).async {
    // バックグラウンドで重い処理
    DispatchQueue.main.async {
        // UI更新はメインスレッドで
    }
}
```
- **QoS (Quality of Service)**: タスクの優先度を指定
- `.userInitiated`: ユーザーが開始した処理（高優先度）

---

## ファイル構成

```
feature/analytics/
├── view/
│   └── AnalyticsView.swift          # 統計画面のUI
├── viewmodels/
│   └── AnalyticsViewModel.swift     # 統計画面のビジネスロジック
└── README.md                         # このドキュメント
```

### 依存関係図
```
AnalyticsView
    ↓ @StateObject
AnalyticsViewModel
    ↓ 依存
    ├── AnalyticsService (統計計算)
    └── DataPersistenceService (データ読み込み)
```

---

## 詳細解説

### 1. AnalyticsView.swift

#### 役割
統計情報を表示するダッシュボード画面。ユーザーに感情の傾向を視覚的に伝える。

#### コード解説

##### (1) 基本構造
```swift
struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                // コンテンツ
            }
            .navigationTitle("Analytics")
        }
    }
}
```
**意味**:
- `@StateObject`: ViewModelを作成して所有
- `NavigationStack`: ナビゲーションバーを提供
- `ScrollView`: コンテンツをスクロール可能にする

##### (2) ローディング状態の分岐
```swift
if viewModel.isLoading {
    ProgressView("Loading...")
} else if let statistics = viewModel.statistics {
    VStack(spacing: 24) {
        overallStatisticsView(statistics: statistics)
        // その他のビュー
    }
} else {
    emptyStateView
}
```
**意味**:
- ローディング中: `ProgressView`を表示
- データあり: 統計ビューを表示
- データなし: Empty State（空状態）を表示

##### (3) 総合統計カード
```swift
private func overallStatisticsView(statistics: MoodStatistics) -> some View {
    HStack(spacing: 20) {
        statCard(title: "Total Entries", value: "\(statistics.totalEntries)", icon: "book.fill")
        statCard(title: "Avg. Entries/Day", value: String(format: "%.1f", statistics.averageEntriesPerDay), icon: "calendar")
    }
}
```
**意味**:
- `HStack`で2つのカードを横並びに配置
- `statCard`は再利用可能なカードビュー
- `String(format: "%.1f", ...)`: 小数点第1位まで表示

##### (4) 感情分布バー
```swift
private func moodDistributionRow(mood: Mood, count: Int, total: Int) -> some View {
    GeometryReader { geometry in
        ZStack(alignment: .leading) {
            // 背景バー（グレー）
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(height: 8)

            // 進行バー（感情の色）
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.color(for: mood))
                .frame(width: geometry.size.width * CGFloat(count) / CGFloat(total), height: 8)
        }
    }
}
```
**意味**:
- `GeometryReader`: 親の幅を取得
- `ZStack(alignment: .leading)`: 左揃えで重ねる
- 幅の計算: `親の幅 × (カウント / 合計)` で割合を表現

##### (5) 期間セレクター
```swift
private func periodButton(title: String, period: AnalyticsPeriod) -> some View {
    Button(action: {
        viewModel.updatePeriod(period)
    }) {
        Text(title)
            .background(viewModel.selectedPeriod == period ? Color.blue : Color(.systemGray6))
    }
}
```
**意味**:
- 選択中の期間は青色、それ以外はグレー
- タップすると`viewModel.updatePeriod()`を呼び出してデータを更新

##### (6) 感情トレンドグリッド
```swift
LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 8) {
    ForEach(sortedTrend, id: \.key) { date, mood in
        VStack(spacing: 4) {
            Text(mood.emoji).font(.title3)
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption2)
        }
        .padding(8)
        .background(Color.color(for: mood).opacity(0.2))
        .cornerRadius(8)
    }
}
```
**意味**:
- カレンダー風のグリッド表示
- 各日付の感情を絵文字で表示
- 背景色は感情に応じて変化（透明度20%）

---

### 2. AnalyticsViewModel.swift

#### 役割
統計データの計算とViewへのデータ提供を担当。

#### コード解説

##### (1) プロパティ定義
```swift
@Published var statistics: MoodStatistics?
@Published var selectedPeriod: AnalyticsPeriod = .month
@Published var moodTrend: [Date: Mood] = [:]
@Published var isLoading = false
```
**意味**:
- `@Published`: 値が変わるとViewが自動更新される
- `statistics`: 計算された統計情報（Optional）
- `selectedPeriod`: 現在選択中の期間（デフォルトは月）
- `moodTrend`: 日付ごとの感情マップ
- `isLoading`: ローディング中かどうか

##### (2) 依存注入（Dependency Injection）
```swift
init(
    analyticsService: AnalyticsServiceProtocol = AnalyticsService(),
    persistenceService: DataPersistenceServiceProtocol = FileSystemDataPersistenceService()
) {
    self.analyticsService = analyticsService
    self.persistenceService = persistenceService
    loadData()
}
```
**意味**:
- **プロトコル型**で受け取ることでテスト時にモックオブジェクトに差し替え可能
- デフォルト引数により、通常使用時はシンプルに`AnalyticsViewModel()`で初期化可能
- 初期化時に`loadData()`を自動実行

##### (3) データ読み込み
```swift
func loadData() {
    isLoading = true

    DispatchQueue.global(qos: .userInitiated).async {
        do {
            let entries = try self.persistenceService.load()
            self.entries = entries

            let statistics = self.analyticsService.calculateStatistics(for: entries)
            let moodTrend = self.analyticsService.getMoodTrend(for: entries, period: self.selectedPeriod)

            DispatchQueue.main.async {
                self.statistics = statistics
                self.moodTrend = moodTrend
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}
```
**意味**:
1. `isLoading = true`でローディング開始
2. **バックグラウンドスレッド**でデータ読み込み・計算（重い処理）
3. `persistenceService.load()`で日記データを取得
4. `analyticsService`で統計とトレンドを計算
5. **メインスレッド**でUI更新用プロパティを更新
6. エラー時もローディングを終了

**なぜバックグラウンド処理？**
- データ読み込みや統計計算は時間がかかる可能性がある
- メインスレッドで実行するとUIがフリーズする
- ユーザー体験を向上させるため

##### (4) 期間更新
```swift
func updatePeriod(_ period: AnalyticsPeriod) {
    selectedPeriod = period
    moodTrend = analyticsService.getMoodTrend(for: entries, period: period)
}
```
**意味**:
- 期間ボタンがタップされた時に呼ばれる
- 既にロード済みの`entries`を使って再計算（高速）
- トレンドのみ更新（総合統計は変わらない）

---

## 連携・関係性

### 1. 他のFeatureとの連携

#### (1) Home Feature
```
HomeView (TabView)
    └── AnalyticsView (タブの一つ)
```
- `HomeView`の`TabView`の中で`AnalyticsView`が表示される
- タブ切り替えで瞬時にアクセス可能

#### (2) DiaryEntry Feature
```
DiaryEntry作成 → データ保存 → Analytics画面で反映
```
- 新しい日記が作成されると、Analytics画面のデータも更新される
- `loadData()`を再度呼ぶことで最新データを取得

### 2. Servicesとの連携

#### (1) AnalyticsService
```swift
let statistics = analyticsService.calculateStatistics(for: entries)
```
**役割**:
- 統計情報の計算ロジックを提供
- `MoodStatistics`構造体を返す
- ViewModelから統計計算の詳細を隠蔽

#### (2) DataPersistenceService
```swift
let entries = try persistenceService.load()
```
**役割**:
- ファイルシステムから日記データを読み込む
- エラーハンドリングを含む

### 3. データフロー図
```
DataPersistenceService (ファイル読み込み)
    ↓ [DiaryEntry]配列
AnalyticsViewModel
    ↓ AnalyticsServiceで計算
    ↓ [MoodStatistics, MoodTrend]
AnalyticsView
    ↓ ビュー構築
ユーザー画面
```

---

## 実際の使用例

### ケース1: ユーザーが Analytics タブを開く

**シナリオ**: ユーザーがHomeViewのタブバーから「Analytics」をタップ

**処理フロー**:
1. `AnalyticsView`が表示される
2. `@StateObject`により`AnalyticsViewModel`が初期化される
3. `init()`内で`loadData()`が自動実行
4. ローディングインジケータが表示される
5. バックグラウンドでデータ読み込みと統計計算
6. 完了後、統計情報が画面に表示される

**コード**:
```swift
// HomeView.swift
TabView {
    // ...
    AnalyticsView()  // <- タップされると表示
        .tabItem { Label("Analytics", systemImage: "chart.bar") }
}
```

---

### ケース2: 期間フィルタを変更する

**シナリオ**: 月次統計を見ていたユーザーが「Week」ボタンをタップ

**処理フロー**:
1. `periodButton`の`action`が実行される
2. `viewModel.updatePeriod(.week)`が呼ばれる
3. `selectedPeriod`が`.week`に更新
4. `moodTrend`が週次データで再計算される
5. Viewが自動的に再描画され、週次トレンドが表示される

**コード**:
```swift
Button(action: {
    viewModel.updatePeriod(.week)  // <- ここが実行される
}) {
    Text("Week")
        .background(viewModel.selectedPeriod == .week ? Color.blue : Color(.systemGray6))
}
```

---

### ケース3: データがない場合

**シナリオ**: 新規ユーザーがAnalytics画面を開く

**処理フロー**:
1. `loadData()`が実行される
2. `persistenceService.load()`が空配列を返す
3. `statistics`が`nil`のまま
4. `emptyStateView`が表示される
5. 「Create some diary entries...」というメッセージが表示

**コード**:
```swift
if viewModel.isLoading {
    ProgressView("Loading...")
} else if let statistics = viewModel.statistics {
    // 統計表示
} else {
    emptyStateView  // <- ここが表示される
}
```

---

### ケース4: 感情分布バーの表示

**シナリオ**: ユーザーが過去30日間で「Happiness」を10回、「Calm」を5回記録

**処理フロー**:
1. `AnalyticsService`が感情ごとのカウントを計算
2. `moodDistribution = [.happiness: 10, .calm: 5]`
3. `moodDistributionView`で降順にソート
4. 各感情について`moodDistributionRow`を生成
5. バーの幅が`(10/15)*100% = 66.7%`で表示

**コード**:
```swift
let sortedMoods = statistics.moodDistribution.sorted { $0.value > $1.value }
ForEach(sortedMoods, id: \.key) { mood, count in
    moodDistributionRow(mood: mood, count: count, total: statistics.totalEntries)
}

// バーの幅計算
.frame(width: geometry.size.width * CGFloat(count) / CGFloat(total), height: 8)
// 幅 = 画面幅 × (10 / 15) = 66.7%
```

---

## よくある質問

### Q1. `@StateObject`と`@ObservedObject`の違いは？
**A**:
- **@StateObject**: Viewがオブジェクトを**作成して所有**する。Viewのライフサイクル全体で同じインスタンスが保持される
- **@ObservedObject**: 外部から渡されたオブジェクトを**監視するだけ**。親Viewから渡されたViewModelに使う

`AnalyticsView`は自分で`AnalyticsViewModel`を作るため`@StateObject`を使用。

---

### Q2. なぜ統計計算をバックグラウンドスレッドで行うの？
**A**:
- 大量の日記データがある場合、統計計算に時間がかかる
- メインスレッド（UIスレッド）で重い処理を行うと、画面がフリーズしてユーザー体験が悪化
- `DispatchQueue.global(qos: .userInitiated).async`でバックグラウンド処理を行い、完了後に`DispatchQueue.main.async`でUI更新

---

### Q3. `GeometryReader`の役割は？
**A**:
- 親ビューのサイズ情報を取得するためのビュー
- プログレスバーの幅を動的に計算する際に使用
- `geometry.size.width`で親の幅を取得し、割合に応じてバーの幅を設定

---

### Q4. `LazyVGrid`の`.adaptive(minimum: 40)`とは？
**A**:
- グリッドの列数を自動調整する設定
- 各セルの最小幅を40ポイントとし、画面幅に応じて可能な限り多くの列を表示
- iPhoneとiPadで自動的に最適なレイアウトになる

---

### Q5. データがない場合はどうなる？
**A**:
```swift
else {
    emptyStateView  // Empty Stateを表示
}
```
- 日記データが1件もない場合、`statistics`が`nil`となる
- `emptyStateView`が表示され、日記作成を促すメッセージが表示される

---

### Q6. 期間フィルタ（Week/Month/Year）の実装は？
**A**:
```swift
func updatePeriod(_ period: AnalyticsPeriod) {
    selectedPeriod = period
    moodTrend = analyticsService.getMoodTrend(for: entries, period: period)
}
```
- `AnalyticsPeriod`はenumで`.week`, `.month`, `.year`を定義
- 期間ボタンをタップすると`updatePeriod()`が呼ばれる
- `AnalyticsService`が期間に応じたトレンドデータを計算

---

### Q7. 感情の色はどこで定義されている？
**A**:
```swift
Color.color(for: mood)  // Extensionで定義
```
- `Color`の拡張機能（Extension）で各`Mood`に対応する色を定義
- `core/utilities/Extensions.swift`に実装されている

---

### Q8. リアルタイム更新はどう実現している？
**A**:
```swift
@Published var statistics: MoodStatistics?
```
- `@Published`により、値が変更されるとViewが自動的に再描画される
- Combineフレームワークの仕組みを利用
- ViewModelのプロパティが更新されると即座にUIに反映される

---

## まとめ

### Analytics Featureの重要ポイント

1. **MVVM アーキテクチャ**
   - View: UI表示のみ
   - ViewModel: ビジネスロジックとデータ管理
   - Service: 統計計算とデータ永続化

2. **非同期処理**
   - バックグラウンドスレッドで重い処理
   - メインスレッドでUI更新
   - ユーザー体験を損なわない

3. **動的レイアウト**
   - `GeometryReader`で画面サイズに対応
   - `LazyVGrid`でレスポンシブなグリッド
   - デバイスサイズに自動適応

4. **状態管理**
   - `@Published`で自動UI更新
   - `@StateObject`でライフサイクル管理
   - Combineフレームワークの活用

5. **エラーハンドリング**
   - データ読み込み失敗時の処理
   - Empty Stateの表示
   - ユーザーフレンドリーなエラー表示

### 学習の次のステップ

1. **AnalyticsService**の実装を確認（`core/services/`）
2. **Combineフレームワーク**の詳細学習
3. **非同期処理**（async/await）の理解
4. **カスタムチャートビュー**の実装

---

## 参考リンク

### 公式ドキュメント
- [SwiftUI - Apple Developer](https://developer.apple.com/xcode/swiftui/)
- [Combine Framework - Apple](https://developer.apple.com/documentation/combine)
- [DispatchQueue - Apple](https://developer.apple.com/documentation/dispatch/dispatchqueue)

### SwiftUI Concepts
- [State and Data Flow](https://developer.apple.com/documentation/swiftui/state-and-data-flow)
- [GeometryReader](https://developer.apple.com/documentation/swiftui/geometryreader)
- [LazyVGrid](https://developer.apple.com/documentation/swiftui/lazyvgrid)

### アーキテクチャ
- [MVVM Pattern in SwiftUI](https://www.hackingwithswift.com/books/ios-swiftui/introducing-mvvm-into-your-swiftui-project)
- [Dependency Injection](https://www.swiftbysundell.com/articles/dependency-injection-using-factories-in-swift/)

---

**このドキュメントについて**
作成日: 2025年
対象: Swift初心者〜中級者
バージョン: FaceDiary v1.0
