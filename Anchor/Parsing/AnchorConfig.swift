//  AnchorConfig.swift
//  Anchor
//
//  Single source of truth for API + model configuration. Do NOT hardcode model
//  ids anywhere else (phase-1-spec §6).

import Foundation

enum AnchorConfig {
    /// Phase 1 NL parse model — fast/cheap for the structured-extraction task
    /// (DESIGN.md §8). Confirm the exact id at build time.
    static let parseModel = "claude-haiku-4-5"

    /// Stronger model reserved for workout generation/rationale (later phases).
    /// Declared here so there's a slot for it; NOT used in Phase 1.
    static let generationModel = "claude-sonnet-4-6"

    /// Anthropic API version header. Confirm the current value at build time.
    static let anthropicVersion = "2023-06-01"

    static let messagesEndpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    /// Token ceiling for the small parse response.
    static let parseMaxTokens = 1024
}
