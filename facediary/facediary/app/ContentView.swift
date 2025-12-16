//
//  ContentView.swift
//  facediary
//
//  Created by 乙津孝太朗 on 2025/10/30.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()

    var body: some View {
        Group {
            switch appViewModel.appState {
            case .loading:
                // ローディング画面
                ProgressView("読み込み中...")
                    .progressViewStyle(CircularProgressViewStyle())

            case .onboarding:
                // 顔未登録 → オンボーディング画面
                FaceRegistrationView(onComplete: {
                    appViewModel.onFaceRegistrationCompleted()
                })

            case .authentication:
                // 顔登録済み → 認証画面
                AuthenticationView(onAuthenticationSuccess: {
                    appViewModel.onAuthenticationSucceeded()
                })

            case .authenticated:
                // 認証成功 → メイン画面
                HomeView()
                    .environmentObject(appViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
