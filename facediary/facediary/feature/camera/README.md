# Camera Feature

## Overview
アプリ全体で使用されるカメラ機能の基盤を提供します。
`AVFoundation`を使用したカメラセッションの管理と、プレビュー表示を行います。

## Components

### Views
*   **CameraPreviewView.swift**
    *   `AVCaptureVideoPreviewLayer`をSwiftUIで表示するための`UIViewRepresentable`ラッパーです。
    *   カメラからの映像ストリームを画面に描画します。
    *   `AuthenticationView`や`DiaryEntryCreateView`など、カメラを使用する全ての画面で再利用されます。

### Services (Core)
*   **CameraService.swift** (Located in Core/Services)
    *   **責務**: `AVCaptureSession`のセットアップ、開始、停止、写真撮影。
    *   **主要機能**:
        *   フロントカメラの入力設定。
        *   ビデオデータ出力（リアルタイムフレーム処理用）の設定。
        *   写真出力の設定。
        *   `framePublisher`: 映像フレームをCombineストリームとして配信。
        *   `photoPublisher`: 撮影された写真をCombineストリームとして配信。

## Usage
この機能は単独で使用される画面（`CameraView`）を持つというよりは、他の機能（Authentication, DiaryEntry, Onboarding）に対してカメラ機能を提供するインフラストラクチャとしての役割が強いです。
各機能のViewModelは`CameraService`のインスタンスを持ち、Viewは`CameraPreviewView`を使用して映像を表示します。
