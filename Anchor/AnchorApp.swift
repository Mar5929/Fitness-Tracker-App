//  AnchorApp.swift
//  Anchor
//
//  App entry. Builds the SwiftData container over the full model graph and seeds
//  the library on first launch.

import SwiftUI
import SwiftData

@main
struct AnchorApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                MuscleGroup.self,
                Exercise.self,
                SetLog.self,
                Workout.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Seed on first launch (idempotent).
        do {
            try SeedLoader.loadIfNeeded(into: container.mainContext)
        } catch {
            // Non-fatal: the app still runs; the library is just empty.
            print("Seed load failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
