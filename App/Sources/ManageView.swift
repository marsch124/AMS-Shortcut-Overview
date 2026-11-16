import SwiftUI
import ServiceManagement
import ShortcutCore

/// The window behind the menu bar icon: shortcuts, learned list, look, guide, what's new.
struct ManageView: View {
    @ObservedObject var model: AppModel
    @State private var page = "shortcuts"

    var body: some View {
        VStack(spacing: 6) {
            if let problem = model.saveProblem {
                Text(problem).font(.callout).foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("saveProblem")
            }
            if let notice = model.restoreNotice {
                HStack(alignment: .top) {
                    Text(notice).font(.callout).foregroundStyle(CardColours.accent("amber"))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button("OK") { model.restoreNotice = nil }
                }
                .accessibilityIdentifier("restoreNotice")
            }
            pages
        }
        .padding(12)
        .frame(width: 600, height: 520)
        .accessibilityIdentifier("manageWindow")
        .onReceive(NotificationCenter.default.publisher(for: .showPage)) { note in
            if let name = note.object as? String { page = name }
        }
    }

    private var pages: some View {
        TabView(selection: $page) {
            ShortcutsPage(model: model).tabItem { Text("Shortcuts") }.tag("shortcuts")
            LearnedPage(model: model).tabItem { Text("Learned") }.tag("learned")
            RemovedPage(model: model).tabItem { Text("Removed") }.tag("removed")
            LookPage(model: model).tabItem { Text("Settings") }.tag("settings")
            GuidePage(sections: Guide.howItWorks).tabItem { Text("How it works") }.tag("guide")
            NewsPage().tabItem { Text("What's new") }.tag("news")
        }
    }
}

// MARK: Shortcuts

struct ShortcutsPage: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 8) {
            List {
                ForEach(model.groups) { g in
                    Section {
                        ForEach(g.shortcuts) { s in
                            HStack(spacing: 8) {
                                Text(s.name)
                                Spacer()
                                Text(statusText(s)).font(.caption).foregroundStyle(.secondary)
                                let c = CardColours.of(g.colour, dark: false)
                                KeyCaps(keys: s.keys, fill: c.fill, text: c.title)
                                Button("Change") { AppDelegate.shared.openEditor(shortcut: s, appName: g.name) }
                                    .buttonStyle(.borderless)
                                    .foregroundStyle(CardColours.accent(g.colour))
                            }
                        }
                    } header: {
                        GroupHeader(model: model, group: g)
                    }
                }
            }
            .accessibilityIdentifier("shortcutList")
            HStack {
                Text("Version \(Guide.version)").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Menu("Add ready-made app") {
                    ForEach(model.readyMadeMissing) { g in
                        Button("\(g.name) (\(g.shortcuts.count) shortcuts)") { model.addReadyMade(g) }
                    }
                }
                .fixedSize()
                .disabled(model.readyMadeMissing.isEmpty)
                .help(model.readyMadeMissing.isEmpty ? "Every ready-made app is on your list already" : "Add a card with 8 checked shortcuts")
                .accessibilityIdentifier("addReadyMade")
                Button("Add shortcut") { AppDelegate.shared.openEditor(shortcut: nil, appName: "") }
                    .buttonStyle(.borderedProminent)
                    .tint(CardColours.button("purple"))
                    .accessibilityIdentifier("addShortcut")
            }
        }
    }

    private func statusText(_ s: Shortcut) -> String {
        switch model.status(s) {
        case .learning: return ""
        case .recheck: return "Recheck"
        case .learned: return "Learned"
        }
    }
}

struct GroupHeader: View {
    @ObservedObject var model: AppModel
    let group: AppGroup
    @State private var askRemove = false

    var body: some View {
        HStack(spacing: 6) {
            Button {
                let names = CardColours.names
                let i = names.firstIndex(of: group.colour) ?? -1
                model.setColour(names[(i + 1) % names.count], group: group.id)
            } label: {
                Circle().fill(CardColours.accent(group.colour)).frame(width: 12, height: 12)
            }
            .buttonStyle(.plain)
            .help("Click to try the next colour")
            Text(group.name).font(.headline).foregroundStyle(CardColours.accent(group.colour))
            Spacer()
            Button("Move left") { model.moveGroup(group.id, by: -1) }.buttonStyle(.borderless)
            Button("Move right") { model.moveGroup(group.id, by: 1) }.buttonStyle(.borderless)
            Button("Remove") { askRemove = true }.buttonStyle(.borderless)
                .accessibilityIdentifier("removeApp-\(group.name)")
        }
        .font(.caption)
        .confirmationDialog("Remove \(group.name) from the desktop?", isPresented: $askRemove) {
            Button("Remove") { model.removeGroup(group.id) }
                .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The card and its \(group.shortcuts.count) shortcuts move to the Removed page. Bring them back from there any time.")
        }
    }
}

// MARK: Learned

struct LearnedPage: View {
    @ObservedObject var model: AppModel

    var body: some View {
        let groups = model.groups.filter { g in g.shortcuts.contains { model.status($0) == .learned } }
        if groups.isEmpty {
            VStack(spacing: 6) {
                Text("Nothing learned yet").font(.headline)
                Text("Tick a shortcut on a desktop card when you know it. It moves here, and comes back once after two weeks to check you still know it.")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary).frame(maxWidth: 380)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 6) {
            Text("This week: \(model.learnedThisWeek) learned · \(model.learnedInAll) learned in all\(model.streakWords)")
                .font(.callout).foregroundStyle(CardColours.accent("green"))
                .accessibilityIdentifier("learnedThisWeek")
            List {
                ForEach(groups) { g in
                    Section {
                        ForEach(g.shortcuts.filter { model.status($0) == .learned }) { s in
                            HStack(spacing: 8) {
                                Text(s.name)
                                Spacer()
                                Text(when(s)).font(.caption).foregroundStyle(.secondary)
                                let c = CardColours.of(g.colour, dark: false)
                                KeyCaps(keys: s.keys, fill: c.fill, text: c.title)
                                Button("Bring back") { model.bringBack(s.id) }
                                    .buttonStyle(.borderless)
                                    .foregroundStyle(CardColours.accent(g.colour))
                            }
                        }
                    } header: {
                        Text(g.name).font(.headline).foregroundStyle(CardColours.accent(g.colour))
                    }
                }
            }
            }
        }
    }

    private func when(_ s: Shortcut) -> String {
        guard let d = s.learnedAt else { return "" }
        if s.recheckDone { return "Learned, no more rechecks" }
        let due = Calendar.current.date(byAdding: .day, value: Rules.recheckAfterDays, to: d) ?? d
        return "Recheck on \(due.formatted(.dateTime.day().month(.abbreviated)))"
    }
}

// MARK: Removed

/// Everything taken off the list. Nothing is ever deleted; it waits here to be brought back.
struct RemovedPage: View {
    @ObservedObject var model: AppModel

    var body: some View {
        let apps = model.removedApps
        let singles = model.removedShortcuts
        if apps.isEmpty && singles.isEmpty {
            VStack(spacing: 6) {
                Text("Nothing removed").font(.headline)
                Text("When you remove a shortcut or a whole app, it moves here instead of being deleted. Bring it back any time.")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary).frame(maxWidth: 380)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Nothing is ever deleted. Bring back what you want to see again.")
                    .font(.callout).foregroundStyle(CardColours.accent("coral"))
                List {
                    ForEach(apps) { g in
                        Section {
                            ForEach(g.shortcuts) { s in row(s, in: g, button: false) }
                        } header: {
                            HStack {
                                Text(g.name).font(.headline).foregroundStyle(CardColours.accent(g.colour))
                                Text("whole app, \(g.shortcuts.count) shortcuts").font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Button("Bring back app") { model.bringBackGroup(g.id) }
                                    .buttonStyle(.borderedProminent).controlSize(.small)
                                    .tint(CardColours.button(g.colour))
                                    .accessibilityIdentifier("bringBackApp-\(g.name)")
                            }
                        }
                    }
                    ForEach(singles) { g in
                        Section {
                            ForEach(g.shortcuts) { s in row(s, in: g, button: true) }
                        } header: {
                            Text(g.name).font(.headline).foregroundStyle(CardColours.accent(g.colour))
                        }
                    }
                }
                .accessibilityIdentifier("removedList")
            }
        }
    }

    private func row(_ s: Shortcut, in g: AppGroup, button: Bool) -> some View {
        HStack(spacing: 8) {
            Text(s.name)
            Spacer()
            let c = CardColours.of(g.colour, dark: false)
            KeyCaps(keys: s.keys, fill: c.fill, text: c.title)
            if button {
                Button("Bring back") { model.bringBackRemoved(s.id) }
                    .buttonStyle(.borderless)
                    .foregroundStyle(CardColours.accent(g.colour))
                    .accessibilityIdentifier("bringBack-\(s.name)")
            }
        }
    }
}

// MARK: Settings

struct LookPage: View {
    @ObservedObject var model: AppModel
    @State private var atLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Toggle("Show the cards on the desktop", isOn: $model.showCards)
            Stepper("Shortcuts per card: \(model.rowsPerCard)", value: $model.rowsPerCard, in: 3...12)
            Toggle(isOn: $model.dailyPick) {
                Text("Today's shortcuts")
                Text("A fresh pick on every card each day, instead of list order.")
            }
            .accessibilityIdentifier("dailyPickSwitch")
            Toggle(isOn: $model.quiz) {
                Text("Quiz me")
                Text("The keys hide until you point at a row or click them.")
            }
            .accessibilityIdentifier("quizSwitch")
            Toggle("Open at login", isOn: $atLogin)
                .onChange(of: atLogin) { _, on in
                    if on { try? SMAppService.mainApp.register() } else { try? SMAppService.mainApp.unregister() }
                }
            LabeledContent("Your list is kept in") {
                Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([model.file]) }
                    .buttonStyle(.borderless)
            }
            LabeledContent {
                Button("Export my list…") { model.exportList() }
                    .buttonStyle(.borderless)
                    .accessibilityIdentifier("exportList")
            } label: {
                Text("A copy to keep anywhere")
                if !model.lastExport.isEmpty { Text(model.lastExport) }
                if let problem = model.exportProblem { Text(problem).foregroundStyle(.red) }
            }
            LabeledContent {
                HStack(spacing: 12) {
                    if model.undoFile != nil {
                        Button("Undo") { model.offerUndo() }
                            .buttonStyle(.borderless)
                            .help("Puts back the list you had before the last bring-in. It asks first.")
                            .accessibilityIdentifier("undoBringIn")
                    }
                    Button("Bring a list back in…") { model.chooseListToBringIn() }
                        .buttonStyle(.borderless)
                        .accessibilityIdentifier("bringListIn")
                }
            } label: {
                Text("Bring an exported list back")
                if !model.importNote.isEmpty { Text(model.importNote) }
                if let problem = model.importProblem { Text(problem).foregroundStyle(.red) }
            }
            LabeledContent("Version", value: Guide.version)
        }
        .formStyle(.grouped)
        .confirmationDialog("Replace your list with this one?",
                            isPresented: Binding(get: { model.pendingImport != nil },
                                                 set: { if !$0 { model.pendingImport = nil } }),
                            presenting: model.pendingImport) { _ in
            Button("Replace my list") { model.bringInPending() }
                .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) { model.pendingImport = nil }
        } message: { pending in
            Text("The file \u{201C}\(pending.url.lastPathComponent)\u{201D} holds \(AppModel.counts(pending.library)). Your list now holds \(AppModel.counts(model.library)). It is kept as a safety copy first, so you can undo this.")
        }
        .onChange(of: model.showCards) { _, _ in AppDelegate.shared.desktop?.refresh() }
        .onChange(of: model.rowsPerCard) { _, _ in AppDelegate.shared.desktop?.refresh() }
        .onChange(of: model.dailyPick) { _, _ in AppDelegate.shared.desktop?.refresh() }
        .onChange(of: model.quiz) { _, _ in AppDelegate.shared.desktop?.refresh() }
    }
}

// MARK: Guide and news

struct GuidePage: View {
    let sections: [GuideSection]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(sections) { s in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(s.title).font(.headline).foregroundStyle(CardColours.accent(s.colour))
                        Text(s.body).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct NewsPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Guide.releases) { r in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Version \(r.version) · \(r.date)").font(.headline)
                            .foregroundStyle(CardColours.accent("purple"))
                        ForEach(r.items, id: \.self) { item in
                            Text("• " + item).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
