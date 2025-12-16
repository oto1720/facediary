import SwiftUI

/// Diary entry detail view
struct DiaryEntryDetailView: View {
    let entry: DiaryEntry

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Date and time
                HStack {
                    Text(entry.date.formatted(as: Constants.dateFormat))
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Text(entry.date.formatted(as: Constants.timeFormat))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                    .padding(.horizontal)

                // Diary text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Diary Entry")
                        .font(.headline)
                    Text(entry.text)
                        .font(.body)
                        .lineSpacing(4)
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .navigationTitle("Diary Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            Text("Edit Diary Entry")
        }
        .alert("Delete Diary Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                // Delete diary entry
            }
        } message: {
            Text("Are you sure you want to delete this diary entry?")
        }
    }

    // MARK: - Subviews

    private var moodSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood")
                .font(.headline)
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
                Text("Mood Scores")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
            Spacer()
            Text(MoodAnalyzer.percentageString(from: score))
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Mood score bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
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
                    text: "Diary Entry",
                    photoData: nil,
                    moodScores: [.happiness: 0.8, .calm: 0.2]
                )
            )
        }
    }
}
