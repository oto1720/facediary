# Core Services

## Overview
アプリケーションのビジネスロジックや外部システム（カメラ、ファイルシステム、Keychain、Vision Framework）とのやり取りをカプセル化するサービスクラス群です。
各サービスはプロトコルによって抽象化されており、テスト容易性と疎結合性を高めています。

## Services

### AnalyticsService.swift
*   **AnalyticsService**
    *   日記データに基づいた統計情報の計算を行います。
    *   **Functions**:
        *   `calculateStatistics`: 全体的な統計（総数、頻出感情など）を計算。
        *   `getMoodTrend`: 指定期間の感情推移データを生成。

### CameraService.swift
*   **CameraService**
    *   `AVFoundation` を使用したカメラ制御を行います。
    *   **Features**:
        *   フロントカメラのセットアップ。
        *   リアルタイム映像フレームの配信 (`framePublisher`)。
        *   写真撮影とデータ配信 (`photoPublisher`)。

### DataPersistenceService.swift
*   **DataPersistenceService**
    *   日記データの永続化を担当します。
    *   **Implementation**: `FileSystemDataPersistenceService` はJSONファイルとしてドキュメントディレクトリに保存します。
    *   **Functions**:
        *   `save`: 日記エントリーの配列を保存。
        *   `load`: 保存された日記エントリーを読み込み。

### FaceRecognitionService.swift
*   **FaceRecognitionService**
    *   `Vision` Frameworkを使用した顔認識と感情分析を行います。
    *   **Functions**:
        *   `generateFaceData`: 画像から顔の特徴点を抽出し、登録用データを生成。
        *   `recognizeFace`: 画像と登録データを照合し、認証結果と感情スコアを返します。

### SecurityService.swift
*   **SecurityService**
    *   機密情報（顔データ）の安全な管理を行います。
    *   **Implementation**: `KeychainSecurityService` はiOS Keychainを使用します。
    *   **Functions**:
        *   `save`: 顔データをKeychainに保存。
        *   `loadFaceData`: Keychainから顔データを取得。
        *   `deleteFaceData`: 顔データを削除。
