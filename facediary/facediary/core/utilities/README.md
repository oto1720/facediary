# Core Utilities

## Overview
アプリケーション全体で再利用される定数、拡張機能、ヘルパークラスをまとめたディレクトリです。

## Files

### Constants.swift
*   **Constants**
    *   アプリ全体の設定値や定数を管理します。
    *   **Categories**:
        *   App Info (名前, Bundle ID)
        *   Face Recognition (閾値, 推奨登録数)
        *   Mood Analysis (閾値)
        *   Storage (Keychainキー, ファイル名)
        *   UI (アスペクト比, アニメーション時間)
        *   Date Formats

### Extensions.swift
*   標準ライブラリやSwiftUIの型に対する拡張機能。
*   **Date**: フォーマット変換、日付計算（`startOfDay`, `startOfMonth`など）。
*   **String**: 空文字判定、切り詰め処理。
*   **Color**: Hex文字列からの初期化、Moodに対応する色の取得。
*   **Array**: 日記エントリーのフィルタリングやグルーピング。
*   **View**: 特定の角のみを丸める`cornerRadius`拡張。

### Helpers.swift
*   特定の機能に特化したヘルパーメソッド群。
*   **ImageHelper**: `UIImage`と`Data`の変換、リサイズ処理。
*   **MoodAnalyzer**: 感情スコアの解析、主要感情の特定、ソート。
*   **DateHelper**: よく使う日付（今日、昨日、週初めなど）や日付範囲の生成。
*   **Validator**: 入力値（テキスト、画像データ）の検証ロジック。
*   **HapticFeedback**: 各種Haptic Feedback（Success, Error, Selectionなど）の実行ラッパー。
