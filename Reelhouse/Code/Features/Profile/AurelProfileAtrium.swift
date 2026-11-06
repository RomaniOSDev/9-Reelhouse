import SwiftUI
import StoreKit
import UniformTypeIdentifiers
import UserNotifications

struct AurelProfileAtrium: View {
    @EnvironmentObject private var hub: VyrethLedgerHub

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Career")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                let rank = VyrethRankTable.step(for: hub.blob.reels)
                VStack(alignment: .leading, spacing: 6) {
                    Text(rank.name)
                        .font(.system(.title, design: .serif).weight(.bold))
                        .foregroundStyle(Color.vyrethPaper)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(hub.blob.reels) Reels")
                        .foregroundStyle(Color.vyrethFlare)
                        .monospacedDigit()
                    Text("Streak \(hub.blob.streak.current) · best \(hub.blob.streak.best)")
                        .foregroundStyle(Color.vyrethMist)
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Takes recorded across \(hub.blob.days.filter { $0.lesson || $0.spotter || $0.logline || $0.diary }.count) active days")
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .vyrethPanel(strong: true)
                link(.ranks, "Career ladder")
                link(.vault, "Frame vault")
                link(.lobby, "Studio lobby")
                link(.badges, "Achievements")
                link(.glossary, "Glossary")
                link(.saved, "Saved cards")
                link(.settings, "Settings")
            }
            .padding(16)
        }
        .vyrethScreen(image: "texture_velvet", opacity: 0.38)
    }

    private func link(_ path: VyrethPath, _ title: String) -> some View {
        NavigationLink(value: path) {
            HStack {
                Text(title)
                    .foregroundStyle(Color.vyrethPaper)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(Color.vyrethMist)
            }
            .vyrethPanel()
        }
        .buttonStyle(.plain)
    }
}

struct AurelRankLadder: View {
    @EnvironmentObject private var hub: VyrethLedgerHub

    private let perks = [
        "Starting rank. The slate is open.",
        "Unlocks a poster and a frame card.",
        "Unlocks another poster design.",
        "Rest pass cap rises to three.",
        "Unlocks a poster and a frame card.",
        "Unlocks a poster and a frame card.",
        "Unlocks the final poster."
    ]

    var body: some View {
        let current = VyrethRankTable.step(for: hub.blob.reels)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Career ladder")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                ForEach(VyrethRankTable.steps.indices, id: \.self) { index in
                    let step = VyrethRankTable.steps[index]
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.0)
                            .font(.headline)
                            .foregroundStyle(index <= current.index ? Color.vyrethPaper : Color.vyrethMist)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(step.1) Reels")
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(Color.vyrethFlare)
                        Text(perks[index])
                            .font(.footnote)
                            .foregroundStyle(Color.vyrethMist)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .vyrethPanel(strong: index == current.index)
                }
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen(image: "texture_velvet", opacity: 0.3)
    }
}

struct AurelFrameVault: View {
    @EnvironmentObject private var hub: VyrethLedgerHub

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Frame vault")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                Text("\(hub.blob.unlocks.filter { $0.kind == "card" }.count) of \(VyrethCatalog.book.terms.count) open")
                    .foregroundStyle(Color.vyrethMist)
                    .monospacedDigit()
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                    ForEach(VyrethCatalog.book.terms) { term in
                        NavigationLink(value: VyrethPath.card(term.id)) {
                            VStack(alignment: .leading, spacing: 6) {
                                if hub.vyrethHas("card", term.id) {
                                    VyrethSketch(kind: sketch(term.id))
                                    Text(term.title)
                                        .foregroundStyle(Color.vyrethPaper)
                                        .fixedSize(horizontal: false, vertical: true)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.vyrethInk)
                                        .frame(height: 72)
                                        .overlay(Image(systemName: "film").foregroundStyle(Color.vyrethMist))
                                    Text(term.title)
                                        .foregroundStyle(Color.vyrethMist)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(term.unlock)
                                        .font(.caption2)
                                        .foregroundStyle(Color.vyrethMist)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(10)
                            .background {
                                RoundedRectangle(cornerRadius: 16).fill(Color.vyrethPanel)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }

    private func sketch(_ id: String) -> String {
        let kinds = ["scale", "angle", "thirds", "depth", "lens", "move", "trio", "soft", "temp", "contrast"]
        let index = abs(id.hashValue) % kinds.count
        return kinds[index]
    }
}

struct AurelCardDetail: View {
    let termId: String
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var flipped = false

    var body: some View {
        let term = VyrethCatalog.book.vyrethTerm(termId)
        let open = hub.vyrethHas("card", termId)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(term?.title ?? "Term")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                    .fixedSize(horizontal: false, vertical: true)
                if open {
                    VyrethSketch(kind: "thirds")
                        .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                    Text(flipped ? (term?.tip ?? "") : (term?.definition ?? ""))
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(flipped ? "Show definition" : "Flip for a tip") {
                        if hub.motionQuiet { flipped.toggle() }
                        else { withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { flipped.toggle() } }
                    }
                    .foregroundStyle(Color.vyrethFlare)
                    Button(hub.blob.savedTerms.contains(termId) ? "Saved" : "Save term") {
                        hub.vyrethToggleSavedTerm(termId)
                    }
                    .foregroundStyle(Color.vyrethPaper)
                } else {
                    Text(term?.unlock ?? "Keep working to open this term.")
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                }
                let films = hub.vyrethFilms(for: termId)
                if !films.isEmpty {
                    Text("Seen in")
                        .font(.headline)
                        .foregroundStyle(Color.vyrethPaper)
                    ForEach(films) { film in
                        NavigationLink(value: VyrethPath.diaryDetail(film.id)) {
                            Text(film.title)
                                .foregroundStyle(Color.vyrethFlare)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(16)
        }
        .onAppear { if open { hub.vyrethOpenTerm(termId) } }
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }
}

struct AurelStudioLobby: View {
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var slot: Int?
    @State private var caption = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Studio lobby")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                Text("Pin an unlocked poster and add your own caption under the frame.")
                    .foregroundStyle(Color.vyrethMist)
                    .fixedSize(horizontal: false, vertical: true)
                let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(hub.blob.pins) { pin in
                        Button {
                            slot = pin.id
                            caption = pin.caption
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                if let poster = VyrethCatalog.book.posters.first(where: { $0.id == pin.posterId }) {
                                    VyrethPosterArt(slot: pin.id + poster.id.hashValue)
                                        .frame(height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    Text(poster.name)
                                        .font(.caption)
                                        .foregroundStyle(Color.vyrethPaper)
                                        .fixedSize(horizontal: false, vertical: true)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.vyrethMist.opacity(0.4), lineWidth: 1)
                                        .frame(height: 120)
                                    Text("Empty frame")
                                        .font(.caption)
                                        .foregroundStyle(Color.vyrethMist)
                                }
                                Text(pin.caption.isEmpty ? "Add a caption" : pin.caption)
                                    .font(.footnote)
                                    .foregroundStyle(Color.vyrethPaper)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .sheet(item: Binding(get: { slot.map { VyrethSlotWrap(id: $0) } }, set: { slot = $0?.id })) { wrap in
            lobbySheet(wrap.id)
        }
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen(image: "studio_lobby", opacity: 0.45)
    }

    private func lobbySheet(_ index: Int) -> some View {
        let unlocked = VyrethCatalog.book.posters.filter { hub.vyrethHas("poster", $0.id) }
        return ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Choose a poster")
                    .font(.headline)
                    .foregroundStyle(Color.vyrethPaper)
                if unlocked.isEmpty {
                    Text("Earn a poster from a rank, a streak milestone, or the weekly festival.")
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(unlocked) { poster in
                    Button(poster.name) {
                        hub.vyrethPin(slot: index, posterId: poster.id, caption: caption)
                    }
                    .foregroundStyle(Color.vyrethFlare)
                }
                TextField("Caption", text: $caption)
                    .foregroundStyle(Color.vyrethPaper)
                    .padding(10)
                    .background { RoundedRectangle(cornerRadius: 12).fill(Color.vyrethPanel) }
                Button("Save caption") {
                    let current = hub.blob.pins.first { $0.id == index }?.posterId ?? ""
                    hub.vyrethPin(slot: index, posterId: current, caption: caption)
                    slot = nil
                }
                .foregroundStyle(Color.vyrethPaper)
                Button("Clear frame") {
                    hub.vyrethPin(slot: index, posterId: "", caption: "")
                    slot = nil
                }
                .foregroundStyle(Color.vyrethEmber)
            }
            .padding(16)
        }
        .vyrethKeysAway()
        .vyrethScreen()
    }
}

struct VyrethSlotWrap: Identifiable {
    var id: Int
}

struct AurelBadgeHall: View {
    @EnvironmentObject private var hub: VyrethLedgerHub

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Achievements")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                let recent = hub.blob.badges.sorted { $0.value > $1.value }.prefix(3)
                if !recent.isEmpty {
                    Text("Recently unlocked")
                        .font(.headline)
                        .foregroundStyle(Color.vyrethPaper)
                    ForEach(Array(recent), id: \.key) { item in
                        Text("\(name(item.key)) · \(item.value)")
                            .foregroundStyle(Color.vyrethFlare)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                ForEach(VyrethCatalog.book.badges) { badge in
                    let progress = hub.vyrethBadgeProgress(badge.id)
                    let done = hub.blob.badges[badge.id] != nil
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: done ? "rosette" : "circle.dashed")
                                .foregroundStyle(done ? Color.vyrethFlare : Color.vyrethMist)
                            Text(badge.title)
                                .foregroundStyle(Color.vyrethPaper)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Text(badge.detail)
                            .font(.footnote)
                            .foregroundStyle(Color.vyrethMist)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(min(progress.0, progress.1)) / \(progress.1)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Color.vyrethMist)
                        GeometryReader { geo in
                            Capsule().fill(Color.vyrethMist.opacity(0.2))
                                .overlay(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.vyrethFlare)
                                        .frame(width: geo.size.width * CGFloat(min(1, Double(progress.0) / Double(max(progress.1, 1)))))
                                }
                        }
                        .frame(height: 8)
                    }
                    .vyrethPanel()
                }
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }

    private func name(_ id: String) -> String {
        VyrethCatalog.book.badges.first { $0.id == id }?.title ?? id
    }
}

struct AurelGlossaryIndex: View {
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var query = ""

    private var rows: [VyrethTermLine] {
        VyrethCatalog.book.terms.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) }
            .sorted { $0.title < $1.title }
    }

    var body: some View {
        List {
            TextField("Search terms", text: $query)
                .foregroundStyle(Color.vyrethPaper)
                .listRowBackground(Color.vyrethPanel)
            ForEach(rows) { term in
                NavigationLink(value: VyrethPath.term(term.id)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(term.title)
                            .foregroundStyle(Color.vyrethPaper)
                            .fixedSize(horizontal: false, vertical: true)
                        if hub.vyrethHas("card", term.id) {
                            Text(term.definition)
                                .font(.footnote)
                                .foregroundStyle(Color.vyrethMist)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text(term.unlock)
                                .font(.footnote)
                                .foregroundStyle(Color.vyrethMist)
                                .fixedSize(horizontal: false, vertical: true)
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
        .navigationTitle("Glossary")
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }
}

struct AurelSavedCards: View {
    @EnvironmentObject private var hub: VyrethLedgerHub

    private var bookmarks: [(String, String, String)] {
        var rows: [(String, String, String)] = []
        for lesson in VyrethCatalog.book.lessons {
            let saved = hub.blob.lessons[lesson.id]?.bookmarks ?? []
            for card in lesson.cards where saved.contains(card.id) {
                rows.append((card.id, card.title, lesson.id))
            }
        }
        return rows
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Saved cards")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                if !hub.vyrethReviewDeck().isEmpty {
                    NavigationLink(value: VyrethPath.review) {
                        Text("Review saved cards")
                            .foregroundStyle(Color.vyrethFlare)
                            .fixedSize(horizontal: false, vertical: true)
                            .vyrethPanel()
                    }
                    .buttonStyle(.plain)
                }
                if bookmarks.isEmpty && hub.blob.savedTerms.isEmpty {
                    Text("Bookmark a lesson card or save a vault term and it will wait here.")
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(bookmarks, id: \.0) { item in
                    NavigationLink(value: VyrethPath.lesson(item.2)) {
                        Text(item.1)
                            .foregroundStyle(Color.vyrethPaper)
                            .fixedSize(horizontal: false, vertical: true)
                            .vyrethPanel()
                    }
                    .buttonStyle(.plain)
                }
                ForEach(hub.blob.savedTerms, id: \.self) { id in
                    if let term = VyrethCatalog.book.vyrethTerm(id) {
                        NavigationLink(value: VyrethPath.term(id)) {
                            Text(term.title)
                                .foregroundStyle(Color.vyrethPaper)
                                .fixedSize(horizontal: false, vertical: true)
                                .vyrethPanel()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }
}

struct AurelCardReview: View {
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var queue: [VyrethReviewCard] = []
    @State private var revealed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Review")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                if queue.isEmpty {
                    Text("The queue is clear. Bookmark a lesson card or save a term and it will wait here.")
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("\(queue.count) left")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Color.vyrethMist)
                    Text(queue[0].title)
                        .font(.system(.title, design: .serif).weight(.bold))
                        .foregroundStyle(Color.vyrethPaper)
                        .fixedSize(horizontal: false, vertical: true)
                    if revealed {
                        Text(queue[0].body)
                            .foregroundStyle(Color.vyrethMist)
                            .fixedSize(horizontal: false, vertical: true)
                        VyrethFlareButton(title: "Remember") { keep() }
                        VyrethQuietButton(title: "Again") { again() }
                    } else {
                        Text("Reveal the definition when you are ready.")
                            .foregroundStyle(Color.vyrethMist)
                            .fixedSize(horizontal: false, vertical: true)
                        VyrethFlareButton(title: "Reveal") {
                            if hub.motionQuiet {
                                revealed = true
                            } else {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { revealed = true }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .onAppear {
            if queue.isEmpty { queue = hub.vyrethReviewDeck() }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }

    private func keep() {
        guard !queue.isEmpty else { return }
        queue.removeFirst()
        revealed = false
        VyrethHaptic.success(hub.blob.profile.haptics)
    }

    private func again() {
        guard !queue.isEmpty else { return }
        let card = queue.removeFirst()
        queue.append(card)
        revealed = false
        VyrethHaptic.tap(hub.blob.profile.haptics)
    }
}

struct SableSettingsPane: View {
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var remind: Bool = true
    @State private var risk: Bool = true
    @State private var haptics: Bool = true
    @State private var reduce: Bool = false
    @State private var takes = 2
    @State private var clock = Date()
    @State private var track = 0
    @State private var importing = false
    @State private var confirmErase = false
    @State private var confirmEraseAgain = false
    @State private var exportURL: URL?
    @State private var denied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Settings")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                Toggle("Daily reminder", isOn: $remind)
                    .tint(Color.vyrethFlare)
                    .foregroundStyle(Color.vyrethPaper)
                DatePicker("Reminder time", selection: $clock, displayedComponents: .hourAndMinute)
                    .foregroundStyle(Color.vyrethPaper)
                Toggle("Light at risk reminder", isOn: $risk)
                    .tint(Color.vyrethFlare)
                    .foregroundStyle(Color.vyrethPaper)
                if denied {
                    Text("Reminders are off in system settings.")
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Open system settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundStyle(Color.vyrethFlare)
                }
                Picker("Takes that count a day", selection: $takes) {
                    Text("2").tag(2)
                    Text("3").tag(3)
                    Text("4").tag(4)
                }
                .pickerStyle(.segmented)
                Picker("Active track", selection: $track) {
                    ForEach(VyrethCatalog.book.tracks) { item in
                        Text(item.title).tag(item.id)
                    }
                }
                Toggle("Haptics", isOn: $haptics)
                    .tint(Color.vyrethFlare)
                    .foregroundStyle(Color.vyrethPaper)
                Toggle("Reduce animation", isOn: $reduce)
                    .tint(Color.vyrethFlare)
                    .foregroundStyle(Color.vyrethPaper)
                VyrethFlareButton(title: "Save settings") { save() }
                Text("Privacy")
                    .font(.headline)
                    .foregroundStyle(Color.vyrethPaper)
                Text("Lessons, notes, and progress stay on this device. Export makes a file you can keep. Nothing is uploaded by the studio tools.")
                    .foregroundStyle(Color.vyrethMist)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Rate us") { rateApp() }
                    .foregroundStyle(Color.vyrethPaper)
                Button("Privacy") { openLink(VyrethLinkEnum.privacy) }
                    .foregroundStyle(Color.vyrethPaper)
                Button("Terms") { openLink(VyrethLinkEnum.terms) }
                    .foregroundStyle(Color.vyrethPaper)
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Text("Export my data")
                            .foregroundStyle(Color.vyrethFlare)
                    }
                }
                Button("Import data") { importing = true }
                    .foregroundStyle(Color.vyrethPaper)
                Button("Reset lobby") { hub.vyrethResetLobby() }
                    .foregroundStyle(Color.vyrethMist)
                Button("Reset all progress") { confirmErase = true }
                    .foregroundStyle(Color.vyrethEmber)
                if !hub.importNote.isEmpty {
                    Text(hub.importNote)
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .vyrethKeysAway()
        .onAppear(perform: load)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            if case let .success(url) = result { hub.vyrethImport(url) }
        }
        .alert("Erase everything?", isPresented: $confirmErase) {
            Button("Continue", role: .destructive) { confirmEraseAgain = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears lessons, notes, and streaks stored on this device.")
        }
        .alert("Erase all progress?", isPresented: $confirmEraseAgain) {
            Button("Erase", role: .destructive) { hub.vyrethEraseAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }

    private func load() {
        remind = hub.blob.profile.reminderOn
        risk = hub.blob.profile.riskOn
        haptics = hub.blob.profile.haptics
        reduce = hub.blob.profile.reduceMotion
        takes = hub.blob.profile.takesPerDay
        track = hub.blob.profile.trackId
        var parts = DateComponents()
        parts.hour = hub.blob.profile.reminderHour
        parts.minute = hub.blob.profile.reminderMinute
        clock = Calendar.current.date(from: parts) ?? Date()
        exportURL = hub.vyrethExportURL()
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { denied = settings.authorizationStatus == .denied }
        }
    }

    private func save() {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: clock)
        hub.blob.profile.reminderOn = remind
        hub.blob.profile.riskOn = risk
        hub.blob.profile.haptics = haptics
        hub.blob.profile.reduceMotion = reduce
        hub.blob.profile.takesPerDay = takes
        hub.blob.profile.trackId = track
        hub.blob.profile.reminderHour = parts.hour ?? 19
        hub.blob.profile.reminderMinute = parts.minute ?? 0
        if remind {
            VyrethNotifyBell.vyrethAsk { _ in
                VyrethNotifyBell.vyrethRefresh(hub.blob)
            }
        } else {
            VyrethNotifyBell.vyrethRefresh(hub.blob)
        }
        exportURL = hub.vyrethExportURL()
        hub.objectWillChange.send()
        hub.vyrethWake()
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func openLink(_ raw: String) {
        if let url = URL(string: raw) {
            UIApplication.shared.open(url)
        }
    }
}
