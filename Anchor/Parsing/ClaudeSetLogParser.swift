//  ClaudeSetLogParser.swift
//  Anchor
//
//  Optional network parser (phase-1-spec §6). Calls the Anthropic Messages API
//  with tool use so the model returns typed SetLogs, not prose to parse. Reads
//  the key from the Keychain; if it's absent it throws .noAPIKey and the caller
//  silently falls back to the mock (no error shown to the user).

import Foundation

struct ClaudeSetLogParser: SetLogParser {
    /// Library names, sent to the model so it resolves to known movements.
    let knownExerciseNames: [String]

    /// Injected for testability; defaults to the real Keychain.
    var apiKeyProvider: @Sendable () -> String? = { KeychainStore.loadAPIKey() }

    private let session: URLSession = .shared

    func parse(_ text: String) async throws -> [ParsedSetLog] {
        guard let apiKey = apiKeyProvider(), !apiKey.isEmpty else {
            throw ParserError.noAPIKey
        }

        var request = URLRequest(url: AnchorConfig.messagesEndpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(AnchorConfig.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody(for: text))

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ParserError.malformedResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw ParserError.http(status: http.statusCode,
                                   body: String(data: data, encoding: .utf8) ?? "")
        }

        return try Self.decodeToolUse(data)
    }

    // MARK: - Request

    private func requestBody(for text: String) -> [String: Any] {
        [
            "model": AnchorConfig.parseModel,
            "max_tokens": AnchorConfig.parseMaxTokens,
            "system": Self.systemPrompt(known: knownExerciseNames),
            "tools": [Self.logSetsTool],
            "tool_choice": ["type": "tool", "name": "log_sets"],
            "messages": [
                ["role": "user", "content": text]
            ]
        ]
    }

    static func systemPrompt(known: [String]) -> String {
        """
        You convert a person's free-text strength-training note into structured sets.
        Rules:
        - Track SET COUNT and EFFORT, never invent reps. If reps are not explicitly \
        stated, omit reps entirely ("didn't count" is valid).
        - effort is one of: light, medium, hard. Map words like "easy/light"→light, \
        "hard/heavy/went hard/burned out/to failure"→hard, otherwise medium.
        - sets defaults to 1 if unstated. "a couple"→2, "a few/several"→3.
        - source is "adhoc" unless the note clearly describes a planned session.
        - Resolve each movement to the closest of these known library names when \
        there is a clear match; otherwise return the user's own wording:
        \(known.joined(separator: ", "))
        Call the log_sets tool exactly once with every set you find.
        """
    }

    static let logSetsTool: [String: Any] = [
        "name": "log_sets",
        "description": "Record the sets described in the user's note.",
        "input_schema": [
            "type": "object",
            "properties": [
                "sets": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "exerciseName": ["type": "string"],
                            "sets": ["type": "integer", "minimum": 1],
                            "reps": ["type": ["integer", "null"]],
                            "load": ["type": ["string", "null"]],
                            "effort": ["type": "string", "enum": ["light", "medium", "hard"]],
                            "source": ["type": "string", "enum": ["planned", "adhoc"]],
                            "rawText": ["type": "string"]
                        ],
                        "required": ["exerciseName", "sets", "effort", "source"]
                    ]
                ]
            ],
            "required": ["sets"]
        ]
    ]

    // MARK: - Response decoding

    /// Pull the first `log_sets` tool_use block out of the Messages response and
    /// map it to ParsedSetLogs.
    static func decodeToolUse(_ data: Data) throws -> [ParsedSetLog] {
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = root["content"] as? [[String: Any]]
        else { throw ParserError.malformedResponse }

        let toolBlock = content.first { ($0["type"] as? String) == "tool_use" }
        guard
            let input = toolBlock?["input"] as? [String: Any],
            let rawSets = input["sets"] as? [[String: Any]]
        else { throw ParserError.malformedResponse }

        return rawSets.compactMap { item in
            guard let name = (item["exerciseName"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty
            else { return nil }

            let setCount = max(1, (item["sets"] as? Int) ?? 1)
            let reps = item["reps"] as? Int            // nil when absent or JSON null
            let load = (item["load"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            let effort = Effort(rawValue: (item["effort"] as? String) ?? "medium") ?? .medium
            let source = SetSource(rawValue: (item["source"] as? String) ?? "adhoc") ?? .adhoc
            let rawText = (item["rawText"] as? String) ?? name

            return ParsedSetLog(
                exerciseName: name,
                sets: setCount,
                reps: reps,
                load: load,
                effort: effort,
                source: source,
                rawText: rawText
            )
        }
    }
}
