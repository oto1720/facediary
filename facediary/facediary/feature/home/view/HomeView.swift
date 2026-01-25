import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingDiaryCreate = false
    @State private var showingSettings = false
    @State private var selectedTab = 0
    @State private var selectedEntry: DiaryEntry?
    @State private var showingDetail = false
    @State private var showingAlreadyExistsAlert = false

    // 今日の日記が存在するかチェック
    private var hasTodayEntry: Bool {
        viewModel.entryForDate(Date()) != nil
    }

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

            // Floating Tab Bar with FAB
            FloatingTabBar(
                selectedTab: $selectedTab,
                tabs: tabs,
                onCenterButtonTap: {
                    if hasTodayEntry {
                        showingAlreadyExistsAlert = true
                    } else {
                        showingDiaryCreate = true
                    }
                },
                centerButtonDisabled: hasTodayEntry
            )
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    // MARK: - Tab Views

    private var diaryListTab: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("読み込み中...")
                        .tint(Color.appAccent)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // カレンダー
                            CalendarView(viewModel: viewModel) { entry in
                                selectedEntry = entry
                                showingDetail = true
                            }

                            // 最近の日記セクション
                            if !viewModel.diaryEntries.isEmpty {
                                recentEntriesSection
                            }
                        }
                        .padding(.bottom, 120)
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
            .alert("今日の日記", isPresented: $showingAlreadyExistsAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("今日の日記は既に作成されています")
            }
            .navigationDestination(isPresented: $showingDetail) {
                if let entry = selectedEntry {
                    DiaryEntryDetailView(entry: entry)
                }
            }
        }
    }

    // MARK: - Recent Entries Section

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近の日記")
                .font(.headline)
                .foregroundColor(Color.appTextPrimary)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(viewModel.diaryEntries.prefix(3)) { entry in
                    Button {
                        selectedEntry = entry
                        showingDetail = true
                    } label: {
                        DiaryEntryRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Diary Entry Row

struct DiaryEntryRow: View {
    let entry: DiaryEntry

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let primaryMood = entry.primaryMood {
                Text(primaryMood.emoji)
                    .font(.system(size: 32))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(Color.appTextSecondary)

                Text(entry.text)
                    .font(.subheadline)
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color.appTextSecondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
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
