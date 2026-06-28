//  Workout.swift
//  Anchor
//
//  A session (DESIGN.md §3.4): ordered planned exercises + the SetLogs attached
//  to it. Phase 1 only needs the type to exist — ad-hoc logging does not require
//  a Workout. Generation/attachment is Phase 3.

import Foundation
import SwiftData

@Model
final class Workout {
    var date: Date
    var title: String?

    /// Which constraint-set version this session was built under (DESIGN.md §7).
    /// Phase 1: unused, kept for forward compatibility.
    var constraintVersion: String?

    /// Deleting a session detaches its sets rather than destroying the record.
    @Relationship(deleteRule: .nullify)
    var setLogs: [SetLog] = []

    init(date: Date = .now, title: String? = nil, constraintVersion: String? = nil) {
        self.date = date
        self.title = title
        self.constraintVersion = constraintVersion
    }
}
