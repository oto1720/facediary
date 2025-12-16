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
                    ProgressView("Processing...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Diary Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
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
                    Text("Mood Selection")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Select your mood from the list")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(15)
                .padding(.bottom, 20)

                // Capture photo button
                Button(action: {
                    viewModel.capturePhotoAndAnalyze()
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

                // Mood selector
                if !viewModel.moodScores.isEmpty {
                    moodSelectorView
                }

                // Diary text input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Diary Entry")
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
                    Text("Save")
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
            Text("Mood Selection")
                .font(.headline)
                .padding(.horizontal)

            // Mood list
            let sortedMoods = MoodAnalyzer.sortedMoods(from: viewModel.moodScores)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sortedMoods, id: \.mood) { item in
                        moodCard(mood: item.mood, score: item.score)
                    }
                }
                .padding(.horizontal)
            }

            // Mood explanation
            Text("Select the mood that best describes your current mood")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Mood.allCases, id: \.self) { mood in
                        Button(action: {
                            viewModel.updateMood(mood)
                        }) {
                            VStack {
                                Text(mood.emoji)
                                    .font(.system(size: 30))
                                Text(mood.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            .padding(8)
                            .background(
                                viewModel.selectedMood == mood
                                    ? Color.blue.opacity(0.2)
                                    : Color(.systemGray6)
                            )
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        viewModel.selectedMood == mood
                                            ? Color.blue
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func moodCard(mood: Mood, score: Double) -> some View {
        VStack(spacing: 8) {
            Text(mood.emoji)
                .font(.system(size: 40))
            Text(mood.rawValue)
                .font(.caption)
                .fontWeight(.medium)
            Text(MoodAnalyzer.percentageString(from: score))
                .font(.caption2)
                .foregroundColor(.secondary)
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
