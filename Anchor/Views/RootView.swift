//  RootView.swift
//  Anchor
//
//  The tab bar. Log is first because capture is the point (DESIGN.md §9).
//  Balance/Today/Coach are Phase 2–4 stubs; Settings holds the API key.

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            LogView()
                .tabItem { Label("Log", systemImage: "square.and.pencil") }

            BalanceView()
                .tabItem { Label("Balance", systemImage: "chart.bar.xaxis") }

            TodayView()
                .tabItem { Label("Today", systemImage: "figure.run") }

            CoachView()
                .tabItem { Label("Coach", systemImage: "bubble.left.and.bubble.right") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
