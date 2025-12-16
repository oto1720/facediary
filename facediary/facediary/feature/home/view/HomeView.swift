import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingDiaryCreate = false
    @State private var showingSettings = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            diaryListTab
                .tabItem {
                    Label("Diary", systemImage: "book")
                }
                .tag(0)

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }
                .tag(1)
        }
    }

    // MARK: - Tab Views

    private var diaryListTab: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack {
                    if viewModel.isLoading {
                        ProgressView("Loading...")
                    } else if viewModel.diaryEntries.isEmpty {
                        emptyStateView
                    } else {
                        diaryListView
                    }
                }
            }
            .navigationTitle("FaceDiary")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingDiaryCreate = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingDiaryCreate) {
                DiaryEntryCreateView(onComplete: {
                    viewModel.loadDiaryEntries()
                })
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(onFaceDataDeleted: {
                    // Handle face data deletion if needed
                })
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.white.opacity(0.7))

            Text("No Diary Entries Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Tap the + button to record\nyour mood today")
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            Button(action: {
                showingDiaryCreate = true
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Create Diary")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(Color.blue)
                .cornerRadius(25)
                .shadow(radius: 5)
            }
            .padding(.top, 20)
        }
    }

    private var diaryListView: some View {
        List {
            ForEach(viewModel.diaryEntries) { entry in
                NavigationLink(destination: DiaryEntryDetailView(entry: entry)) {
                    DiaryEntryRow(entry: entry)
                }
            }
            .onDelete(perform: viewModel.deleteDiaryEntry)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Diary Entry Row View

struct DiaryEntryRow: View {
    let entry: DiaryEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let primaryMood = entry.primaryMood {
                Text(primaryMood.emoji)
                    .font(.system(size: 40))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(entry.text)
                    .font(.body)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
