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
                    Label("日記", systemImage: "book")
                }
                .tag(0)

            AnalyticsView()
                .tabItem {
                    Label("分析", systemImage: "chart.bar")
                }
                .tag(1)
        }
        .tint(Color.appAccent)
    }

    // MARK: - Tab Views

    private var diaryListTab: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                VStack {
                    if viewModel.isLoading {
                        ProgressView("読み込み中...")
                            .tint(Color.appAccent)
                    } else if viewModel.diaryEntries.isEmpty {
                        emptyStateView
                    } else {
                        diaryListView
                    }
                }
            }
            .navigationTitle("FaceDiary")
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundColor(Color.AppColors.textPrimary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingDiaryCreate = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.AppColors.textPrimary)
                    }
                }
            }
            .toolbarBackground(Color.appSurface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
                .foregroundColor(Color.appTextSecondary)

            Text("日記がまだありません")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.appTextPrimary)

            Text("+ボタンをタップして\n今日の気分を記録しましょう")
                .font(.body)
                .foregroundColor(Color.appTextSecondary)
                .multilineTextAlignment(.center)

            Button(action: {
                showingDiaryCreate = true
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("日記を作成")
                }
                .font(.headline)
                .foregroundColor(Color.appSurface)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(Color.appAccent)
                .cornerRadius(25)
                .shadow(color: Color.AppColors.shadow, radius: 5)
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
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: viewModel.deleteDiaryEntry)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
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
                    .foregroundColor(Color.appTextSecondary)

                Text(entry.text)
                    .font(.body)
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.appSurface)
        .cornerRadius(12)
        .shadow(color: Color.AppColors.shadow, radius: 2, x: 0, y: 1)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
