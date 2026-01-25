import SwiftUI

/// Diary entry detail view
struct DiaryEntryDetailView: View {
    let entry: DiaryEntry

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Date and time
                    HStack {
                        Text(entry.date.formatted(as: Constants.dateFormat))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.appTextPrimary)
                        Spacer()
                        Text(entry.date.formatted(as: Constants.timeFormat))
                            .font(.subheadline)
                            .foregroundColor(Color.appTextSecondary)
                    }
                    .padding(.horizontal)

                    // Photo preview
                    if let photoData = entry.photoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .clipped()
                            .cornerRadius(15)
                            .padding(.horizontal)
                    }

                    // Mood section
                    moodSectionView

                    Divider()
                        .background(Color.appBorder)
                        .padding(.horizontal)

                    // Diary text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("日記")
                            .font(.headline)
                            .foregroundColor(Color.appTextPrimary)
                        Text(entry.text)
                            .font(.body)
                            .foregroundColor(Color.appTextPrimary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
        }
        .navigationTitle("日記の詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Label("編集", systemImage: "pencil")
                    }

                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Color.appTextPrimary)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            Text("日記を編集")
        }
        .alert("日記を削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                // Delete diary entry
            }
        } message: {
            Text("この日記を削除してもよろしいですか？")
        }
    }

    // MARK: - Subviews

    private var moodSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("気分")
                .font(.headline)
                .foregroundColor(Color.appTextPrimary)
                .padding(.horizontal)

            if let primaryMood = entry.primaryMood {
                HStack {
                    // Mood section
                    VStack {
                        Text(primaryMood.emoji)
                            .font(.system(size: 50))
                        Text(primaryMood.rawValue)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.appTextPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.color(for: primaryMood).opacity(0.2))
                    .cornerRadius(15)

                    Spacer()
                }
                .padding(.horizontal)
            }

            // Mood scores
            if entry.moodScores.count > 1 {
                Text("気分スコア")
                    .font(.subheadline)
                    .foregroundColor(Color.appTextSecondary)
                    .padding(.horizontal)

                let sortedMoods = MoodAnalyzer.sortedMoods(from: entry.moodScores)
                VStack(spacing: 8) {
                    ForEach(sortedMoods, id: \.mood) { item in
                        moodScoreRow(mood: item.mood, score: item.score)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func moodScoreRow(mood: Mood, score: Double) -> some View {
        HStack {
            Text(mood.emoji)
                .font(.title2)
            Text(mood.rawValue)
                .font(.body)
                .foregroundColor(Color.appTextPrimary)
            Spacer()
            Text(MoodAnalyzer.percentageString(from: score))
                .font(.subheadline)
                .foregroundColor(Color.appTextSecondary)

            // Mood score bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appBackgroundSecondary)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.color(for: mood))
                        .frame(width: geometry.size.width * CGFloat(score), height: 8)
                }
            }
            .frame(width: 60, height: 8)
        }
        .padding(.vertical, 4)
    }
}

struct DiaryEntryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DiaryEntryDetailView(
                entry: DiaryEntry(
                    date: Date(),
                    text: "今日はとても良い一日でした。",
                    photoData: nil,
                    moodScores: [.happiness: 0.8, .calm: 0.2]
                )
            )
        }
    }
}
