//  KeychainStore.swift
//  Anchor
//
//  The Anthropic API key lives in the iOS Keychain ONLY — never on disk in
//  plaintext, never committed (phase-1-spec §2, §7). Thin wrapper over SecItem.

import Foundation
import Security

enum KeychainStore {
    /// Namespaced so the key is isolated to this app.
    private static let service = "com.mrihm.anchor"
    private static let account = "anthropic-api-key"

    /// Store (or overwrite) the API key. Returns false on an unexpected status.
    @discardableResult
    static func saveAPIKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else {
            return false
        }

        // Delete any existing item first so we cleanly overwrite.
        _ = clearAPIKey()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    /// Read the API key, or nil if none is stored.
    static func loadAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty
        else {
            return nil
        }
        return key
    }

    /// Remove the stored key. Returns true if it was removed or already absent.
    @discardableResult
    static func clearAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    static var hasAPIKey: Bool { loadAPIKey() != nil }
}
