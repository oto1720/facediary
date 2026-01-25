import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingDiaryCreate = false
    @State private var showingSettings = false
    @State private var selectedTab = 0

    private let tabs = [
        TabItem(id: 0, icon: "book", title: "日記"),
        TabItem(id: 1, icon: "chart.bar", title: "分析")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            Group {
                switch selectedTab {
                case 0:
                    diaryListTab
                        .transition(.opacity)
                case 1:
                    AnalyticsView()
                        .transition(.opacity)
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            .ignoresSafeArea(.container, edges: .bottom)

            // Floating Tab Bar
            FloatingTabBar(selectedTab: $selectedTab, tabs: tabs)
                .ignoresSafeArea(.container, edges: .bottom)
        }
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
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingDiaryCreate) {
                DiaryEntryCreateView(onComplete: {
                    viewModel.loadDiaryEntries()
                })
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
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
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 80) // Floating tab bar spacing
        }
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
