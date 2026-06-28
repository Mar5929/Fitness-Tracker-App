//  SetLogEditView.swift
//  Anchor
//
//  Quick edit for a logged set (phase-1-spec §5: "tapping a row opens a quick
//  edit"). Reps stay optional — "not counted" is a valid state you can set back to.

import SwiftUI
import SwiftData

struct SetLogEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var log: SetLog

    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var countReps: Bool

    init(log: SetLog) {
        self.log = log
        _countReps = State(initialValue: log.reps != nil)
    }

    var body: some View {
        Form {
            Section("Movement") {
                Picker("Exercise", selection: exerciseSelection) {
                    Text("Unrecognized: \(log.exerciseNameSnapshot)").tag(Optional<Exercise>.none)
                    ForEach(exercises) { ex in
                        Text(ex.name).tag(Optional(ex))
                    }
                }
            }

            Section("Sets") {
                Stepper("Sets: \(log.sets)", value: $log.sets, in: 1...50)
            }

            Section("Reps") {
                Toggle("Counted reps", isOn: $countReps)
                if countReps {
                    Stepper("Reps: \(log.reps ?? 0)",
                            value: Binding(get: { log.reps ?? 0 },
                                           set: { log.reps = $0 }),
                            in: 0...100)
                } else {
                    Text("Not counted").foregroundStyle(.secondary)
                }
            }

            Section("Effort") {
                Picker("Effort", selection: effortBinding) {
                    ForEach(Effort.allCases) { Text($0.display).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section("Source") {
                Picker("Source", selection: sourceBinding) {
                    ForEach(SetSource.allCases) { Text($0.display).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section("Original note") {
                Text(log.rawText).font(.callout).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Edit Set")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: countReps) { _, on in if !on { log.reps = nil } }
        .onDisappear { try? context.save() }
    }

    // MARK: - Bindings

    private var exerciseSelection: Binding<Exercise?> {
        Binding(
            get: { log.exercise },
            set: {
                log.exercise = $0
                if let name = $0?.name { log.exerciseNameSnapshot = name }
            }
        )
    }

    private var effortBinding: Binding<Effort> {
        Binding(get: { log.effort }, set: { log.effort = $0 })
    }

    private var sourceBinding: Binding<SetSource> {
        Binding(get: { log.source }, set: { log.source = $0 })
    }
}
