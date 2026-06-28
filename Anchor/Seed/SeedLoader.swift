//  SeedLoader.swift
//  Anchor
//
//  Fills the MuscleGroup + Exercise tables from the bundled seed.json on first
//  launch (phase-1-spec §4). Idempotent: a no-op once the store is populated.
//  seed.json is the generated artifact; exercise-library.md stays the source.

import Foundation
import SwiftData

// MARK: - Decodable mirror of seed.json

private struct SeedFile: Decodable {
    let version: Int
    let muscleGroups: [SeedMuscle]
    let exercises: [SeedExercise]
}

private struct SeedMuscle: Decodable {
    let name: String
    let displayName: String
    let tau: Double
    let mev: Int
    let mav: Int
    let mrv: Int
}

private struct SeedExercise: Decodable {
    let name: String
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let equivalenceClass: String
    let pattern: String
    let clinicalTags: [String]
    let defaultEffort: String
    let notes: String?
}

enum SeedLoaderError: Error {
    case resourceMissing
}

enum SeedLoader {
    /// Insert seed rows if the store is empty. Safe to call on every launch.
    static func loadIfNeeded(into context: ModelContext) throws {
        let existing = try context.fetchCount(FetchDescriptor<MuscleGroup>())
        guard existing == 0 else { return }
        try load(into: context)
    }

    static func load(into context: ModelContext) throws {
        guard let url = Bundle.main.url(forResource: "seed", withExtension: "json") else {
            throw SeedLoaderError.resourceMissing
        }
        let data = try Data(contentsOf: url)
        let seed = try JSONDecoder().decode(SeedFile.self, from: data)

        // 1) Muscle groups first, indexed by canonical name for wiring up below.
        var muscleByName: [String: MuscleGroup] = [:]
        for m in seed.muscleGroups {
            let group = MuscleGroup(
                name: m.name,
                displayName: m.displayName,
                tau: m.tau,
                mev: m.mev,
                mav: m.mav,
                mrv: m.mrv
            )
            context.insert(group)
            muscleByName[m.name] = group
        }

        // 2) Exercises, linking to the inserted muscle groups.
        for e in seed.exercises {
            let exercise = Exercise(
                name: e.name,
                equivalenceClass: e.equivalenceClass,
                pattern: MovementPattern(seed: e.pattern),
                clinicalTags: e.clinicalTags,
                defaultEffort: Effort(rawValue: e.defaultEffort) ?? .medium,
                comfortRating: 3,
                notes: (e.notes?.isEmpty == true) ? nil : e.notes,
                primaryMuscles: e.primaryMuscles.compactMap { muscleByName[$0] },
                secondaryMuscles: e.secondaryMuscles.compactMap { muscleByName[$0] }
            )
            context.insert(exercise)
        }

        try context.save()
    }
}
