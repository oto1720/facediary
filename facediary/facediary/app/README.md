# App Directory

## Overview
アプリケーションのエントリーポイントと、アプリ全体のライフサイクル、およびトップレベルの状態遷移を管理するディレクトリです。
起動時の初期化処理や、認証状態に応じた画面の切り替え（ルーティング）を担当します。

## Components

### Entry Point
*   **facediaryApp.swift**
    *   `@main` 属性を持つアプリのエントリーポイント。
    *   `WindowGroup` を定義し、ルートビューとして `ContentView` を設定します。
    *   `PersistenceController` の初期化もここで行われます。

### Views
*   **ContentView.swift**
    *   アプリのルートビューです。
    *   `AppViewModel` の `appState` に基づいて、表示する画面を切り替えます。
        *   `.loading`: ローディング画面（`ProgressView`）
        *   `.onboarding`: 顔登録画面（`FaceRegistrationView`）
        *   `.authentication`: 認証画面（`AuthenticationView`）
        *   `.authenticated`: メイン画面（`HomeView`）

### ViewModels
*   **AppViewModel.swift**
    *   **責務**: アプリ全体のステート管理と初期化フローの制御。
    *   **主要プロパティ**:
        *   `appState`: 現在のアプリの状態（`AppState` enum）。
    *   **主要メソッド**:
        *   `checkInitialState()`: 起動時に顔データの有無を確認し、適切な初期画面（Onboarding or Authentication）を決定します。
        *   `onFaceRegistrationCompleted()`: 顔登録完了時の遷移処理。
        *   `onAuthenticationSucceeded()`: 認証成功時の遷移処理。
    *   **依存サービス**:
        *   `SecurityService`: 顔データの存在確認。

## Application Flow
1.  **起動**: `facediaryApp` が `ContentView` を表示します。
2.  **初期化**: `ContentView` が `AppViewModel` を初期化し、`checkInitialState()` が実行されます。
3.  **状態判定**:
    *   顔データがない場合 → `.onboarding` 状態になり、`FaceRegistrationView` を表示。
    *   顔データがある場合 → `.authentication` 状態になり、`AuthenticationView` を表示。
4.  **遷移**:
    *   顔登録完了 → `.authentication` へ遷移。
    *   認証成功 → `.authenticated` へ遷移し、`HomeView` を表示。
