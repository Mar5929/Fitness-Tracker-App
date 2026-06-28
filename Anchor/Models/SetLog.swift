//  SetLog.swift
//  Anchor
//
//  The atomic unit of capture (DESIGN.md §3.3). Intentionally tolerant of
//  missing data: reps and load are nullable, "didn't count" is first-class.

import Foundation
import SwiftData

@Model
final class SetLog {
    /// Resolved library movement. Nullable so an unresolved name still logs
    /// (we never block capture on a missing library match).
    @Relationship var exercise: Exercise?

    /// Name as captured/resolved — kept even if `exercise` is nil, so the row
    /// is always meaningful and survives library edits.
    var exerciseNameSnapshot: String

    var timestamp: Date

    /// Defaults to 1 if unstated.
    var sets: Int

    /// Nullable — "didn't count" is a first-class valid state. Never force a value.
    var reps: Int?

    /// Nullable — bodyweight / band / unknown all fine.
    var load: String?

    /// Stored raw; access via `effort`.
    var effortRaw: String

    /// Stored raw; access via `source`.
    var sourceRaw: String

    /// The original sentence, kept verbatim for audit.
    var rawText: String

    /// Owning session, if any. Ad-hoc sets have none.
    @Relationship(inverse: \Workout.setLogs) var workout: Workout?

    var effort: Effort {
        get { Effort(rawValue: effortRaw) ?? .medium }
        set { effortRaw = newValue.rawValue }
    }

    var source: SetSource {
        get { SetSource(rawValue: sourceRaw) ?? .adhoc }
        set { sourceRaw = newValue.rawValue }
    }

    init(
        exercise: Exercise?,
        exerciseNameSnapshot: String,
        timestamp: Date = .now,
        sets: Int = 1,
        reps: Int? = nil,
        load: String? = nil,
        effort: Effort = .medium,
        source: SetSource = .adhoc,
        rawText: String
    ) {
        self.exercise = exercise
        self.exerciseNameSnapshot = exerciseNameSnapshot
        self.timestamp = timestamp
        self.sets = sets
        self.reps = reps
        self.load = load
        self.effortRaw = effort.rawValue
        self.sourceRaw = source.rawValue
        self.rawText = rawText
    }

    /// True when the captured name could not be matched to a library Exercise.
    var isUnresolved: Bool { exercise == nil }
}
