//  PlaceholderViews.swift
//  Anchor
//
//  Clean stubs for later phases (phase-1-spec §8). The tab structure is visible
//  but nothing is half-built. Each notes the phase that fills it in.

import SwiftUI

struct PhaseStubView: View {
    let title: String
    let systemImage: String
    let phase: String
    let blurb: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label(title, systemImage: systemImage)
            } description: {
                VStack(spacing: 8) {
                    Text(blurb)
                    Text(phase).font(.caption).foregroundStyle(.tertiary)
                }
            }
            .navigationTitle(title)
        }
    }
}

struct BalanceView: View {
    // TODO: Phase 2 — per-muscle volume vs. MEV/MAV/MRV band + readiness bars,
    // computed from SetLog history (DESIGN.md §5). Needs the OWNER TODO tuning
    // constants finalized first.
    var body: some View {
        PhaseStubView(
            title: "Balance",
            systemImage: "chart.bar.xaxis",
            phase: "Phase 2",
            blurb: "Your per-muscle over/under-training ledger will live here."
        )
    }
}

struct TodayView: View {
    // TODO: Phase 3 — tap to generate today's session via Claude, review/swap/
    // accept with clinical-constraint awareness (DESIGN.md §6, §7).
    var body: some View {
        PhaseStubView(
            title: "Today",
            systemImage: "figure.run",
            phase: "Phase 3",
            blurb: "Generate and tweak today's full-body session here."
        )
    }
}

struct CoachView: View {
    // TODO: Phase 4 — Coach Agent chat + buttons over the tool layer, with
    // auto/confirm tiers, change-undo log, and clinical deferral (DESIGN.md §7b).
    var body: some View {
        PhaseStubView(
            title: "Coach",
            systemImage: "bubble.left.and.bubble.right",
            phase: "Phase 4",
            blurb: "Talk to your training coach here — it manages the plan within your limits."
        )
    }
}
