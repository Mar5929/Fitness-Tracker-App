//  LogStore.swift
//  Anchor
//
//  Logic for the Log screen: pick a parser, parse text, resolve names to library
//  Exercises, insert SetLogs, and support a one-shot Undo of the last capture.
//  Kept out of the View so the parsing/resolution flow is testable.

import Foundation
import SwiftData

@Observable
@MainActor
final class LogStore {
    /// Result of a capture, used to drive the glanceable confirmation banner.
    struct Confirmation: Identifiable {
        let id = UUID()
        let summary: String
        let usedClaude: Bool
        let hadUnresolved: Bool
    }

    private let context: ModelContext

    /// Sets inserted by the most recent capture — the Undo target.
    private(set) var lastBatch: [SetLog] = []

    var confirmation: Confirmation?
    var isWorking = false
    var errorMessage: String?

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Capture

    /// Parse `text`, write SetLogs, and surface a confirmation. Uses the Claude
    /// parser when an API key is present, silently falling back to the on-device
    /// mock otherwise (or on any network error).
    func capture(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        let known = knownExerciseNames()
        var usedClaude = false
        var parsed: [ParsedSetLog]

        if KeychainStore.hasAPIKey {
            do {
                parsed = try await ClaudeSetLogParser(knownExerciseNames: known).parse(trimmed)
                usedClaude = true
            } catch {
                // Silent fallback — the app must always work offline.
                parsed = (try? await MockSetLogParser(knownExerciseNames: known).parse(trimmed)) ?? []
            }
        } else {
            parsed = (try? await MockSetLogParser(knownExerciseNames: known).parse(trimmed)) ?? []
        }

        guard !parsed.isEmpty else {
            errorMessage = "Couldn't find a movement in that. Try e.g. \"3 sets of calf raises\"."
            return
        }

        let inserted = parsed.map { insert($0) }
        do {
            try context.save()
        } catch {
            errorMessage = "Couldn't save: \(error.localizedDescription)"
            return
        }

        lastBatch = inserted
        confirmation = Confirmation(
            summary: Self.summary(for: inserted),
            usedClaude: usedClaude,
            hadUnresolved: inserted.contains { $0.isUnresolved }
        )
    }

    /// Remove the sets inserted by the most recent capture.
    func undoLast() {
        guard !lastBatch.isEmpty else { return }
        for log in lastBatch { context.delete(log) }
        try? context.save()
        lastBatch = []
        confirmation = nil
    }

    func dismissConfirmation() {
        confirmation = nil
    }

    // MARK: - Resolution / insertion

    private func insert(_ p: ParsedSetLog) -> SetLog {
        let match = resolveExercise(named: p.exerciseName)
        let log = SetLog(
            exercise: match,
            exerciseNameSnapshot: match?.name ?? p.exerciseName,
            timestamp: .now,
            sets: p.sets,
            reps: p.reps,
            load: p.load,
            effort: p.effort,
            source: p.source,
            rawText: p.rawText
        )
        context.insert(log)
        return log
    }

    /// Match a parsed name to a library Exercise: exact (case-insensitive) first,
    /// then a contains match either direction. nil → logs as an unresolved row.
    private func resolveExercise(named raw: String) -> Exercise? {
        let needle = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return nil }
        let all = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []

        if let exact = all.first(where: { $0.name.lowercased() == needle }) {
            return exact
        }
        return all.first { ex in
            let n = ex.name.lowercased()
            return n.contains(needle) || needle.contains(n)
        }
    }

    private func knownExerciseNames() -> [String] {
        let all = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        return all.map(\.name)
    }

    // MARK: - Display

    static func summary(for logs: [SetLog]) -> String {
        let parts = logs.map { log -> String in
            let muscle = log.exercise?.primaryMuscles.first?.displayName
                ?? (log.isUnresolved ? "unrecognized" : "—")
            return "\(log.sets)× \(log.exerciseNameSnapshot) (\(muscle))"
        }
        return "Logged: " + parts.joined(separator: ", ")
    }
}
