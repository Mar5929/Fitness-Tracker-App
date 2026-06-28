//  MockSetLogParser.swift
//  Anchor
//
//  Default, on-device, no-network parser (phase-1-spec §6). Must be good enough
//  to demo logging "3 sets of calf raises and a few hard rows" with no API key.
//
//  Heuristic, deliberately simple: split into clauses, pull a set count and an
//  effort word out of each, then match the remaining words to a known library
//  movement by shared word-stems. Never invents reps.

import Foundation

struct MockSetLogParser: SetLogParser {
    /// Canonical library names this parser can resolve against. Passed in so the
    /// parser has no dependency on SwiftData.
    let knownExerciseNames: [String]

    func parse(_ text: String) async throws -> [ParsedSetLog] {
        let clauses = Self.splitClauses(text)
        return clauses.compactMap { Self.parseClause($0, known: knownExerciseNames) }
    }

    // MARK: - Clause splitting

    /// Break a sentence on commas and connectives ("and", "then", "&", "+").
    static func splitClauses(_ text: String) -> [String] {
        let lowered = text.lowercased()
        let separators: [String] = [",", " and ", " then ", " & ", " + ", ";"]
        var fragments = [lowered]
        for sep in separators {
            fragments = fragments.flatMap { $0.components(separatedBy: sep) }
        }
        return fragments
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Clause parsing

    static func parseClause(_ clause: String, known: [String]) -> ParsedSetLog? {
        let sets = extractSetCount(clause)
        let reps = extractReps(clause)
        let effort = extractEffort(clause)
        let resolvedName = resolveExerciseName(clause, known: known)

        // If we couldn't pull a recognizable movement out, drop the clause —
        // better to log nothing than a junk row. (Filler like "went pretty hard
        // on the" with no movement won't produce a set.)
        guard let name = resolvedName else { return nil }

        return ParsedSetLog(
            exerciseName: name,
            sets: sets,
            reps: reps,
            load: nil,
            effort: effort,
            source: .adhoc,
            rawText: clause
        )
    }

    // MARK: - Field extractors

    /// Quantity words and explicit counts → a set count. Defaults to 1.
    static func extractSetCount(_ clause: String) -> Int {
        // Explicit "3 sets", "3x", "3 x", "x3"
        if let n = firstInt(in: clause, patterns: [
            #"(\d+)\s*(?:sets?|x\b)"#,
            #"\bx\s*(\d+)"#
        ]) {
            return max(1, n)
        }
        // Quantity words
        let words: [(String, Int)] = [
            ("a couple of", 2), ("couple of", 2), ("a couple", 2), ("couple", 2),
            ("a few", 3), ("few", 3), ("several", 3), ("some", 2),
            ("a bunch of", 3), ("bunch of", 3),
            ("a", 1), ("an", 1), ("one", 1), ("two", 2), ("three", 3),
            ("four", 4), ("five", 5)
        ]
        for (w, n) in words where containsWord(clause, w) {
            return n
        }
        // A bare leading number ("3 calf raises")
        if let n = firstInt(in: clause, patterns: [#"^\s*(\d+)\b"#]) {
            return max(1, n)
        }
        return 1
    }

    /// Reps stay nil unless the user *explicitly* states them. "Didn't count" is
    /// the default and a valid first-class state — we never invent a number.
    static func extractReps(_ clause: String) -> Int? {
        firstInt(in: clause, patterns: [
            #"(\d+)\s*reps?\b"#,
            #"x\s*(\d+)\s*reps?\b"#
        ])
    }

    static func extractEffort(_ clause: String) -> Effort {
        let hard = ["hard", "heavy", "went hard", "burned out", "burnt out",
                    "tough", "brutal", "max", "all out", "all-out", "to failure", "intense"]
        let light = ["easy", "light", "easygoing", "gentle", "chill", "warm up",
                     "warm-up", "warmup", "barely"]
        for w in hard where clause.contains(w) { return .hard }
        for w in light where clause.contains(w) { return .light }
        return .medium
    }

    // MARK: - Exercise name resolution

    /// Match the clause to a known movement by shared word-stems. Returns the
    /// canonical library name, or the cleaned-up free text if nothing matches
    /// (so an unknown movement still logs as an unresolved row).
    static func resolveExerciseName(_ clause: String, known: [String]) -> String? {
        let clauseStems = Set(stems(from: clause))
        guard !clauseStems.isEmpty else { return nil }

        var best: (name: String, score: Int, wordCount: Int)?
        for name in known {
            let nameStems = stems(from: name)
            guard !nameStems.isEmpty else { continue }
            let overlap = nameStems.filter { clauseStems.contains($0) }.count
            guard overlap > 0 else { continue }
            // Prefer more overlap; break ties toward the more generic (fewer-word)
            // name so "calf raises" → "Calf raise", not "Single-leg calf raise".
            if let b = best {
                if overlap > b.score || (overlap == b.score && nameStems.count < b.wordCount) {
                    best = (name, overlap, nameStems.count)
                }
            } else {
                best = (name, overlap, nameStems.count)
            }
        }

        if let best { return best.name }

        // No library match — keep the user's words (minus quantities/effort) so
        // the set logs as an unresolved row rather than vanishing.
        let leftover = cleanedFreeText(clause)
        return leftover.isEmpty ? nil : leftover
    }

    /// Content-word stems of a string, with stop/quantity/effort words removed
    /// and a crude singularization (trailing "s"/"es" trimmed).
    static func stems(from text: String) -> [String] {
        let stop: Set<String> = [
            "of", "the", "a", "an", "some", "few", "couple", "several", "bunch",
            "set", "sets", "rep", "reps", "x", "and", "then", "did", "do", "done",
            "doing", "got", "get", "went", "go", "just", "today", "my", "for",
            "with", "on", "pretty", "really", "super", "very", "to", "i", "ive",
            "hard", "heavy", "easy", "light", "tough", "brutal", "max", "intense",
            "out", "burned", "burnt", "all", "warm", "warmup", "chill", "gentle",
            "one", "two", "three", "four", "five", "couple", "bit", "lil", "little"
        ]
        return tokenize(text)
            .map { singularize($0) }
            .filter { !$0.isEmpty && !stop.contains($0) && !$0.allSatisfy(\.isNumber) }
    }

    static func cleanedFreeText(_ clause: String) -> String {
        stems(from: clause).joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Small helpers

    static func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    static func singularize(_ word: String) -> String {
        if word.hasSuffix("ies") && word.count > 3 { return String(word.dropLast(3)) + "y" }
        if word.hasSuffix("es") && word.count > 3 { return String(word.dropLast(2)) }
        if word.hasSuffix("s") && word.count > 2 { return String(word.dropLast()) }
        return word
    }

    static func containsWord(_ haystack: String, _ phrase: String) -> Bool {
        let pattern = #"(?<![\w])"# + NSRegularExpression.escapedPattern(for: phrase) + #"(?![\w])"#
        return haystack.range(of: pattern, options: .regularExpression) != nil
    }

    /// First captured integer across the given regex patterns, in order.
    static func firstInt(in text: String, patterns: [String]) -> Int? {
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1,
               let r = Range(match.range(at: 1), in: text), let n = Int(text[r]) {
                return n
            }
        }
        return nil
    }
}
