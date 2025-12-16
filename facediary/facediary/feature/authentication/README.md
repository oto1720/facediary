# Authentication Feature

## Overview
ユーザーの顔認証を行い、アプリへのアクセスを制御する機能です。
Core機能として提供される`CameraService`と`FaceRecognitionService`を使用して、リアルタイムでの顔検出と照合を行います。

## Components

### Views
*   **AuthenticationView.swift**
    *   カメラプレビューを表示し、認証プロセスを視覚化します。
    *   `AuthenticationState`に基づいて、スキャン中、処理中、成功、失敗のUIを切り替えます。
    *   成功時にコールバックを実行し、画面遷移をトリガーします。

### ViewModels
*   **AuthenticationViewModel.swift**
    *   **責務**: 認証プロセスの制御と状態管理。
    *   **主要プロパティ**:
        *   `authenticationState`: 現在の認証状態（ready, scanning, processing, success, failed）。
    *   **主要メソッド**:
        *   `startCamera()`: カメラセッションを開始します。
        *   `authenticate()`: 現在のフレームをキャプチャし、登録済みの顔データと照合します。
    *   **依存サービス**:
        *   `CameraService`: カメラ映像の取得。
        *   `FaceRecognitionService`: 顔の特徴量抽出と照合。
        *   `SecurityService`: 参照用顔データの読み込み。

## Flow
1.  `AuthenticationView`が表示されると、`viewModel.startCamera()`が呼ばれます。
2.  ユーザーが「認証」ボタンを押すか、自動的にスキャンが開始されます（現在はボタン操作）。
3.  `viewModel.authenticate()`が実行され、現在のカメラフレームが`FaceRecognitionService`に送られます。
4.  照合結果に基づいて`authenticationState`が更新され、UIに反映されます。
