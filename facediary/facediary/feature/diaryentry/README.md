# DiaryEntry Feature

## Overview
新しい日記を作成し、閲覧する機能です。
写真撮影による感情分析と、テキスト入力、気分の手動選択を組み合わせた日記作成フローを提供します。

## Components

### Views
*   **DiaryEntryCreateView.swift**
    *   日記作成のウィザード形式のUIを提供します。
    *   **Step 1**: カメラプレビューと撮影ボタン。
    *   **Step 2**: 撮影された写真、分析された感情スコア、テキスト入力フィールド。
    *   感情スコアに基づいた推奨ムードの選択UIを含みます。
*   **DiaryEntryDetailView.swift**
    *   作成済みの日記の詳細を表示します。
    *   写真、日付、感情、本文を表示します。

### ViewModels
*   **DiaryEntryViewModel.swift**
    *   **責務**: 日記作成フローの制御、写真撮影、感情分析、データ保存。
    *   **主要プロパティ**:
        *   `capturedPhotoData`: 撮影された写真データ。
        *   `moodScores`: 写真から分析された感情スコア。
        *   `diaryText`: 入力された日記本文。
    *   **主要メソッド**:
        *   `capturePhotoAndAnalyze()`: 写真を撮影し、自動的に感情分析を開始します。
        *   `saveDiary()`: 写真、感情、テキストをまとめて保存します。
    *   **依存サービス**:
        *   `CameraService`: 写真撮影。
        *   `FaceRecognitionService`: 感情分析（顔認識の一部として実装）。
        *   `DataPersistenceService`: 日記データの保存。

## Flow
1.  **撮影モード**: ユーザーは自分の顔を撮影します。
2.  **分析**: 撮影された画像から`FaceRecognitionService`が感情（Mood）を分析します。
3.  **編集モード**:
    *   分析結果の感情スコアが表示され、ユーザーは主要な感情を選択します。
    *   日記の本文を入力します。
4.  **保存**: 「Save」ボタンでデータが永続化され、ホーム画面に戻ります。
