//  SetLogParser.swift
//  Anchor
//
//  The NL logging pipeline's front door (DESIGN.md §4, phase-1-spec §6).
//  A parser turns one free-text sentence into structured ParsedSetLogs.
//  Resolution to a library Exercise happens later, in the store layer — the
//  parser stays pure and side-effect free.

import Foundation

/// One parsed set (or cluster of sets) before it is matched to the library.
struct ParsedSetLog: Identifiable, Sendable {
    let id = UUID()

    /// Name as written by the user, e.g. "rows". Resolver matches this to a
    /// library Exercise; if it can't, the name is still kept on the SetLog.
    var exerciseName: String

    /// Defaults to 1 if unstated.
    var sets: Int

    /// Nullable — we never invent a rep count.
    var reps: Int?

    var load: String?

    var effort: Effort

    var source: SetSource

    /// The fragment of the original sentence this set came from (audit trail).
    var rawText: String
}

protocol SetLogParser: Sendable {
    /// Parse free text into zero or more sets. Throws only on a hard failure
    /// (e.g. a network/API error in the Claude implementation); an empty result
    /// is valid, not an error.
    func parse(_ text: String) async throws -> [ParsedSetLog]
}

enum ParserError: LocalizedError {
    case noAPIKey
    case http(status: Int, body: String)
    case malformedResponse

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key set."
        case .http(let status, _):
            return "Anthropic API returned HTTP \(status)."
        case .malformedResponse:
            return "Could not read the model's response."
        }
    }
}
