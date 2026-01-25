import SwiftUI

/// Diary entry create view
struct DiaryEntryCreateView: View {
    @StateObject private var viewModel = DiaryEntryViewModel()
    @Environment(\.dismiss) var dismiss

    /// Completion handler
    var onComplete: (() -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.capturedPhotoData == nil {
                    // Camera view
                    cameraView
                } else {
                    // Diary input view
                    diaryInputView
                }

                // Processing indicator
                if viewModel.isProcessing {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    ProgressView("処理中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                }
            }
            .navigationTitle("日記を書く")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .onChange(of: viewModel.saveSucceeded) { succeeded in
                if succeeded {
                    onComplete?()
                    dismiss()
                }
            }
        }
        .onAppear {
            viewModel.startCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
    }

    // MARK: - Subviews

    private var cameraView: some View {
        ZStack {
            // Camera preview
            if let session = viewModel.cameraService.previewLayer.session {
                CameraPreviewView(session: session)
                    .ignoresSafeArea()
            }

            VStack {
                Spacer()

                // Mood selection
                VStack(spacing: 8) {
                    Text("写真を撮影")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("今の気持ちを写真に残しましょう")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(15)
                .padding(.bottom, 20)

                // Capture photo button
                Button(action: {
                    viewModel.capturePhoto()
                }) {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 4)
                            .frame(width: 70, height: 70)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private var diaryInputView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo preview
                if let photoData = viewModel.capturedPhotoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipped()
                        .cornerRadius(15)
                        .padding(.horizontal)
                }

                // Mood selector (always shown)
                moodSelectorView

                // Diary text input
                VStack(alignment: .leading, spacing: 8) {
                    Text("日記")
                        .font(.headline)
                        .padding(.horizontal)

                    TextEditor(text: $viewModel.diaryText)
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                // Save diary button
                Button(action: {
                    viewModel.saveDiary { _ in }
                }) {
                    Text("保存")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.top)
        }
    }

    private var moodSelectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今の気分")
                .font(.headline)
                .padding(.horizontal)

            Text("今の気持ちに近いものを選んでください")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Mood.allCases, id: \.self) { mood in
                        moodCard(mood: mood)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func moodCard(mood: Mood) -> some View {
        VStack(spacing: 8) {
            Text(mood.emoji)
                .font(.system(size: 40))
            Text(mood.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding()
        .frame(width: 100)
        .background(
            viewModel.selectedMood == mood
                ? Color.color(for: mood).opacity(0.3)
                : Color(.systemGray6)
        )
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    viewModel.selectedMood == mood
                        ? Color.color(for: mood)
                        : Color.clear,
                    lineWidth: 2
                )
        )
        .onTapGesture {
            viewModel.updateMood(mood)
        }
    }
}

struct DiaryEntryCreateView_Previews: PreviewProvider {
    static var previews: some View {
        DiaryEntryCreateView()
    }
}
