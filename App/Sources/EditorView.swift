import SwiftUI
import ShortcutCore

/// Add or change one shortcut. Cancel / Save; Escape is Cancel.
struct EditorView: View {
    @ObservedObject var model: AppModel
    let original: Shortcut?
    @State var appName: String
    @State private var name: String
    @State private var keys: String
    @State private var problem = ""
    var close: () -> Void

    init(model: AppModel, original: Shortcut?, appName: String, close: @escaping () -> Void) {
        self.model = model
        self.original = original
        _appName = State(initialValue: appName)
        _name = State(initialValue: original?.name ?? "")
        _keys = State(initialValue: original?.keys ?? "")
        self.close = close
    }

    private var colour: String {
        model.library.groups.first { $0.name.caseInsensitiveCompare(appName) == .orderedSame }?.colour
            ?? Rules.nextColour(used: model.library.groups.map(\.colour))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(original == nil ? "New shortcut" : "Change shortcut")
                .font(.headline).foregroundStyle(CardColours.accent(colour))

            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    Text("App").foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        TextField("Obsidian", text: $appName).accessibilityIdentifier("editorApp")
                        Menu("Pick") {
                            ForEach(model.library.groups) { g in Button(g.name) { appName = g.name } }
                        }
                        .fixedSize()
                    }
                }
                GridRow {
                    Text("What it does").foregroundStyle(.secondary)
                    TextField("Search all files", text: $name).accessibilityIdentifier("editorName")
                }
                GridRow {
                    Text("Keys").foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        TextField("⌘ ⇧ F", text: $keys).accessibilityIdentifier("editorKeys")
                        ForEach(["⌘", "⌥", "⌃", "⇧"], id: \.self) { m in
                            Button(m) { keys = (keys.isEmpty ? "" : keys + " ") + m }
                                .help(help(for: m))
                        }
                    }
                }
                GridRow {
                    Text("Looks like").foregroundStyle(.secondary)
                    let c = CardColours.of(colour, dark: false)
                    KeyCaps(keys: Rules.cleanKeys(keys), fill: c.fill, text: c.title)
                        .frame(height: 20)
                }
            }

            if !problem.isEmpty {
                Text(problem).font(.callout).foregroundStyle(.red)
            }

            HStack {
                if let o = original {
                    Button("Delete", role: .destructive) { model.delete(o.id); close() }
                }
                Spacer()
                Button("Cancel") { close() }.keyboardShortcut(.cancelAction)
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .tint(CardColours.button(colour))
                    .accessibilityIdentifier("editorSave")
            }
        }
        .padding(16)
        .frame(width: 440)
    }

    private func help(for m: String) -> String {
        ["⌘": "Command", "⌥": "Option", "⌃": "Control", "⇧": "Shift"][m] ?? m
    }

    private func save() {
        let a = appName.trimmingCharacters(in: .whitespaces)
        let n = name.trimmingCharacters(in: .whitespaces)
        let k = Rules.cleanKeys(keys)
        if a.isEmpty { problem = "Type the app's name."; return }
        if n.isEmpty { problem = "Say what the shortcut does."; return }
        if k.isEmpty { problem = "Type the keys, for example ⌘ ⇧ F."; return }
        var s = original ?? Shortcut(name: n, keys: k)
        s.name = n; s.keys = k
        model.save(shortcut: s, appName: a)
        close()
    }
}
