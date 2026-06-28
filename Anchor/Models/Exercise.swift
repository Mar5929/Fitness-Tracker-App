//  Exercise.swift
//  Anchor
//
//  A movement in the library (DESIGN.md §3.2). Seeded from exercise-library.md
//  via seed.json.

import Foundation
import SwiftData

@Model
final class Exercise {
    /// Display name, e.g. "Resistance-band lateral walk". Unique.
    @Attribute(.unique) var name: String

    /// Full stimulus credit (×1.0).
    var primaryMuscles: [MuscleGroup] = []

    /// Partial credit (×0.5).
    var secondaryMuscles: [MuscleGroup] = []

    /// The swap pool for variety, e.g. "hip_abductor_iso". Same class →
    /// interchangeable (clamshells ↔ band lateral walks).
    var equivalenceClass: String

    /// Stored raw; access typed via `pattern`.
    var patternRaw: String

    /// Derived clinical constraint tags (e.g. "spine_neutral_req",
    /// "left_knee_priority"). See exercise-library.md legend.
    var clinicalTags: [String] = []

    /// Fallback effort when NL omits it. Stored raw; access via `defaultEffort`.
    var defaultEffortRaw: String

    /// Owner-set comfort 1–5; bias toward comfortable movements. Default 3.
    var comfortRating: Int

    /// Human-readable clinical / coaching note carried over from the library.
    var notes: String?

    var pattern: MovementPattern {
        get { MovementPattern(seed: patternRaw) }
        set { patternRaw = newValue.rawValue }
    }

    var defaultEffort: Effort {
        get { Effort(rawValue: defaultEffortRaw) ?? .medium }
        set { defaultEffortRaw = newValue.rawValue }
    }

    init(
        name: String,
        equivalenceClass: String,
        pattern: MovementPattern,
        clinicalTags: [String] = [],
        defaultEffort: Effort = .medium,
        comfortRating: Int = 3,
        notes: String? = nil,
        primaryMuscles: [MuscleGroup] = [],
        secondaryMuscles: [MuscleGroup] = []
    ) {
        self.name = name
        self.equivalenceClass = equivalenceClass
        self.patternRaw = pattern.rawValue
        self.clinicalTags = clinicalTags
        self.defaultEffortRaw = defaultEffort.rawValue
        self.comfortRating = comfortRating
        self.notes = notes
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
    }
}
