import SwiftUI

struct QuillLoglineLab: View {
    var prompted: Bool
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var whenLine = ""
    @State private var mustLine = ""
    @State private var elseLine = ""
    @State private var finalLine = ""
    @State private var title = ""
    @State private var notes = ""
    @State private var checks = Array(repeating: false, count: 6)
    @State private var status = "Idea"
    @State private var notice = ""

    private var prompt: (genre: String, person: String, obstacle: String, twist: String, stakes: String) {
        hub.vyrethPrompt()
    }

    private var words: Int {
        finalLine.split { $0.isWhitespace || $0.isNewline }.filter { !$0.isEmpty }.count
    }

    private let labels = [
        "A clear protagonist",
        "A goal",
        "An obstacle",
        "Stakes",
        "No ending spoiler",
        "Under 40 words"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(prompted ? "Today's prompt" : "Open writing")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                    .fixedSize(horizontal: false, vertical: true)
                if prompted {
                    Text("\(prompt.genre). \(prompt.person) faces \(prompt.obstacle). Twist: \(prompt.twist). Stakes: \(prompt.stakes).")
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                    VyrethQuietButton(title: "Reroll prompt") {
                        if hub.vyrethRerollPrompt() {
                            notice = "The prompt changed for today."
                        } else {
                            notice = "The prompt can change once each day."
                        }
                    }
                }
                field("Title", text: $title)
                field("When", text: $whenLine)
                field("A person must", text: $mustLine)
                field("Or else", text: $elseLine)
                field("Final logline", text: $finalLine)
                Text("\(words) words. Aim for 25 to 40.")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(words > 40 ? Color.vyrethEmber : Color.vyrethMist)
                ForEach(labels.indices, id: \.self) { index in
                    Button {
                        checks[index].toggle()
                        VyrethHaptic.tap(hub.blob.profile.haptics)
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: checks[index] ? "checkmark.square.fill" : "square")
                                .foregroundStyle(Color.vyrethFlare)
                            Text(labels[index])
                                .foregroundStyle(Color.vyrethPaper)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Picker("Status", selection: $status) {
                    Text("Idea").tag("Idea")
                    Text("Draft").tag("Draft")
                    Text("Polished").tag("Polished")
                }
                .pickerStyle(.segmented)
                if !notice.isEmpty {
                    Text(notice)
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VyrethFlareButton(title: "Save to script pad") { save() }
                if prompted {
                    NavigationLink(value: VyrethPath.loglineOpen) {
                        Text("Write without a prompt")
                            .foregroundStyle(Color.vyrethFlare)
                    }
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .vyrethKeysAway()
        .navigationTitle("Logline Lab")
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }

    private func field(_ name: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.caption)
                .foregroundStyle(Color.vyrethMist)
            TextField(name, text: text, axis: .vertical)
                .foregroundStyle(Color.vyrethPaper)
                .padding(10)
                .background {
                    RoundedRectangle(cornerRadius: 12).fill(Color.vyrethPanel)
                }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            notice = "Add a title before saving."
            return
        }
        let now = VyrethClock.key()
        let entry = VyrethLoglineKnot(
            id: UUID().uuidString,
            title: trimmed,
            genre: prompted ? prompt.genre : "Open",
            status: status,
            whenLine: whenLine,
            mustLine: mustLine,
            elseLine: elseLine,
            text: finalLine,
            notes: notes,
            checks: checks,
            created: now,
            updated: now
        )
        hub.vyrethSaveLogline(entry, counts: prompted)
        notice = "Saved."
    }
}

struct QuillScriptPad: View {
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var query = ""
    @State private var status = "All"
    @State private var genre = "All"
    @State private var sort = "Newest"
    @State private var pending: VyrethLoglineKnot?

    private var genres: [String] {
        ["All"] + Array(Set(hub.blob.loglines.map(\.genre))).sorted()
    }

    private var rows: [VyrethLoglineKnot] {
        var list = hub.blob.loglines
        if status != "All" { list = list.filter { $0.status == status } }
        if genre != "All" { list = list.filter { $0.genre == genre } }
        if !query.isEmpty {
            list = list.filter { $0.title.localizedCaseInsensitiveContains(query) || $0.text.localizedCaseInsensitiveContains(query) }
        }
        switch sort {
        case "Oldest": list.sort { $0.created < $1.created }
        case "Words": list.sort { wordCount($0) > wordCount($1) }
        default: list.sort { $0.updated > $1.updated }
        }
        return list
    }

    var body: some View {
        List {
            Section {
                TextField("Search ideas", text: $query)
                    .foregroundStyle(Color.vyrethPaper)
                Picker("Status", selection: $status) {
                    ForEach(["All", "Idea", "Draft", "Polished"], id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                Picker("Sort", selection: $sort) {
                    ForEach(["Newest", "Oldest", "Words"], id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                if genres.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(genres, id: \.self) { item in
                                Button(item) { genre = item }
                                    .font(.footnote)
                                    .foregroundStyle(genre == item ? Color.vyrethInk : Color.vyrethPaper)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background { Capsule().fill(genre == item ? Color.vyrethFlare : Color.vyrethPanel) }
                            }
                        }
                    }
                }
                NavigationLink(value: VyrethPath.idea("new")) {
                    Text("New idea")
                        .foregroundStyle(Color.vyrethFlare)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .listRowBackground(Color.vyrethPanel)
            if rows.isEmpty {
                Text("Saved loglines appear here. Write one in the lab or start a blank idea.")
                    .foregroundStyle(Color.vyrethMist)
                    .fixedSize(horizontal: false, vertical: true)
                    .listRowBackground(Color.clear)
            }
            ForEach(rows) { item in
                NavigationLink(value: VyrethPath.idea(item.id)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .foregroundStyle(Color.vyrethPaper)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(item.genre) · \(item.status) · \(wordCount(item)) words")
                            .font(.footnote)
                            .foregroundStyle(Color.vyrethMist)
                            .fixedSize(horizontal: false, vertical: true)
                        let filled = hub.vyrethShotFill(item.id)
                        if filled > 0 {
                            Text("\(filled) of 6 shots")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(Color.vyrethFlare)
                        }
                    }
                }
                .swipeActions {
                    Button("Delete", role: .destructive) { pending = item }
                }
                .listRowBackground(Color.vyrethPanel)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .vyrethKeysAway()
        .confirmationDialog("Delete this idea?", isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })) {
            Button("Delete", role: .destructive) {
                if let pending { hub.vyrethDeleteLogline(pending.id) }
                pending = nil
            }
            Button("Cancel", role: .cancel) { pending = nil }
        }
        .navigationTitle("Script pad")
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }

    private func wordCount(_ item: VyrethLoglineKnot) -> Int {
        item.text.split { $0.isWhitespace }.filter { !$0.isEmpty }.count
    }
}

struct QuillIdeaEditor: View {
    let ideaId: String
    @EnvironmentObject private var hub: VyrethLedgerHub
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var genre = "Drama"
    @State private var status = "Idea"
    @State private var text = ""
    @State private var notes = ""
    @State private var whenLine = ""
    @State private var mustLine = ""
    @State private var elseLine = ""
    @State private var checks = Array(repeating: false, count: 6)
    @State private var created = ""
    @State private var notice = ""
    @State private var shots = VyrethShotKnot.blankSix()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(ideaId == "new" ? "New idea" : "Edit idea")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                box("Title", $title)
                box("Genre", $genre)
                Picker("Status", selection: $status) {
                    ForEach(["Idea", "Draft", "Polished"], id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                box("Logline", $text)
                box("When", $whenLine)
                box("Must", $mustLine)
                box("Or else", $elseLine)
                box("Notes", $notes)
                Text("Shot list")
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundStyle(Color.vyrethPaper)
                Text("Six frames. Set size, angle, and movement on each one.")
                    .font(.subheadline)
                    .foregroundStyle(Color.vyrethMist)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(shots.indices, id: \.self) { index in
                    shotRow(index)
                }
                if !created.isEmpty {
                    Text("Created \(created)")
                        .font(.footnote)
                        .foregroundStyle(Color.vyrethMist)
                }
                if !notice.isEmpty {
                    Text(notice).foregroundStyle(Color.vyrethMist).fixedSize(horizontal: false, vertical: true)
                }
                VyrethFlareButton(title: "Save") { save() }
                if ideaId != "new", let item = hub.blob.loglines.first(where: { $0.id == ideaId }) {
                    ShareLink(item: shareText(item)) {
                        Text("Share logline")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(Color.vyrethPaper)
                    }
                    .buttonStyle(VyrethQuietStyle())
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .vyrethKeysAway()
        .onAppear(perform: load)
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }

    private func box(_ name: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.caption).foregroundStyle(Color.vyrethMist)
            TextField(name, text: text, axis: .vertical)
                .foregroundStyle(Color.vyrethPaper)
                .padding(10)
                .background { RoundedRectangle(cornerRadius: 12).fill(Color.vyrethPanel) }
        }
    }

    private func load() {
        guard ideaId != "new", let item = hub.blob.loglines.first(where: { $0.id == ideaId }) else { return }
        title = item.title
        genre = item.genre
        status = item.status
        text = item.text
        notes = item.notes
        whenLine = item.whenLine
        mustLine = item.mustLine
        elseLine = item.elseLine
        checks = item.checks.count == 6 ? item.checks : checks
        created = item.created
        let stored = hub.blob.extra.shots[item.id] ?? []
        if stored.count == 6 { shots = stored }
    }

    private func shotRow(_ index: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Shot \(index + 1)")
                .font(.caption)
                .foregroundStyle(Color.vyrethMist)
            HStack(spacing: 6) {
                shotMenu(shots[index].size, "Size", VyrethShotWords.sizes) { shots[index].size = $0 }
                shotMenu(shots[index].angle, "Angle", VyrethShotWords.angles) { shots[index].angle = $0 }
                shotMenu(shots[index].move, "Move", VyrethShotWords.moves) { shots[index].move = $0 }
            }
        }
    }

    private func shotMenu(_ current: String, _ placeholder: String, _ options: [String], _ set: @escaping (String) -> Void) -> some View {
        Menu {
            Button("Clear") { set("") }
            ForEach(options, id: \.self) { option in
                Button(option) { set(option) }
            }
        } label: {
            Text(current.isEmpty ? placeholder : current)
                .font(.caption2)
                .foregroundStyle(current.isEmpty ? Color.vyrethMist : Color.vyrethPaper)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background { RoundedRectangle(cornerRadius: 10).fill(Color.vyrethPanel) }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            notice = "Add a title before saving."
            return
        }
        let now = VyrethClock.key()
        let existing = hub.blob.loglines.first { $0.id == ideaId }
        let id = ideaId == "new" ? UUID().uuidString : ideaId
        let entry = VyrethLoglineKnot(
            id: id,
            title: trimmed,
            genre: genre.isEmpty ? "Drama" : genre,
            status: status,
            whenLine: whenLine,
            mustLine: mustLine,
            elseLine: elseLine,
            text: text,
            notes: notes,
            checks: existing?.checks ?? checks,
            created: existing?.created ?? now,
            updated: now
        )
        hub.vyrethSaveLogline(entry, counts: false)
        hub.vyrethSaveShots(id, shots, announce: false)
        dismiss()
    }

    private func shareText(_ item: VyrethLoglineKnot) -> String {
        "\(item.title)\n\(item.text)"
    }
}

struct QuillShotList: View {
    @EnvironmentObject private var hub: VyrethLedgerHub

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Shot list")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                Text("Open a saved logline and fill six frames. A complete list counts as today's Shot list Take.")
                    .foregroundStyle(Color.vyrethMist)
                    .fixedSize(horizontal: false, vertical: true)
                if hub.blob.loglines.isEmpty {
                    Text("Save a logline first, then break it into shots.")
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                    NavigationLink(value: VyrethPath.logline) {
                        Text("Open Logline Lab")
                            .foregroundStyle(Color.vyrethFlare)
                    }
                }
                ForEach(hub.blob.loglines.sorted { $0.updated > $1.updated }) { item in
                    NavigationLink(value: VyrethPath.idea(item.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .foregroundStyle(Color.vyrethPaper)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(hub.vyrethShotFill(item.id)) of 6 shots")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(Color.vyrethMist)
                        }
                        .vyrethPanel()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .navigationTitle("Shot list")
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }
}
