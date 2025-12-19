# Home Feature - ホーム画面機能

## 目次
1. [概要](#概要)
2. [ファイル構成](#ファイル構成)
3. [詳細解説](#詳細解説)
4. [よくある質問](#よくある質問)
5. [まとめ](#まとめ)

---

## 概要

**Home Feature**は、アプリのメイン画面であり、日記一覧とAnalytics画面へのナビゲーションを提供します。ユーザーが作成した日記エントリーを時系列で表示し、詳細画面や作成画面への遷移を管理します。

### 主な機能
- **タブナビゲーション**: DiaryとAnalyticsの2つのタブ
- **日記一覧表示**: 作成した日記を新しい順に表示
- **日記作成**: +ボタンから新規日記作成
- **設定画面**: 歯車アイコンから設定へアクセス
- **Empty State**: 日記がない場合の表示

---

## ファイル構成

```
feature/home/
├── view/
│   ├── HomeView.swift          # メイン画面とタブ管理
│   └── DiaryListView.swift     # (未使用/空ファイル)
├── viewmodels/
│   └── HomeViewModel.swift     # 日記データ管理
└── README.md
```

---

## 詳細解説

### 1. HomeView.swift

#### 役割
アプリのメイン画面。TabViewで日記一覧とAnalyticsを切り替え、日記の作成・設定へのアクセスを提供。

#### 重要なポイント

##### (1) TabView構造
```swift
TabView(selection: $selectedTab) {
    diaryListTab
        .tabItem { Label("Diary", systemImage: "book") }
        .tag(0)

    AnalyticsView()
        .tabItem { Label("Analytics", systemImage: "chart.bar") }
        .tag(1)
}
```
- 2つのタブ: Diary（日記一覧）とAnalytics（統計）
- `selectedTab`で現在のタブを管理
- `tag`でタブを識別

##### (2) グラデーション背景
```swift
ZStack {
    LinearGradient(
        gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    .ignoresSafeArea()

    // コンテンツ
}
```
- 青から紫へのグラデーション
- 視覚的に魅力的なデザイン
- Safe Areaを無視して全画面表示

##### (3) 状態に応じた表示
```swift
if viewModel.isLoading {
    ProgressView("Loading...")
} else if viewModel.diaryEntries.isEmpty {
    emptyStateView
} else {
    diaryListView
}
```
- ローディング中: プログレスインジケータ
- データなし: Empty State（作成を促す）
- データあり: 日記リスト

##### (4) ツールバー
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button { showingSettings = true }
    }

    ToolbarItem(placement: .navigationBarTrailing) {
        Button { showingDiaryCreate = true }
    }
}
```
- 左: 設定ボタン
- 右: 日記作成ボタン（+アイコン）

##### (5) シートプレゼンテーション
```swift
.sheet(isPresented: $showingDiaryCreate) {
    DiaryEntryCreateView(onComplete: {
        viewModel.loadDiaryEntries()
    })
}

.sheet(isPresented: $showingSettings) {
    SettingsView(onFaceDataDeleted: {
        // 顔データ削除時の処理
    })
}
```
- モーダルで日記作成画面を表示
- 完了時に`loadDiaryEntries()`でリフレッシュ
- コールバックパターンで連携

---

### 2. DiaryEntryRow (HomeView内の内部View)

#### 役割
リスト内の各日記エントリーの行を表示するサブビュー。

#### 表示内容
```swift
struct DiaryEntryRow: View {
    let entry: DiaryEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let primaryMood = entry.primaryMood {
                Text(primaryMood.emoji).font(.system(size: 40))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, style: .date).font(.caption)
                Text(entry.text).font(.body).lineLimit(2)
            }

            Spacer()
        }
    }
}
```
- 感情の絵文字（大きく表示）
- 日付（小さく、グレー）
- 本文の抜粋（2行まで）

---

### 3. HomeViewModel.swift

#### 役割
日記データの読み込みとリスト管理を担当。

#### 重要なメソッド

##### (1) データ読み込み
```swift
func loadDiaryEntries() {
    isLoading = true
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            let entries = try self.persistenceService.load()
            DispatchQueue.main.async {
                self.diaryEntries = entries.sorted { $0.date > $1.date }
                self.isLoading = false
            }
        } catch {
            // エラーハンドリング
        }
    }
}
```
**処理フロー**:
1. ローディング開始
2. バックグラウンドスレッドでデータ読み込み
3. 日付降順にソート（新しい順）
4. メインスレッドでUI更新

##### (2) 日記削除
```swift
func deleteDiaryEntry(at offsets: IndexSet) {
    diaryEntries.remove(atOffsets: offsets)
    saveDiaryEntries()
}
```
- SwiftUIの`onDelete`モディファイアと連携
- スワイプで削除
- 自動的に保存

##### (3) 初期化時の自動読み込み
```swift
init(persistenceService: DataPersistenceServiceProtocol = FileSystemDataPersistenceService()) {
    self.persistenceService = persistenceService
    loadDiaryEntries()
}
```
- ViewModelの初期化時に自動でデータ読み込み
- 画面表示時には既にデータが準備されている

---

## よくある質問

### Q1. TabViewとNavigationStackの関係は？
**A**:
```swift
TabView {
    diaryListTab  // <- NavigationStackを含む
    AnalyticsView()
}
```
- TabViewが最上位
- 各タブ内にNavigationStackを配置
- タブごとに独立したナビゲーション階層

### Q2. なぜグラデーション背景？
**A**:
- 視覚的な魅力を高める
- ブランドカラー（青と紫）を表現
- Listの背景を透明にして調和させる

### Q3. Empty Stateの重要性は？
**A**:
```swift
VStack {
    Image(systemName: "book.closed")
    Text("No Diary Entries Yet")
    Button("Create Diary") { showingDiaryCreate = true }
}
```
- 初回ユーザーに次のアクションを明示
- アプリの使い方を視覚的に伝える
- ユーザー体験の向上

### Q4. データのリフレッシュタイミングは？
**A**:
- ViewModelの初期化時（画面表示時）
- 日記作成完了時（`onComplete`コールバック）
- 日記削除時（自動）

### Q5. ソート順は？
**A**:
```swift
self.diaryEntries = entries.sorted { $0.date > $1.date }
```
- 日付降順（新しい順）
- 最新の日記が一番上に表示

---

## まとめ

### Home Featureの重要ポイント

1. **ナビゲーション設計**
   - TabViewでセクション分離
   - NavigationStackで画面遷移管理
   - Sheetでモーダル表示

2. **状態管理**
   - ローディング、Empty、データあり
   - 各状態で適切なUIを表示
   - `@Published`で自動更新

3. **データ永続化**
   - バックグラウンドで読み込み
   - UIスレッドをブロックしない
   - エラーハンドリング

4. **UX設計**
   - グラデーション背景
   - Empty State
   - スワイプで削除

### 学習の次のステップ
1. TabView と NavigationStack の組み合わせ
2. List と ForEach の使い方
3. Sheet プレゼンテーション
4. コールバックパターン

---

**このドキュメントについて**
作成日: 2025年
対象: Swift初心者〜中級者
バージョン: FaceDiary v1.0
