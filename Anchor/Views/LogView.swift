//  LogView.swift
//  Anchor
//
//  The home tab — capture is the whole point (phase-1-spec §5). Big text field
//  ("What did you do?"), iOS dictation (the system keyboard mic; no extra code),
//  a glanceable undoable confirmation, and today's logged sets below.

import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var context

    /// Today's sets, newest first. Bound to a day window computed at view init.
    @Query private var todaysLogs: [SetLog]

    @State private var store: LogStore?
    @State private var draft: String = ""
    @FocusState private var fieldFocused: Bool

    init() {
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? .now
        _todaysLogs = Query(
            filter: #Predicate<SetLog> { $0.timestamp >= start && $0.timestamp < end },
            sort: \SetLog.timestamp, order: .reverse
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                inputArea
                Divider()
                todaysList
            }
            .navigationTitle("Log")
            .safeAreaInset(edge: .bottom) { confirmationBanner }
            .onAppear {
                if store == nil { store = LogStore(context: context) }
            }
        }
    }

    // MARK: - Input

    private var inputArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What did you do?")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Multiline field; the system keyboard's mic gives free dictation.
            TextField(
                "e.g. did 3 sets of calf raises and a few hard rows",
                text: $draft,
                axis: .vertical
            )
            .lineLimit(2...5)
            .textFieldStyle(.roundedBorder)
            .focused($fieldFocused)
            .submitLabel(.done)

            HStack {
                if store?.isWorking == true {
                    ProgressView().controlSize(.small)
                    Text("Logging…").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Log") { submit() }
                    .buttonStyle(.borderedProminent)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || store?.isWorking == true)
            }

            if let error = store?.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red)
            }
        }
        .padding()
    }

    private func submit() {
        guard let store else { return }
        let text = draft
        Task {
            await store.capture(text)
            if store.errorMessage == nil {
                draft = ""
                fieldFocused = false
            }
        }
    }

    // MARK: - Today's sets

    private var todaysList: some View {
        Group {
            if todaysLogs.isEmpty {
                ContentUnavailableView(
                    "Nothing logged today",
                    systemImage: "figure.strengthtraining.traditional",
                    description: Text("Type what you did above. No rep-counting required.")
                )
            } else {
                List {
                    Section("Today") {
                        ForEach(todaysLogs) { log in
                            NavigationLink {
                                SetLogEditView(log: log)
                            } label: {
                                SetLogRow(log: log)
                            }
                        }
                        .onDelete(perform: deleteRows)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private func deleteRows(_ offsets: IndexSet) {
        for index in offsets { context.delete(todaysLogs[index]) }
        try? context.save()
    }

    // MARK: - Confirmation banner

    @ViewBuilder
    private var confirmationBanner: some View {
        if let store, let confirmation = store.confirmation {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: confirmation.hadUnresolved
                      ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(confirmation.hadUnresolved ? .orange : .green)
                VStack(alignment: .leading, spacing: 2) {
                    Text(confirmation.summary).font(.subheadline).bold()
                    Text(confirmation.usedClaude ? "Parsed by Claude · tap a row to edit"
                                                 : "Parsed on-device · tap a row to edit")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Button("Undo") { store.undoLast() }
                    .font(.subheadline.bold())
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .task(id: confirmation.id) {
                // Auto-dismiss after a few seconds; Undo stays available on rows.
                try? await Task.sleep(for: .seconds(5))
                store.dismissConfirmation()
            }
        }
    }
}

// MARK: - Row

private struct SetLogRow: View {
    let log: SetLog

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(log.exerciseNameSnapshot).font(.body).bold()
                if log.isUnresolved {
                    Text("unrecognized")
                        .font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.orange.opacity(0.2), in: Capsule())
                }
                Spacer()
                Text(log.timestamp, style: .time)
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Label("\(log.sets) set\(log.sets == 1 ? "" : "s")", systemImage: "number")
                if let reps = log.reps {
                    Label("\(reps) reps", systemImage: "repeat")
                } else {
                    Text("reps not counted").foregroundStyle(.tertiary)
                }
                EffortBadge(effort: log.effort)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct EffortBadge: View {
    let effort: Effort
    var body: some View {
        Text(effort.display)
            .font(.caption2.bold())
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
    }
    private var color: Color {
        switch effort {
        case .light: return .blue
        case .medium: return .green
        case .hard: return .red
        }
    }
}
