//  SettingsView.swift
//  Anchor
//
//  Minimal Phase 1 settings (phase-1-spec §7): enter/clear the Anthropic API key
//  in the Keychain. Nothing else. The app works fully with no key (mock parser).

import SwiftUI

struct SettingsView: View {
    @State private var keyDraft: String = ""
    @State private var hasKey: Bool = KeychainStore.hasAPIKey
    @State private var justSaved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: hasKey ? "checkmark.seal.fill" : "key.slash")
                            .foregroundStyle(hasKey ? .green : .secondary)
                        Text(hasKey ? "API key stored in Keychain" : "No API key — using on-device parser")
                            .font(.subheadline)
                    }
                } header: {
                    Text("Status")
                } footer: {
                    Text("Anchor works fully without a key: logging is parsed on-device. "
                         + "Add your Anthropic key to use Claude for sharper parsing.")
                }

                Section("Anthropic API Key") {
                    SecureField("sk-ant-…", text: $keyDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Save Key") { save() }
                        .disabled(keyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if hasKey {
                        Button("Clear Key", role: .destructive) { clear() }
                    }
                }

                if justSaved {
                    Section { Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green) }
                }

                Section {
                    LabeledContent("Parse model", value: AnchorConfig.parseModel)
                    LabeledContent("App", value: "Anchor · Phase 1")
                } header: {
                    Text("About")
                } footer: {
                    Text("The key is stored only in the iOS Keychain on this device. "
                         + "It is never written to disk in plaintext or sent anywhere but Anthropic.")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func save() {
        guard KeychainStore.saveAPIKey(keyDraft) else { return }
        keyDraft = ""
        hasKey = true
        flashSaved()
    }

    private func clear() {
        KeychainStore.clearAPIKey()
        hasKey = false
    }

    private func flashSaved() {
        justSaved = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            justSaved = false
        }
    }
}
