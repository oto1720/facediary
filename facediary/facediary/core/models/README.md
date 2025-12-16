# Core Models

## Overview
アプリケーション全体で使用されるデータモデルを定義するディレクトリです。
これらのモデルは、`Codable` に準拠しており、JSON形式での保存や読み込みに対応しています。

## Models

### DiaryEntry.swift
*   **DiaryEntry**
    *   日記の1エントリーを表す構造体。
    *   **Properties**:
        *   `id`: ユニークID (UUID)。
        *   `date`: 作成日時。
        *   `text`: 日記の本文。
        *   `photoData`: 撮影された写真のバイナリデータ。
        *   `moodScores`: 感情分析の結果（感情とスコアの辞書）。
        *   `primaryMood`: 最もスコアが高い主要な感情（算出プロパティ）。

### Mood.swift
*   **Mood**
    *   感情の種類を表す列挙型（String, CaseIterable, Codable）。
    *   **Cases**: `happiness`, `sadness`, `anger`, `surprise`, `calm`, `neutral`。
    *   **Properties**:
        *   `emoji`: 各感情に対応する絵文字を返します。

### FaceData.swift
*   **FaceData**
    *   顔認証に使用される参照データを表す構造体。
    *   **Properties**:
        *   `userID`: ユーザーID。
        *   `faceObservations`: Vision Frameworkから抽出された顔の特徴点データ（Data型）。
        *   `createdAt`: データ作成日時。
