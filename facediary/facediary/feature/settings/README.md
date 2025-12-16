# Settings Feature

## Overview
アプリの設定、データ管理、アプリ情報の表示を行う機能です。
ユーザーデータの削除やエクスポート、顔認証データのリセットなどの管理機能を提供します。

## Components

### Views
*   **SettingsView.swift**
    *   リスト形式の設定画面。
    *   **App Info**: アプリ名とバージョン情報の表示。
    *   **Data Management**:
        *   日記データのエクスポート（JSON形式）。
        *   全日記データの削除（確認アラート付き）。
    *   **Security**:
        *   顔データの削除（リセット）。
    *   **About**: プライバシーポリシーと利用規約へのリンク。

### ViewModels
*   **SettingsViewModel.swift**
    *   **責務**: 設定アクションの実行。
    *   **主要メソッド**:
        *   `deleteFaceData()`: セキュリティサービスを通じて顔データを削除します。
        *   `deleteAllDiaries()`: 永続化サービスを通じて全日記を削除（空リストで上書き）します。
        *   `exportDiaries()`: 日記データをJSON文字列に変換して返します。
        *   `getAppVersion()`: バンドル情報からバージョンを取得します。
    *   **依存サービス**:
        *   `SecurityService`: 顔データの削除。
        *   `DataPersistenceService`: 日記データの操作。

## Flow
1.  ユーザーがアクション（例：データ削除）を選択します。
2.  破壊的な操作の場合、確認アラートが表示されます。
3.  確認後、ViewModelのメソッドが実行されます。
4.  操作の成功/失敗に応じて、Haptic Feedbackとメッセージが表示されます。
