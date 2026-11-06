import SwiftUI
import Charts

struct NoxDiaryFolio: View {
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var query = ""
    @State private var mood = "All"
    @State private var place = "All"
    @State private var pending: VyrethDiaryKnot?

    private var rows: [VyrethDiaryKnot] {
        hub.blob.diary.filter { item in
            (query.isEmpty || item.title.localizedCaseInsensitiveContains(query) || item.verdict.localizedCaseInsensitiveContains(query))
                && (mood == "All" || item.moods.contains(mood))
                && (place == "All" || item.place == place)
        }
        .sorted { $0.watched > $1.watched }
    }

    private var groups: [(String, [VyrethDiaryKnot])] {
        let dict = Dictionary(grouping: rows) { String($0.watched.prefix(7)) }
        return dict.keys.sorted(by: >).map { ($0, dict[$0] ?? []) }
    }

    var body: some View {
        List {
            Section {
                TextField("Search titles or verdicts", text: $query)
                    .foregroundStyle(Color.vyrethPaper)
                Picker("Place", selection: $place) {
                    ForEach(["All", "Cinema", "Home", "Festival", "Outdoor"], id: \.self) { Text($0).tag($0) }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(["All"] + VyrethCatalog.book.moods, id: \.self) { item in
                            Button(item) { mood = item }
                                .font(.footnote)
                                .foregroundStyle(mood == item ? Color.vyrethInk : Color.vyrethPaper)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background { Capsule().fill(mood == item ? Color.vyrethFlare : Color.vyrethPanel) }
                        }
                    }
                }
                NavigationLink(value: VyrethPath.diaryEdit("new")) { Text("Log a film").foregroundStyle(Color.vyrethFlare) }
                NavigationLink(value: VyrethPath.watch) { Text("Watch shelf").foregroundStyle(Color.vyrethPaper) }
                NavigationLink(value: VyrethPath.stats) { Text("Diary stats").foregroundStyle(Color.vyrethPaper) }
            }
            .listRowBackground(Color.vyrethPanel)
            if rows.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        VyrethSketch(kind: "logline")
                        Text("No films logged yet. Add a title, a rating, and one thing you noticed.")
                            .foregroundStyle(Color.vyrethMist)
                            .fixedSize(horizontal: false, vertical: true)
                        NavigationLink(value: VyrethPath.diaryEdit("new")) {
                            Text("Log your first film")
                                .foregroundStyle(Color.vyrethFlare)
                        }
                    }
                }
                .listRowBackground(Color.clear)
            }
            ForEach(groups, id: \.0) { group in
                Section(group.0) {
                    ForEach(group.1) { item in
                        NavigationLink(value: VyrethPath.diaryDetail(item.id)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .foregroundStyle(Color.vyrethPaper)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("\(item.watched) · \(item.place) · \(String(format: "%.1f", item.rating))")
                                    .font(.footnote.monospacedDigit())
                                    .foregroundStyle(Color.vyrethMist)
                                    .fixedSize(horizontal: false, vertical: true)
                                if !item.moods.isEmpty {
                                    Text(item.moods.joined(separator: ", "))
                                        .font(.footnote)
                                        .foregroundStyle(Color.vyrethFlare)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                if let termId = hub.blob.extra.diaryTerms[item.id], let term = VyrethCatalog.book.vyrethTerm(termId) {
                                    Text(term.title)
                                        .font(.footnote)
                                        .foregroundStyle(Color.vyrethFlare)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .swipeActions {
                            Button("Delete", role: .destructive) { pending = item }
                        }
                    }
                }
                .listRowBackground(Color.vyrethPanel)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .vyrethKeysAway()
        .confirmationDialog("Delete this entry?", isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })) {
            Button("Delete", role: .destructive) {
                if let pending { hub.vyrethDeleteDiary(pending.id) }
                pending = nil
            }
            Button("Cancel", role: .cancel) { pending = nil }
        }
        .navigationTitle("Diary")
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }
}

struct NoxEntryEditor: View {
    let entryId: String
    var fromTake: Bool
    var watchSeed: String = ""
    @EnvironmentObject private var hub: VyrethLedgerHub
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var year = ""
    @State private var watched = Date()
    @State private var rating = 3.5
    @State private var place = "Home"
    @State private var moods: [String] = []
    @State private var noticed = ""
    @State private var verdict = ""
    @State private var notice = ""
    @State private var watchId = ""
    @State private var termId = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(entryId == "new" ? "New entry" : "Edit entry")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                labeled("Title", $title)
                labeled("Year, optional", $year)
                DatePicker("Date watched", selection: $watched, displayedComponents: .date)
                    .foregroundStyle(Color.vyrethPaper)
                Text("Rating \(String(format: "%.1f", rating))")
                    .foregroundStyle(Color.vyrethPaper)
                    .monospacedDigit()
                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: starIcon(star))
                            .font(.title2)
                            .foregroundStyle(Color.vyrethFlare)
                            .onTapGesture {
                                if rating == Double(star) { rating = Double(star) - 0.5 }
                                else { rating = Double(star) }
                            }
                            .accessibilityLabel("Set rating near \(star)")
                    }
                }
                Picker("Where watched", selection: $place) {
                    ForEach(["Cinema", "Home", "Festival", "Outdoor"], id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                Text("Moods, up to three")
                    .font(.caption)
                    .foregroundStyle(Color.vyrethMist)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(VyrethCatalog.book.moods, id: \.self) { mood in
                        Button(mood) { toggleMood(mood) }
                            .font(.footnote)
                            .foregroundStyle(moods.contains(mood) ? Color.vyrethInk : Color.vyrethPaper)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background { Capsule().fill(moods.contains(mood) ? Color.vyrethFlare : Color.vyrethPanel) }
                    }
                }
                labeled("What I noticed", $noticed)
                termMenu
                labeled("One-line verdict", $verdict)
                if !notice.isEmpty {
                    Text(notice).foregroundStyle(Color.vyrethEmber).fixedSize(horizontal: false, vertical: true)
                }
                VyrethFlareButton(title: "Save entry") { save() }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .vyrethKeysAway()
        .onAppear(perform: load)
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }

    private var termMenu: some View {
        let title = VyrethCatalog.book.vyrethTerm(termId)?.title ?? "Add a technique"
        return VStack(alignment: .leading, spacing: 4) {
            Text("Technique")
                .font(.caption)
                .foregroundStyle(Color.vyrethMist)
            Menu {
                Button("No technique") { termId = "" }
                ForEach(VyrethCatalog.book.terms.sorted { $0.title < $1.title }) { term in
                    Button(term.title) { termId = term.id }
                }
            } label: {
                Text(title)
                    .foregroundStyle(termId.isEmpty ? Color.vyrethMist : Color.vyrethPaper)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background { RoundedRectangle(cornerRadius: 12).fill(Color.vyrethPanel) }
            }
        }
    }

    private func labeled(_ name: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.caption).foregroundStyle(Color.vyrethMist)
            TextField(name, text: text, axis: .vertical)
                .foregroundStyle(Color.vyrethPaper)
                .padding(10)
                .background { RoundedRectangle(cornerRadius: 12).fill(Color.vyrethPanel) }
        }
    }

    private func starIcon(_ star: Int) -> String {
        if rating >= Double(star) { return "star.fill" }
        if rating >= Double(star) - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }

    private func toggleMood(_ mood: String) {
        if moods.contains(mood) {
            moods.removeAll { $0 == mood }
        } else if moods.count < 3 {
            moods.append(mood)
        } else {
            notice = "Choose up to three moods."
        }
    }

    private func load() {
        if entryId == "new", !watchSeed.isEmpty, let watch = hub.blob.watch.first(where: { $0.id == watchSeed }) {
            title = watch.title
            verdict = watch.note
            watchId = watch.id
            return
        }
        guard entryId != "new", let item = hub.blob.diary.first(where: { $0.id == entryId }) else { return }
        title = item.title
        year = item.year
        watched = VyrethClock.date(item.watched)
        rating = item.rating
        place = item.place
        moods = item.moods
        noticed = item.noticed
        verdict = item.verdict
        termId = hub.blob.extra.diaryTerms[item.id] ?? ""
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            notice = "Add a title before saving."
            return
        }
        let entry = VyrethDiaryKnot(
            id: entryId == "new" ? UUID().uuidString : entryId,
            title: trimmed,
            year: year,
            watched: VyrethClock.key(watched),
            rating: min(5, max(0.5, rating)),
            place: place,
            moods: moods,
            noticed: noticed,
            verdict: verdict
        )
        hub.vyrethSaveDiary(entry, fromTake: fromTake || entryId == "new", termId: termId)
        if !watchId.isEmpty { hub.vyrethDeleteWatch(watchId) }
        dismiss()
    }
}

struct NoxEntryDetail: View {
    let entryId: String
    @EnvironmentObject private var hub: VyrethLedgerHub
    @Environment(\.dismiss) private var dismiss
    @State private var confirm = false

    var body: some View {
        let item = hub.blob.diary.first { $0.id == entryId }
        ScrollView {
            if let item {
                VStack(alignment: .leading, spacing: 10) {
                    Text(item.title)
                        .font(.system(.title, design: .serif).weight(.bold))
                        .foregroundStyle(Color.vyrethPaper)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(item.year.isEmpty ? "Year not set" : item.year) · \(item.watched)")
                        .foregroundStyle(Color.vyrethMist)
                    Text("Rating \(String(format: "%.1f", item.rating)) · \(item.place)")
                        .foregroundStyle(Color.vyrethFlare)
                        .monospacedDigit()
                    if !item.moods.isEmpty {
                        Text(item.moods.joined(separator: ", "))
                            .foregroundStyle(Color.vyrethPaper)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !item.noticed.isEmpty {
                        Text(item.noticed)
                            .foregroundStyle(Color.vyrethMist)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !item.verdict.isEmpty {
                        Text(item.verdict)
                            .foregroundStyle(Color.vyrethPaper)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let termId = hub.blob.extra.diaryTerms[item.id], let term = VyrethCatalog.book.vyrethTerm(termId) {
                        NavigationLink(value: VyrethPath.term(term.id)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Technique")
                                    .font(.caption)
                                    .foregroundStyle(Color.vyrethMist)
                                Text(term.title)
                                    .foregroundStyle(Color.vyrethFlare)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    NavigationLink(value: VyrethPath.diaryEdit(item.id)) {
                        Text("Edit entry").foregroundStyle(Color.vyrethFlare)
                    }
                    ShareLink(item: "\(item.title) (\(item.watched))\n\(item.verdict)\n\(item.noticed)") {
                        Text("Share entry")
                            .foregroundStyle(Color.vyrethPaper)
                    }
                    Button("Delete entry") { confirm = true }
                        .foregroundStyle(Color.vyrethEmber)
                }
                .padding(16)
            }
        }
        .confirmationDialog("Delete this entry?", isPresented: $confirm) {
            Button("Delete", role: .destructive) {
                hub.vyrethDeleteDiary(entryId)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }
}

struct NoxWatchShelf: View {
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var title = ""
    @State private var note = ""
    @State private var notice = ""
    @State private var pending: VyrethWatchKnot?
    @Environment(\.editMode) private var editMode

    private var rows: [VyrethWatchKnot] {
        hub.blob.watch.sorted { $0.order < $1.order }
    }

    var body: some View {
        List {
            Section {
                TextField("Title to watch", text: $title)
                    .foregroundStyle(Color.vyrethPaper)
                TextField("Why it is on the shelf", text: $note, axis: .vertical)
                    .foregroundStyle(Color.vyrethPaper)
                Button("Add to shelf") { add() }
                    .foregroundStyle(Color.vyrethFlare)
                if !notice.isEmpty {
                    Text(notice).foregroundStyle(Color.vyrethMist).fixedSize(horizontal: false, vertical: true)
                }
                Text("\(rows.count) of 200")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Color.vyrethMist)
            }
            .listRowBackground(Color.vyrethPanel)
            ForEach(rows) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .foregroundStyle(Color.vyrethPaper)
                        .fixedSize(horizontal: false, vertical: true)
                    if !item.note.isEmpty {
                        Text(item.note)
                            .font(.footnote)
                            .foregroundStyle(Color.vyrethMist)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    NavigationLink(value: VyrethPath.diaryFromWatch(item.id)) {
                        Text("Mark watched")
                            .font(.footnote)
                            .foregroundStyle(Color.vyrethFlare)
                    }
                }
                .swipeActions {
                    Button("Remove", role: .destructive) { pending = item }
                }
            }
            .onMove(perform: hub.vyrethMoveWatch)
            .listRowBackground(Color.vyrethPanel)
        }
        .environment(\.editMode, .constant(.active))
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .vyrethKeysAway()
        .confirmationDialog("Remove this title?", isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })) {
            Button("Remove", role: .destructive) {
                if let pending { hub.vyrethDeleteWatch(pending.id) }
                pending = nil
            }
            Button("Cancel", role: .cancel) { pending = nil }
        }
        .navigationTitle("Watch shelf")
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }

    private func add() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            notice = "Add a title first."
            return
        }
        if hub.vyrethAddWatch(title: trimmed, note: note) {
            title = ""
            note = ""
            notice = "Added."
        } else {
            notice = "The shelf holds 200 titles. Remove one to add another."
        }
    }
}

struct NoxDiaryStats: View {
    @EnvironmentObject private var hub: VyrethLedgerHub

    private var months: [(String, Int)] {
        let dict = Dictionary(grouping: hub.blob.diary) { String($0.watched.prefix(7)) }
        return dict.keys.sorted().suffix(6).map { ($0, dict[$0]?.count ?? 0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Diary stats")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                if hub.blob.diary.isEmpty {
                    VyrethSketch(kind: "beats")
                    Text("Log a film and the charts will fill with your own notes.")
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                    NavigationLink(value: VyrethPath.diaryEdit("new")) {
                        Text("Log your first film").foregroundStyle(Color.vyrethFlare)
                    }
                } else {
                    Text("Total entries \(hub.blob.diary.count)")
                        .foregroundStyle(Color.vyrethPaper)
                        .monospacedDigit()
                    Text("Average rating \(String(format: "%.2f", average))")
                        .foregroundStyle(Color.vyrethFlare)
                        .monospacedDigit()
                    Text("This month \(monthCount(0)) · previous month \(monthCount(1))")
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Longest run of days with a log: \(longestRun)")
                        .foregroundStyle(Color.vyrethPaper)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Films per month")
                        .font(.headline)
                        .foregroundStyle(Color.vyrethPaper)
                    Chart(months, id: \.0) { item in
                        BarMark(x: .value("Month", item.0), y: .value("Films", item.1))
                            .foregroundStyle(Color.vyrethFlare)
                    }
                    .frame(minHeight: 180)
                    Text("Rating spread")
                        .font(.headline)
                        .foregroundStyle(Color.vyrethPaper)
                    Chart(ratingBins, id: \.0) { item in
                        BarMark(x: .value("Rating", item.0), y: .value("Count", item.1))
                            .foregroundStyle(Color.vyrethEmber)
                    }
                    .frame(minHeight: 160)
                    Text("Where you watched")
                        .font(.headline)
                        .foregroundStyle(Color.vyrethPaper)
                    ForEach(placeSplit, id: \.0) { item in
                        Text("\(item.0): \(item.1)")
                            .foregroundStyle(Color.vyrethMist)
                            .monospacedDigit()
                    }
                    Text("Top moods")
                        .font(.headline)
                        .foregroundStyle(Color.vyrethPaper)
                    ForEach(topMoods, id: \.0) { item in
                        Text("\(item.0): \(item.1)")
                            .foregroundStyle(Color.vyrethMist)
                    }
                }
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen(image: "texture_velvet", opacity: 0.25)
    }

    private var average: Double {
        guard !hub.blob.diary.isEmpty else { return 0 }
        return hub.blob.diary.map(\.rating).reduce(0, +) / Double(hub.blob.diary.count)
    }

    private var ratingBins: [(String, Int)] {
        (1...5).map { star in
            let count = hub.blob.diary.filter { Int($0.rating.rounded()) == star }.count
            return ("\(star)", count)
        }
    }

    private var placeSplit: [(String, Int)] {
        let dict = Dictionary(grouping: hub.blob.diary, by: \.place)
        return dict.keys.sorted().map { ($0, dict[$0]?.count ?? 0) }
    }

    private var topMoods: [(String, Int)] {
        var counts: [String: Int] = [:]
        for entry in hub.blob.diary {
            for mood in entry.moods { counts[mood, default: 0] += 1 }
        }
        return counts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }

    private func monthCount(_ ago: Int) -> Int {
        guard let date = Calendar.current.date(byAdding: .month, value: -ago, to: Date()) else { return 0 }
        let key = VyrethClock.monthKey(date)
        return hub.blob.diary.filter { $0.watched.hasPrefix(key) }.count
    }

    private var longestRun: Int {
        let days = Set(hub.blob.diary.map(\.watched)).sorted()
        var best = 0
        var run = 0
        var previous = ""
        for day in days {
            if previous.isEmpty || VyrethClock.dayDelta(previous, day) == 1 {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = day
        }
        return best
    }
}
