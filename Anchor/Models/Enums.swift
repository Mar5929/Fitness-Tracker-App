//  Enums.swift
//  Anchor
//
//  Shared value enums used across the data model and parsing layer.
//  Stored on @Model types as raw String columns (SwiftData-friendly) with typed
//  accessors, so persisted values stay stable even if the enum evolves.

import Foundation

/// Effort proxy for intensity. We track effort, NOT reps and NOT heart rate.
/// (Heart-rate zones are unreliable for the owner — see DESIGN.md / propranolol note.)
enum Effort: String, CaseIterable, Codable, Identifiable, Sendable {
    case light
    case medium
    case hard

    var id: String { rawValue }

    var display: String {
        switch self {
        case .light: return "Light"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    /// Weight used by the (later-phase) recovery model. Defined here so there is
    /// a single source for it. Not used by the Phase 1 Log screen.
    var weight: Double {
        switch self {
        case .light: return 0.6
        case .medium: return 1.0
        case .hard: return 1.4
        }
    }
}

/// Where a set came from. Ad-hoc sets live outside a planned session but still
/// count toward the ledger.
enum SetSource: String, CaseIterable, Codable, Identifiable, Sendable {
    case planned
    case adhoc

    var id: String { rawValue }

    var display: String {
        switch self {
        case .planned: return "Planned"
        case .adhoc: return "Ad-hoc"
        }
    }
}

/// Movement pattern — used by the constraint rules in later phases.
enum MovementPattern: String, CaseIterable, Codable, Identifiable, Sendable {
    case squat
    case hinge
    case press
    case pull
    case isolation
    case carry
    case core
    case mobility
    case cardio

    var id: String { rawValue }

    /// Tolerant decode: unknown / missing patterns fall back to `.isolation`
    /// so a future seed value never crashes the loader.
    init(seed raw: String) {
        self = MovementPattern(rawValue: raw.lowercased()) ?? .isolation
    }
}
