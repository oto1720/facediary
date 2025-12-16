# Onboarding Feature

## Overview
アプリの初回起動時にユーザーの顔データを登録するための機能です。
このプロセスにより、その後の認証機能（Authentication）で使用される参照データが作成されます。

## Components

### Views
*   **FaceRegistrationView.swift**
    *   顔登録のメイン画面です。
    *   **State Handling**:
        *   `initial`/`capturing`: ガイドメッセージと撮影ボタンを表示。
        *   `processing`: 処理中のインジケータを表示。
        *   `completed`: 成功メッセージと次へ進むボタンを表示。
        *   `failed`: エラーメッセージと再試行ボタンを表示。
*   **OnboardingView.swift**
    *   オンボーディングフロー全体のコンテナ（実装状況によってはプレースホルダーの可能性があります）。

### ViewModels
*   **OnboardingViewModel.swift**
    *   **責務**: 顔登録プロセスの状態管理と実行。
    *   **主要プロパティ**:
        *   `registrationState`: 現在の登録状態（`OnboardingRegistrationState`）。
    *   **主要メソッド**:
        *   `startCamera()`: カメラを起動し、撮影モードにします。
        *   `registerFace()`: 現在のフレームをキャプチャし、顔データの生成と保存を行います。
    *   **依存サービス**:
        *   `CameraService`: カメラ映像の取得。
        *   `FaceRecognitionService`: 顔データ（特徴量）の生成。
        *   `SecurityService`: 顔データの安全な保存（Keychain等）。

## Flow
1.  画面が表示されるとカメラが起動します。
2.  ユーザーが顔を枠に合わせて撮影ボタンを押します。
3.  `viewModel.registerFace()`が呼ばれ、画像から顔特徴量が抽出されます。
4.  抽出されたデータが`SecurityService`を通じて保存されます。
5.  保存成功後、完了画面が表示され、アプリのメイン機能へ遷移可能になります。
