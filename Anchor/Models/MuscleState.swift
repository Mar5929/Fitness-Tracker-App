//  MuscleState.swift
//  Anchor
//
//  Derived, NOT stored (DESIGN.md §3.5). Computed on the fly per muscle and fed
//  to the Balance dashboard and the Coach. This is a Phase 2 concern — the type
//  is sketched here so the shape is visible, but it is not computed in Phase 1.

import Foundation

enum VolumeStatus: String, Sendable {
    case under      // below MEV
    case inBand     // MEV ≤ v ≤ MAV (target)
    case over       // above MRV
    case unknown    // constants not yet set (current Phase 1 state)
}

/// Per-muscle rollup the Balance screen will show and the Coach will read.
struct MuscleState: Identifiable, Sendable {
    let muscle: String
    var weeklyVolume: Double
    var volumeStatus: VolumeStatus
    var readinessPct: Double
    var lastTrained: Date?

    var id: String { muscle }

    // TODO: Phase 2 — compute from SetLog history + MuscleGroup tuning constants
    // (DESIGN.md §5). Requires the OWNER TODO constants to be finalized first.
}
