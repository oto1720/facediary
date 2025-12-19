# App Directory

## 目次
1. [Overview（概要）](#overview)
2. [SwiftUIの基礎知識](#swiftuiの基礎知識)
3. [ファイル構成](#ファイル構成)
4. [詳細解説](#詳細解説)
5. [アプリの起動フロー](#アプリの起動フロー)
6. [クラス間の関係](#クラス間の関係)
7. [よくある質問](#よくある質問)

---

## Overview
アプリケーションのエントリーポイントと、アプリ全体のライフサイクル、およびトップレベルの状態遷移を管理するディレクトリです。
起動時の初期化処理や、認証状態に応じた画面の切り替え（ルーティング）を担当します。

このディレクトリは、アプリケーション全体の「入り口」として機能し、ユーザーがアプリを起動したときに最初に実行されるコードが含まれています。

---

## SwiftUIの基礎知識

### SwiftUIとは
SwiftUIは、Appleが提供する宣言的なUIフレームワークです。「宣言的」とは、「UIがどのように見えるべきか」を記述すると、フレームワークが自動的にそれを実現してくれるという意味です。

従来のUIKit（命令的）では：
```swift
let label = UILabel()
label.text = "こんにちは"
label.textColor = .blue
view.addSubview(label)
```

SwiftUIでは：
```swift
Text("こんにちは")
    .foregroundColor(.blue)
```

このように、SwiftUIではコードがシンプルで読みやすくなります。

### Viewプロトコル
SwiftUIでは、画面に表示される全ての要素は `View` プロトコルに準拠した構造体（struct）として定義されます。
`View` プロトコルは、`body` プロパティを持つ必要があります。これが実際に画面に表示される内容を返します。

```swift
struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
    }
}
```

### Appプロトコル
`App` プロトコルは、アプリケーション全体のエントリーポイントを定義します。
構造体が `App` プロトコルに準拠すると、その構造体がアプリケーションのライフサイクルを管理します。

### @main属性
`@main` は、このファイルがプログラムのエントリーポイント（開始点）であることをSwiftに伝えます。
C言語やJavaの `main()` 関数と同じ役割です。アプリが起動すると、`@main` が付いた構造体が最初に実行されます。

### Scene（シーン）
`Scene` は、アプリのユーザーインターフェースの一部を表します。
- `WindowGroup`: 1つ以上のウィンドウを管理するシーン。iOSでは通常1つのウィンドウ、iPadやMacでは複数のウィンドウを持つことができます。

### ObservableObjectプロトコル
`ObservableObject` は、状態の変化を監視可能なオブジェクトを作成するためのプロトコルです。
このプロトコルに準拠したクラスは、`@Published` プロパティの変更を自動的にビューに通知します。

**なぜクラスなのか？**
`ObservableObject` は参照型（クラス）である必要があります。これは、複数のビューが同じインスタンスを共有し、
1つのビューで状態が変更されたときに、他のビューも自動的に更新されるようにするためです。

### @Published
`@Published` は、プロパティラッパーの一種で、このプロパティが変更されたときに自動的に購読者（ビュー）に通知します。

```swift
class AppViewModel: ObservableObject {
    @Published var appState: AppState = .loading
    // appStateが変わると、このViewModelを監視している全てのビューが自動的に再描画されます
}
```

### @StateObject
`@StateObject` は、ビューがObservableObjectのインスタンスを所有し、そのライフサイクルを管理することを示します。
ビューが生成されるときに一度だけ作成され、ビューが破棄されるまで保持されます。

```swift
struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    // このビューが存在する限り、同じappViewModelインスタンスが使われます
}
```

**@ObservedObjectとの違い：**
- `@StateObject`: このビューがオブジェクトの「所有者」
- `@ObservedObject`: 親ビューから渡されたオブジェクトを「観察」するだけ

### @EnvironmentObject
`@EnvironmentObject` は、ビュー階層全体で共有されるオブジェクトです。
親ビューから子ビューへ、さらにその子ビューへと、引数として渡さなくても自動的に利用可能になります。

```swift
HomeView()
    .environmentObject(appViewModel)
// HomeViewとその全ての子ビューでappViewModelが使えるようになります
```

### enum（列挙型）
`enum` は、関連する値のグループを定義するための型です。
このアプリでは、アプリの状態を表すために使われています。

```swift
enum AppState {
    case loading        // 読み込み中
    case onboarding     // 初回セットアップ
    case authentication // 認証待ち
    case authenticated  // 認証済み
}
```

列挙型を使うことで、アプリが取りうる状態を明確にし、想定外の状態を防ぐことができます。

---

## ファイル構成

```
app/
├── facediaryApp.swift     # アプリのエントリーポイント
├── ContentView.swift      # ルートビュー（画面の切り替えを担当）
├── AppViewModel.swift     # アプリ全体の状態管理
└── AppDelegate.swift      # （空ファイル）UIKitとの連携用（現在未使用）
```

---

## 詳細解説

### 1. facediaryApp.swift
**ファイルパス**: `facediary/facediary/app/facediaryApp.swift`

#### 役割
このファイルは、アプリケーション全体のエントリーポイント（開始点）です。
iOSアプリが起動すると、このファイルの `@main` が付いた構造体が最初に実行されます。

#### コードの詳細解説

```swift
import SwiftUI
```
- SwiftUIフレームワークをインポート（読み込み）しています。
- このimport文により、SwiftUIの全ての機能（View、App、WindowGroupなど）が使えるようになります。

```swift
@main
```
- この属性は、「このファイルがアプリの開始点です」とSwiftに伝えます。
- アプリ内で `@main` を付けられるのは1つのファイルだけです。
- これがないと、アプリはどこから実行を始めればいいか分かりません。

```swift
struct facediaryApp: App {
```
- `facediaryApp` という名前の構造体を定義しています。
- `App` プロトコルに準拠しているため、アプリケーションとして機能します。
- **命名規則**: 通常、型名は大文字で始めますが（例: FacediaryApp）、このコードでは小文字で始まっています。

```swift
let persistenceController = PersistenceController.shared
```
- `PersistenceController` は、Core Dataを管理するシングルトンオブジェクトです。
- Core Dataは、iOSアプリでデータを永続化（保存）するためのフレームワークです。
- `.shared` は、アプリ全体で1つのインスタンスだけを共有するパターン（シングルトンパターン）です。
- **注意**: 現在のコードでは定義されていますが、実際には使われていないようです。

```swift
var body: some Scene {
```
- `App` プロトコルに準拠するために必須のプロパティです。
- `some Scene` は、「何らかのSceneプロトコルに準拠した型」を返すという意味です（Opaque Type）。
- `body` は、アプリのシーン構成を定義します。

```swift
WindowGroup {
    ContentView()
}
```
- `WindowGroup` は、1つ以上のウィンドウを管理するシーンです。
- iPhoneでは通常1つのウィンドウ、iPadやMacでは複数のウィンドウを持つことができます。
- `ContentView()` をルートビュー（最初に表示されるビュー）として設定しています。

#### このファイルの重要性
このファイルがなければアプリは起動しません。アプリのライフサイクル全体を制御する最上位のファイルです。

---

### 2. ContentView.swift
**ファイルパス**: `facediary/facediary/app/ContentView.swift`

#### 役割
アプリのルートビュー（根となるビュー）として、`AppViewModel` の状態に応じて適切な画面を表示します。
いわば「交通整理係」のような役割で、ユーザーがどの画面を見るべきかを判断します。

#### コードの詳細解説

```swift
import SwiftUI
```
- SwiftUIフレームワークをインポートしています。

```swift
struct ContentView: View {
```
- `ContentView` という名前の構造体を定義しています。
- `View` プロトコルに準拠しているため、画面要素として使えます。

```swift
@StateObject private var appViewModel = AppViewModel()
```
- `appViewModel` というプロパティを定義しています。
- `@StateObject` により、このビューが `AppViewModel` の所有者となります。
- `private` は、このプロパティがこのファイル内でのみアクセス可能であることを示します。
- `AppViewModel()` で新しいインスタンスを作成しています。

**なぜ@StateObjectを使うのか？**
- ビューの再描画時にもViewModelが再作成されず、同じインスタンスが保持されます。
- ViewModelの状態変更を自動的に検知し、ビューを更新します。

```swift
var body: some View {
```
- `View` プロトコルに準拠するために必須のプロパティです。
- 実際に画面に表示される内容を返します。

```swift
Group {
```
- `Group` は、複数のビューをまとめるコンテナです。
- ここでは、switch文で選択されたビューをラップしています。
- `Group` 自体は画面上に何も表示しませんが、子ビューをまとめる役割を果たします。

```swift
switch appViewModel.appState {
```
- `appViewModel` の `appState` プロパティの値に応じて、表示するビューを切り替えます。
- これが「画面の切り替え」を実現する核心部分です。

**各状態の詳細：**

```swift
case .loading:
    ProgressView("読み込み中...")
        .progressViewStyle(CircularProgressViewStyle())
```
- **状態**: アプリが起動して、初期化処理中
- **表示**: くるくる回る読み込みインジケーター
- **用途**: 顔データの存在確認など、非同期処理が完了するまで表示されます

```swift
case .onboarding:
    FaceRegistrationView(onComplete: {
        appViewModel.onFaceRegistrationCompleted()
    })
```
- **状態**: 初回起動時、まだ顔が登録されていない
- **表示**: 顔登録画面（`FaceRegistrationView`）
- **クロージャ**: `onComplete` は、顔登録が完了したときに呼ばれるコールバック関数です
- **遷移**: 登録完了後、`appViewModel.onFaceRegistrationCompleted()` を呼び出して認証画面へ

```swift
case .authentication:
    AuthenticationView(onAuthenticationSuccess: {
        appViewModel.onAuthenticationSucceeded()
    })
```
- **状態**: 顔登録済みで、認証待ち
- **表示**: 顔認証画面（`AuthenticationView`）
- **遷移**: 認証成功後、`appViewModel.onAuthenticationSucceeded()` を呼び出してメイン画面へ

```swift
case .authenticated:
    HomeView()
        .environmentObject(appViewModel)
```
- **状態**: 認証成功、アプリのメイン機能が使える状態
- **表示**: ホーム画面（`HomeView`）
- `.environmentObject(appViewModel)`: `HomeView` とその子ビュー全てで `appViewModel` にアクセス可能にします

```swift
#Preview {
    ContentView()
}
```
- Xcode 15以降で導入されたプレビュー機能です。
- Xcodeのキャンバスで、実機やシミュレータを起動せずにビューを確認できます。
- 開発中の画面確認が非常に高速になります。

#### このファイルの重要性
アプリ全体のナビゲーション（画面遷移）を一箇所で管理しています。
新しい画面状態を追加したい場合は、`AppState` enumに新しいcaseを追加し、ここでその画面を表示するコードを追加します。

---

### 3. AppViewModel.swift
**ファイルパス**: `facediary/facediary/app/AppViewModel.swift`

#### 役割
アプリ全体の状態（State）を管理し、ビジネスロジックを制御するViewModelです。
MVVMアーキテクチャパターンにおける「ViewModel」の役割を果たします。

#### MVVMアーキテクチャとは
- **Model**: データと基本的なビジネスロジック（例: DiaryEntry、FaceData）
- **View**: 画面表示（例: ContentView、HomeView）
- **ViewModel**: ViewとModelの仲介役、状態管理とビジネスロジック（例: AppViewModel）

ViewModelを使うことで、ビューのコードがシンプルになり、テストがしやすくなります。

#### コードの詳細解説

```swift
import SwiftUI
import Combine
```
- `SwiftUI`: SwiftUIフレームワークをインポート
- `Combine`: リアクティブプログラミングのフレームワーク（@PublishedやObservableObjectで内部的に使用）

```swift
enum AppState {
    case loading
    case onboarding
    case authentication
    case authenticated
}
```
- アプリが取りうる4つの状態を列挙型で定義しています。
- **loading**: 初期化処理中
- **onboarding**: 顔未登録、初回セットアップ
- **authentication**: 顔登録済み、認証待ち
- **authenticated**: 認証成功、メイン画面

**列挙型を使う利点：**
- コンパイル時に存在しない状態を防げる（タイプセーフ）
- switch文で全ケースを網羅しているかチェックできる
- 自動補完が効くので、タイプミスを防げる

```swift
class AppViewModel: ObservableObject {
```
- `class`: 参照型として定義（structではなく）
- `ObservableObject`: このクラスの状態変化を監視可能にします

**なぜclassなのか？**
- 複数のビューで同じインスタンスを共有するため
- `ObservableObject` プロトコルはclassでのみ使用可能

```swift
@Published var appState: AppState = .loading
```
- アプリの現在の状態を保持するプロパティ
- `@Published`: この値が変わると、購読しているビュー全てが自動的に再描画されます
- 初期値は `.loading`（読み込み中）

```swift
private let securityService: SecurityServiceProtocol
```
- 顔データの保存・読み込みを担当するサービス
- `private`: このクラス内でのみアクセス可能
- `SecurityServiceProtocol`: プロトコル指向プログラミングにより、テスト時にモックと差し替え可能

```swift
init(securityService: SecurityServiceProtocol = KeychainSecurityService()) {
    self.securityService = securityService
    checkInitialState()
}
```
- イニシャライザ（初期化メソッド）
- デフォルト引数により、通常は `KeychainSecurityService()` が使われます
- テスト時には別の実装を注入できます（Dependency Injection）
- 初期化時に `checkInitialState()` を呼び出して状態をチェックします

#### メソッドの詳細解説

**checkInitialState()**
```swift
func checkInitialState() {
    DispatchQueue.global(qos: .userInitiated).async {
        // バックグラウンドスレッドで実行
        do {
            let faceData = try self.securityService.loadFaceData()
            DispatchQueue.main.async {
                // メインスレッドでUI更新
                if faceData != nil {
                    self.appState = .authentication
                } else {
                    self.appState = .onboarding
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.appState = .onboarding
            }
        }
    }
}
```

**詳細解説：**
1. `DispatchQueue.global(qos: .userInitiated).async`:
   - バックグラウンドスレッドで非同期実行
   - `qos: .userInitiated`: ユーザーが開始した重要なタスクの優先度
   - メインスレッド（UI更新を担当）をブロックしないようにするため

2. `try self.securityService.loadFaceData()`:
   - Keychainから顔データを読み込み
   - エラーが発生する可能性があるため `try` を使用

3. `DispatchQueue.main.async`:
   - UI更新は必ずメインスレッドで行う必要があります
   - バックグラウンドスレッドからメインスレッドに戻します

4. 判定ロジック:
   - 顔データが存在 → `.authentication`（認証画面へ）
   - 顔データが存在しない or エラー → `.onboarding`（登録画面へ）

**onFaceRegistrationCompleted()**
```swift
func onFaceRegistrationCompleted() {
    appState = .authentication
}
```
- 顔登録が完了したときに呼ばれます
- 状態を `.authentication` に変更して認証画面へ遷移

**onAuthenticationSucceeded()**
```swift
func onAuthenticationSucceeded() {
    appState = .authenticated
}
```
- 顔認証が成功したときに呼ばれます
- 状態を `.authenticated` に変更してメイン画面へ遷移

**logout()**
```swift
func logout() {
    appState = .authentication
}
```
- ログアウト処理
- 状態を `.authentication` に戻します
- 設定画面などから呼ばれることを想定
- **注意**: 現在は顔データの削除は行っていません（状態の変更のみ）

#### このファイルの重要性
アプリ全体の「頭脳」として機能します。
状態管理とビジネスロジックを一箇所に集約することで、コードの見通しが良くなり、バグを減らすことができます。

---

### 4. AppDelegate.swift
**ファイルパス**: `facediary/facediary/app/AppDelegate.swift`

#### 役割
現在は空ファイルです。UIKitとの連携が必要になった場合に使用されます。

#### 背景知識
- UIKitは、SwiftUI以前のiOSアプリ開発フレームワークです
- `AppDelegate` は、UIKitでアプリのライフサイクルイベント（起動、バックグラウンド移行など）を処理するクラスです
- SwiftUIアプリでは基本的に不要ですが、以下のような場合に使用されます：
  - プッシュ通知の設定
  - サードパーティSDKの初期化
  - UIKitのコンポーネントとの統合

#### このファイルの重要性
現在は使用されていませんが、将来的な拡張のために残されています。

---

## アプリの起動フロー

以下は、アプリが起動してからユーザーがメイン画面にたどり着くまでの詳細なフローです。

### フロー図（テキスト）

```
[アプリ起動]
    ↓
① facediaryApp.swift が実行される
    ├─ @main により、ここが開始点
    ├─ PersistenceController.shared を初期化（Core Data）
    └─ WindowGroup で ContentView を表示
    ↓
② ContentView が初期化される
    ├─ @StateObject により AppViewModel() を作成
    │   └─ AppViewModel.init() が実行される
    │       ├─ securityService を初期化
    │       └─ checkInitialState() を呼び出す
    │           ↓
    │       【バックグラウンドスレッドで実行】
    │           ├─ securityService.loadFaceData() を実行
    │           │   ├─ Keychainから顔データを読み込み
    │           │   └─ データの有無を確認
    │           ↓
    │       【メインスレッドに戻る】
    │           └─ appState を更新
    │               ├─ 顔データあり → .authentication
    │               └─ 顔データなし → .onboarding
    ↓
③ ContentView の body が評価される
    └─ appState の初期値は .loading
        └─ ProgressView("読み込み中...") を表示
    ↓
④ checkInitialState() 完了後、appState が更新される
    ├─ @Published により、ContentView が自動的に再描画される
    └─ switch appViewModel.appState で分岐
        ├─ .onboarding の場合
        │   └─ FaceRegistrationView を表示
        │       └─ 顔登録完了後、onFaceRegistrationCompleted() を呼び出し
        │           └─ appState = .authentication に変更
        │               └─ AuthenticationView に遷移
        │
        └─ .authentication の場合
            └─ AuthenticationView を表示
                └─ 認証成功後、onAuthenticationSucceeded() を呼び出し
                    └─ appState = .authenticated に変更
                        └─ HomeView に遷移（メイン画面）
```

### 初回起動時の流れ（顔データなし）
1. アプリ起動 → facediaryApp
2. ContentView 表示 → ProgressView（読み込み中）
3. checkInitialState() 実行 → 顔データなし
4. appState = .onboarding
5. FaceRegistrationView 表示
6. ユーザーが顔を登録
7. onFaceRegistrationCompleted() 実行
8. appState = .authentication
9. AuthenticationView 表示
10. ユーザーが顔認証
11. onAuthenticationSucceeded() 実行
12. appState = .authenticated
13. HomeView 表示（メイン画面）

### 2回目以降の起動時の流れ（顔データあり）
1. アプリ起動 → facediaryApp
2. ContentView 表示 → ProgressView（読み込み中）
3. checkInitialState() 実行 → 顔データあり
4. appState = .authentication
5. AuthenticationView 表示
6. ユーザーが顔認証
7. onAuthenticationSucceeded() 実行
8. appState = .authenticated
9. HomeView 表示（メイン画面）

---

## クラス間の関係

### 依存関係図

```
facediaryApp (App)
    │
    └─── ContentView (View)
            │
            ├─── AppViewModel (ViewModel) @StateObject
            │       │
            │       ├─── AppState (Enum)
            │       │       ├─ .loading
            │       │       ├─ .onboarding
            │       │       ├─ .authentication
            │       │       └─ .authenticated
            │       │
            │       └─── SecurityServiceProtocol (Protocol)
            │               └─── KeychainSecurityService (Implementation)
            │
            └─── 表示されるView（appStateに応じて変わる）
                    ├─ ProgressView (.loading)
                    ├─ FaceRegistrationView (.onboarding)
                    ├─ AuthenticationView (.authentication)
                    └─ HomeView (.authenticated) ← @EnvironmentObject で appViewModel を受け取る
```

### データフローの説明

1. **単方向データフロー**
   ```
   ユーザーアクション
       ↓
   ViewModel のメソッド呼び出し
       ↓
   @Published プロパティの更新
       ↓
   View の自動再描画
   ```

2. **状態の流れ**
   ```
   AppViewModel (@Published appState)
       ↓ 状態変更を通知
   ContentView (@StateObject)
       ↓ 適切なビューを選択
   子ビュー (FaceRegistrationView, AuthenticationView, HomeView)
   ```

3. **コールバックの流れ**
   ```
   子ビュー (例: AuthenticationView)
       ↓ onAuthenticationSuccess クロージャ呼び出し
   ContentView
       ↓ appViewModel.onAuthenticationSucceeded() 実行
   AppViewModel
       ↓ appState を更新
   ContentView
       ↓ 再描画、新しいビューを表示
   HomeView
   ```

### プロトコル指向プログラミング

```swift
protocol SecurityServiceProtocol {
    func loadFaceData() throws -> FaceData?
    func saveFaceData(_ data: FaceData) throws
}

class AppViewModel {
    private let securityService: SecurityServiceProtocol
    // 実装ではなく、プロトコルに依存
}
```

**利点：**
- テスト時にモック実装と差し替え可能
- 実装の詳細を隠蔽（カプセル化）
- 将来的な実装変更が容易（Keychainから別の保存方法への変更など）

---

## よくある質問

### Q1: なぜContentViewとAppViewModelを分けるのですか？
**A**: MVVMアーキテクチャパターンに従うためです。
- **View (ContentView)**: 画面表示のみに集中
- **ViewModel (AppViewModel)**: ビジネスロジックと状態管理

これにより、コードの責任が明確になり、テストがしやすくなります。

### Q2: @StateObjectと@ObservedObjectの違いは何ですか？
**A**:
- `@StateObject`: ビューがオブジェクトを**所有**します。ビューが生成されるときに一度だけ作成され、ビューが存在する限り保持されます。
- `@ObservedObject`: 親ビューから渡されたオブジェクトを**観察**するだけです。ビューの再描画時に新しいインスタンスになる可能性があります。

**使い分け：**
- オブジェクトを作成するビュー → `@StateObject`
- 親から渡されたオブジェクトを使うビュー → `@ObservedObject`

### Q3: なぜ非同期処理でDispatchQueueを2回使っているのですか？
**A**:
```swift
DispatchQueue.global(...).async {
    // 重い処理（Keychainアクセス）
    DispatchQueue.main.async {
        // UI更新
    }
}
```
- **global**: 重い処理をバックグラウンドスレッドで実行し、UIをブロックしない
- **main**: UI更新は必ずメインスレッドで行う必要があるため

### Q4: enumのAppStateに新しい状態を追加したい場合は？
**A**:
1. `AppState` enumに新しいcaseを追加
   ```swift
   enum AppState {
       case loading
       case onboarding
       case authentication
       case authenticated
       case settings // 新しい状態
   }
   ```
2. `ContentView` の switch文に新しいcaseを追加
   ```swift
   case .settings:
       SettingsView()
   ```
3. 状態遷移のメソッドを `AppViewModel` に追加
   ```swift
   func showSettings() {
       appState = .settings
   }
   ```

### Q5: PersistenceControllerは何に使われていますか？
**A**: Core Dataの管理に使われることを想定していますが、現在のコードでは実際には使用されていません。
将来的に、日記データなどをCore Dataで保存する場合に使用される予定です。

### Q6: クロージャ（onComplete、onAuthenticationSuccess）とは何ですか？
**A**: クロージャは、関数を値として扱えるSwiftの機能です。
```swift
FaceRegistrationView(onComplete: {
    appViewModel.onFaceRegistrationCompleted()
})
```
ここでは、「顔登録が完了したら何をするか」を関数として渡しています。
これにより、子ビュー（FaceRegistrationView）は親ビュー（ContentView）の詳細を知らなくても、
完了時に適切な処理を実行できます（疎結合）。

### Q7: アプリを起動したときに毎回認証が必要なのはなぜですか？
**A**: セキュリティのためです。
顔認証は、アプリがバックグラウンドに移行したり、完全に終了したりすると、再度認証が必要になります。
これにより、他の人がデバイスを手に取った場合でも、日記の内容を見られないようにしています。

### Q8: SwiftUIのビューは何度も作り直されるのですか？
**A**: はい、SwiftUIのビューは状態が変わるたびに再作成されます。
しかし、これはパフォーマンスの問題にはなりません。なぜなら：
- ビュー（struct）は軽量で、作り直しても高速
- `@StateObject` を使うことで、ViewModelは再作成されず、同じインスタンスが保持される
- SwiftUIが差分を計算し、実際に変更が必要な部分だけを更新する

---

## まとめ

`app` ディレクトリは、FaceDiaryアプリの「司令塔」として機能します：

1. **facediaryApp.swift**: アプリの開始点
2. **ContentView.swift**: 画面の切り替えを担当
3. **AppViewModel.swift**: アプリ全体の状態とビジネスロジックを管理

これらが協力することで、ユーザーにシームレスな体験を提供しています。

---

## 参考リンク
- [Apple公式: SwiftUI チュートリアル](https://developer.apple.com/tutorials/swiftui)
- [Apple公式: App Structure](https://developer.apple.com/documentation/swiftui/app-structure)
- [Apple公式: State and Data Flow](https://developer.apple.com/documentation/swiftui/state-and-data-flow)
