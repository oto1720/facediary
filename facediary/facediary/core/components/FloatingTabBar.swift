//
//  FloatingTabBar.swift
//  facediary
//
//  Created on 2025/01/25.
//

import SwiftUI

// MARK: - Tab Item Model

struct TabItem: Identifiable, Equatable {
    let id: Int
    let icon: String
    let selectedIcon: String
    let title: String

    init(id: Int, icon: String, selectedIcon: String? = nil, title: String) {
        self.id = id
        self.icon = icon
        self.selectedIcon = selectedIcon ?? "\(icon).fill"
        self.title = title
    }
}

// MARK: - Floating Tab Bar

struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]
    var onCenterButtonTap: (() -> Void)?
    var centerButtonDisabled: Bool = false

    @Namespace private var animation

    var body: some View {
        ZStack {
            // Tab Bar Background
            HStack(spacing: 0) {
                // Left tab
                if let leftTab = tabs.first {
                    TabButton(
                        tab: leftTab,
                        isSelected: selectedTab == leftTab.id,
                        animation: animation
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = leftTab.id
                        }
                    }
                }

                // Center spacer for FAB
                Spacer()
                    .frame(width: 70)

                // Right tab
                if tabs.count > 1 {
                    TabButton(
                        tab: tabs[1],
                        isSelected: selectedTab == tabs[1].id,
                        animation: animation
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tabs[1].id
                        }
                    }
                }
            }
            .frame(height: 50)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.AppColors.surface)
                    .shadow(color: Color.AppColors.shadow, radius: 12, x: 0, y: 4)
            )
            .padding(.horizontal, 40)

            // Center FAB Button
            if let onTap = onCenterButtonTap {
                Button(action: onTap) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: centerButtonDisabled
                                        ? [Color.gray.opacity(0.5), Color.gray.opacity(0.3)]
                                        : [Color.AppColors.accent, Color.AppColors.accent.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(
                                color: centerButtonDisabled
                                    ? Color.clear
                                    : Color.AppColors.accent.opacity(0.4),
                                radius: 8,
                                x: 0,
                                y: 4
                            )

                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .offset(y: -20)
                .buttonStyle(FABButtonStyle())
            }
        }
        .padding(.bottom, 16)
    }
}

// MARK: - FAB Button Style

private struct FABButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let animation: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .center) {
                if isSelected {
                    Capsule()
                        .fill(Color.AppColors.accent.opacity(0.15))
                        .matchedGeometryEffect(id: "background", in: animation)
                }

                HStack(spacing: 6) {
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? Color.AppColors.accent : Color.AppColors.textSecondary)
                        .scaleEffect(isSelected ? 1.1 : 1.0)

                    if isSelected {
                        Text(tab.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.AppColors.accent)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.8)),
                                removal: .opacity.combined(with: .scale(scale: 0.8))
                            ))
                    }
                }
                .padding(.horizontal, isSelected ? 16 : 12)
                .padding(.vertical, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .buttonStyle(TabButtonStyle())
    }
}

// MARK: - Tab Button Style

private struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTab = 0

        let tabs = [
            TabItem(id: 0, icon: "book", title: "日記"),
            TabItem(id: 1, icon: "chart.bar", title: "分析")
        ]

        var body: some View {
            ZStack(alignment: .bottom) {
                Color.AppColors.background
                    .ignoresSafeArea()

                VStack {
                    Text("Selected: \(selectedTab)")
                        .font(.largeTitle)
                    Spacer()
                }
                .padding(.top, 100)

                FloatingTabBar(
                    selectedTab: $selectedTab,
                    tabs: tabs,
                    onCenterButtonTap: {
                        print("FAB tapped!")
                    }
                )
            }
        }
    }

    return PreviewWrapper()
}
