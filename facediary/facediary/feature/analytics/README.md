# Analytics Feature

## Overview
ユーザーの日記データに基づいて、感情の傾向や統計情報を可視化する機能です。
期間（週、月、年）ごとのフィルタリングや、感情分布のグラフ表示を提供します。

## Components

### Views
*   **AnalyticsView.swift**
    *   統計情報を表示するダッシュボードです。
    *   **Overall Statistics**: 総エントリー数、1日あたりの平均エントリー数、最も頻繁な感情を表示。
    *   **Mood Distribution**: 感情ごとの割合をバーチャートで表示。
    *   **Mood Trend**: カレンダー形式で日ごとの感情推移を表示。
    *   **Period Selector**: 分析期間（Week, Month, Year）の切り替えUI。

### ViewModels
*   **AnalyticsViewModel.swift**
    *   **責務**: 統計データの計算と表示用データの準備。
    *   **主要プロパティ**:
        *   `statistics`: 計算された統計情報（`MoodStatistics`）。
        *   `moodTrend`: 日付ごとの感情データ。
        *   `selectedPeriod`: 現在選択されている分析期間。
    *   **主要メソッド**:
        *   `loadData()`: 日記データを読み込み、統計を計算します。
        *   `updatePeriod(_:)`: 期間を変更し、トレンドデータを再計算します。
    *   **依存サービス**:
        *   `AnalyticsService`: 統計計算ロジック。
        *   `DataPersistenceService`: データ読み込み。

## Flow
1.  `AnalyticsView`が表示されると、`viewModel.loadData()`が呼ばれます。
2.  `DataPersistenceService`から全日記データを取得します。
3.  `AnalyticsService`を使用して、統計情報とトレンドデータを計算します。
4.  計算結果がUIに反映されます。
5.  ユーザーが期間を変更すると、`viewModel.updatePeriod()`が呼ばれ、表示が更新されます。
