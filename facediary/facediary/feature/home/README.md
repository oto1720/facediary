# Home Feature

## Overview
アプリのメイン画面であり、日記一覧と分析画面へのナビゲーションを提供します。
ユーザーが作成した日記エントリーを時系列で表示し、詳細画面や作成画面への遷移を管理します。

## Components

### Views
*   **HomeView.swift**
    *   `TabView`を使用して「Diary」と「Analytics」の2つの主要セクションを切り替えます。
    *   `NavigationStack`を持ち、画面遷移のルートとなります。
    *   日記がない場合のEmpty State表示も担当します。
*   **DiaryEntryRow.swift**
    *   リスト内の各日記エントリーの行を表示するサブビューです。
    *   主要な感情（絵文字）、日付、本文の抜粋を表示します。

### ViewModels
*   **HomeViewModel.swift**
    *   **責務**: 日記データの読み込みとリスト管理。
    *   **主要プロパティ**:
        *   `diaryEntries`: 表示する日記エントリーの配列。
        *   `isLoading`: 読み込み中フラグ。
    *   **主要メソッド**:
        *   `loadDiaryEntries()`: 永続化層から日記データを非同期で読み込みます。
        *   `deleteDiaryEntry(at:)`: 指定されたエントリーを削除します。
    *   **依存サービス**:
        *   `DataPersistenceService`: データの保存と読み込み。

## Flow
1.  `HomeView`が表示されると、`viewModel.loadDiaryEntries()`が呼ばれます。
2.  データ読み込み中はローディングインジケータが表示されます。
3.  データ取得後、リストが表示されます。
4.  「+」ボタンで`DiaryEntryCreateView`がモーダル表示されます。
5.  日記作成完了後、コールバックを受け取りリストを再読み込みします。
