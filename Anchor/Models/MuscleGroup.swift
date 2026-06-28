//  MuscleGroup.swift
//  Anchor
//
//  The unit the whole app reasons in (DESIGN.md §3.1). A fixed taxonomy seeded
//  from docs/muscle-taxonomy.md (provisional 21-group set).

import Foundation
import SwiftData

@Model
final class MuscleGroup {
    /// Canonical id, e.g. "calves". Unique.
    @Attribute(.unique) var name: String

    /// Human-facing label, e.g. "Calves".
    var displayName: String

    // MARK: Tuning constants — OWNER TODO placeholders (DESIGN.md §5, §11).
    // Not used by the Phase 1 Log screen. Need evidence-grounded defaults
    // before the Phase 2 Balance ledger means anything.

    /// Recovery time-constant.
    var tau: Double
    /// Minimum effective volume (sets/week).
    var mev: Int
    /// Maximum adaptive volume (sets/week) — top of the target band.
    var mav: Int
    /// Maximum recoverable volume (sets/week).
    var mrv: Int

    // MARK: Inverse relationships (declared here; forward sides live on Exercise)

    @Relationship(inverse: \Exercise.primaryMuscles)
    var primaryOf: [Exercise] = []

    @Relationship(inverse: \Exercise.secondaryMuscles)
    var secondaryOf: [Exercise] = []

    init(
        name: String,
        displayName: String,
        tau: Double = 0,
        mev: Int = 0,
        mav: Int = 0,
        mrv: Int = 0
    ) {
        self.name = name
        self.displayName = displayName
        self.tau = tau
        self.mev = mev
        self.mav = mav
        self.mrv = mrv
    }
}
