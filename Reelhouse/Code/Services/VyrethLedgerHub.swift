import Foundation
import SwiftUI

@MainActor
final class VyrethLedgerHub: ObservableObject {
    @Published var blob: VyrethLedgerBlob
    @Published var quizOutcome: VyrethQuizOutcome?
    @Published var showCelebration = false
    @Published var showLightSheet = false
    @Published var showRankSheet = false
    @Published var rankTitle = ""
    @Published var burstTick = 0
    @Published var toast: VyrethToastNote?
    @Published var importNote = ""

    private let fileURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("VyrethSlateVault", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent("ledger.json")
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(VyrethLedgerBlob.self, from: data) {
            blob = saved
        } else {
            blob = .fresh()
        }
    }

    var motionQuiet: Bool {
        blob.profile.reduceMotion || UIAccessibility.isReduceMotionEnabled
    }

    var vyrethPassCap: Int {
        blob.reels >= 900 ? 3 : 2
    }

    func vyrethWake() {
        vyrethCloseGaps()
        vyrethRollFestival()
        if blob.profile.onboarded && (blob.streak.light != blob.streak.notedLight || blob.passNotePending) {
            showLightSheet = true
        }
        VyrethNotifyBell.vyrethRefresh(blob)
        vyrethSyncBadges()
        vyrethSave()
    }

    func vyrethAckLight() {
        blob.streak.notedLight = blob.streak.light
        blob.passNotePending = false
        showLightSheet = false
        vyrethSave()
    }

    func vyrethFinishOnboard(track: Int, takes: Int, hour: Int, minute: Int, remind: Bool) {
        blob.profile.trackId = track
        blob.profile.takesPerDay = takes
        blob.profile.reminderHour = hour
        blob.profile.reminderMinute = minute
        blob.profile.reminderOn = remind
        blob.profile.onboarded = true
        blob.streak.notedLight = blob.streak.light
        vyrethSave()
        if remind {
            VyrethNotifyBell.vyrethAsk { [weak self] _ in
                self?.vyrethWake()
            }
        } else {
            vyrethWake()
        }
    }

    func vyrethDay(_ key: String) -> VyrethDayKnot {
        blob.days.first { $0.date == key } ?? .empty(key)
    }

    func vyrethStoreDay(_ day: VyrethDayKnot) {
        if let index = blob.days.firstIndex(where: { $0.date == day.date }) {
            blob.days[index] = day
        } else {
            blob.days.append(day)
        }
    }

    func vyrethTodayLesson() -> VyrethLessonLine? {
        let rows = VyrethCatalog.book.vyrethLessons(track: blob.profile.trackId)
        if let next = rows.first(where: { blob.lessons[$0.id]?.completed != true }) {
            return next
        }
        guard !rows.isEmpty else { return nil }
        return rows[VyrethMixer.dayNumber(VyrethClock.key()) % rows.count]
    }

    func vyrethLessonOpen(_ lesson: VyrethLessonLine) -> Bool {
        let rows = VyrethCatalog.book.vyrethLessons(track: lesson.track)
        guard let index = rows.firstIndex(where: { $0.id == lesson.id }) else { return false }
        if index == 0 { return true }
        return blob.lessons[rows[index - 1].id]?.completed == true
    }

    func vyrethFrameTerm() -> VyrethTermLine? {
        let terms = VyrethCatalog.book.terms
        guard !terms.isEmpty else { return nil }
        return terms[VyrethMixer.dayNumber(VyrethClock.key()) % terms.count]
    }

    func vyrethOpenTerm(_ id: String) {
        vyrethUnlock("card", id)
        if !blob.tally.termsOpened.contains(id) {
            blob.tally.termsOpened.append(id)
        }
        vyrethSyncBadges()
        vyrethSave()
    }

    func vyrethToggleBookmark(lessonId: String, cardId: String) {
        var prog = blob.lessons[lessonId] ?? VyrethLessonProg(completed: false, bestScore: 0, bookmarks: [])
        if prog.bookmarks.contains(cardId) {
            prog.bookmarks.removeAll { $0 == cardId }
        } else {
            prog.bookmarks.append(cardId)
        }
        blob.lessons[lessonId] = prog
        VyrethHaptic.tap(blob.profile.haptics)
        vyrethSave()
    }

    func vyrethScoreLesson(_ lesson: VyrethLessonLine, picks: [Int]) {
        var correct = 0
        var missed: [VyrethMissLine] = []
        for (index, quiz) in lesson.quiz.enumerated() {
            if picks.indices.contains(index), picks[index] == quiz.answer {
                correct += 1
            } else {
                missed.append(VyrethMissLine(id: quiz.id, prompt: quiz.prompt, why: quiz.why))
            }
        }
        let scheduledId = vyrethTodayLesson()?.id
        var prog = blob.lessons[lesson.id] ?? VyrethLessonProg(completed: false, bestScore: 0, bookmarks: [])
        prog.bestScore = max(prog.bestScore, correct)
        var earned = 0
        if correct >= 2 {
            if !prog.completed {
                prog.completed = true
                earned = 20
                vyrethUnlock("card", lesson.termId)
                vyrethUnlock("poster", "poster-0")
            } else if blob.lessonRepeatKey != VyrethClock.key() {
                earned = 5
                blob.lessonRepeatKey = VyrethClock.key()
            }
            blob.lessons[lesson.id] = prog
            if scheduledId == lesson.id {
                vyrethStampTake("lesson", reels: earned)
            } else if earned > 0 {
                vyrethGrantReels(earned)
                vyrethToast("Checkpoint passed", "\(earned) Reels added to your total.")
                vyrethSyncBadges()
                vyrethSave()
            } else {
                vyrethSyncBadges()
                vyrethSave()
            }
        } else {
            blob.lessons[lesson.id] = prog
            VyrethHaptic.warn(blob.profile.haptics)
            vyrethSave()
        }
        quizOutcome = VyrethQuizOutcome(lessonId: lesson.id, score: correct, reels: earned, missed: missed)
        if correct >= 2 {
            VyrethHaptic.success(blob.profile.haptics)
        }
    }

    func vyrethFinishSpotter(score: Int, perfect: Bool, detail: [String: Int]) {
        blob.tally.spotterRounds += 1
        if perfect { blob.tally.perfectRounds += 1 }
        let today = VyrethClock.key()
        if blob.spotterReelKey != today {
            blob.spotterReelKey = today
            blob.spotterReelRounds = 0
        }
        var reels = 0
        if blob.spotterReelRounds < 3 {
            reels = min(25, score + (perfect ? 5 : 0))
            blob.spotterReelRounds += 1
        }
        blob.attempts.append(VyrethAttemptKnot(id: UUID().uuidString, tool: "spotter", date: today, score: score, detail: detail))
        if !vyrethDay(today).spotter {
            vyrethStampTake("spotter", reels: reels)
        } else if reels > 0 {
            vyrethGrantReels(reels)
            vyrethToast("Round saved", "\(reels) Reels from this round.")
            vyrethSyncBadges()
            vyrethSave()
        } else {
            vyrethToast("Round saved", "Practice score is stored. Reel rewards pause after three rounds today.")
            vyrethSyncBadges()
            vyrethSave()
        }
    }

    func vyrethFinishComposer(briefId: String, score: Int) {
        let previous = blob.composerBests[briefId] ?? 0
        if score > previous { blob.composerBests[briefId] = score }
        let today = VyrethClock.key()
        let onSlate = VyrethSlate.kinds(blob.extra).contains("composer")
        if onSlate && !vyrethDay(today).composer {
            vyrethStampTake("composer", reels: 15)
            return
        }
        if vyrethDay(today).spotter && !vyrethDay(today).composer {
            var day = vyrethDay(today)
            day.composer = true
            vyrethStoreDay(day)
            vyrethGrantReels(15)
            vyrethToast("Bonus frame", "15 Reels for today's framing bonus.")
        } else {
            vyrethToast("Frame saved", "Your best score for this brief is kept.")
        }
        vyrethSyncBadges()
        vyrethSave()
    }

    func vyrethPrompt() -> (genre: String, person: String, obstacle: String, twist: String, stakes: String) {
        let book = VyrethCatalog.book
        let bumped = blob.loglineRerollKey == VyrethClock.key()
        let number = VyrethMixer.dayNumber(VyrethClock.key()) + (bumped ? 19 : 0)
        func pick(_ list: [String], salt: Int) -> String {
            guard !list.isEmpty else { return "An original idea" }
            let mixed = abs(number * salt + salt * 13)
            return list[mixed % list.count]
        }
        return (pick(book.genres, salt: 3), pick(book.protagonists, salt: 5), pick(book.obstacles, salt: 7), pick(book.twists, salt: 11), pick(book.stakes, salt: 13))
    }

    func vyrethRerollPrompt() -> Bool {
        let today = VyrethClock.key()
        if blob.loglineRerollKey == today { return false }
        blob.loglineRerollKey = today
        vyrethSave()
        return true
    }

    func vyrethTodayBrief() -> VyrethBriefLine? {
        let briefs = VyrethCatalog.book.briefs
        guard !briefs.isEmpty else { return nil }
        return briefs[VyrethMixer.dayNumber(VyrethClock.key()) % briefs.count]
    }

    func vyrethSaveLogline(_ entry: VyrethLoglineKnot, counts: Bool) {
        if let index = blob.loglines.firstIndex(where: { $0.id == entry.id }) {
            blob.loglines[index] = entry
        } else {
            blob.loglines.append(entry)
        }
        let marks = entry.checks.filter { $0 }.count
        if counts && marks >= 4 && !vyrethDay(VyrethClock.key()).logline {
            vyrethStampTake("logline", reels: 20)
        } else {
            vyrethToast("Idea saved", "It is stored in the script pad.")
            vyrethSyncBadges()
            vyrethSave()
        }
    }

    func vyrethDeleteLogline(_ id: String) {
        blob.loglines.removeAll { $0.id == id }
        blob.extra.shots[id] = nil
        vyrethSave()
    }

    func vyrethSaveShots(_ id: String, _ shots: [VyrethShotKnot], announce: Bool = true) {
        blob.extra.shots[id] = shots
        let filled = shots.filter(\.filled).count >= 6
        let today = VyrethClock.key()
        let onSlate = VyrethSlate.kinds(blob.extra).contains("board")
        if filled && onSlate && !blob.extra.boardDays.contains(today) {
            vyrethStampTake("board", reels: 15)
        } else if announce {
            vyrethToast("Shot list saved", filled ? "Six frames are on this logline." : "The frames you set are stored with the idea.")
            vyrethSyncBadges()
            vyrethSave()
        } else {
            vyrethSyncBadges()
            vyrethSave()
        }
    }

    func vyrethSaveDiary(_ entry: VyrethDiaryKnot, fromTake: Bool, termId: String = "") {
        if let index = blob.diary.firstIndex(where: { $0.id == entry.id }) {
            blob.diary[index] = entry
        } else {
            blob.diary.append(entry)
        }
        if termId.isEmpty {
            blob.extra.diaryTerms[entry.id] = nil
        } else {
            blob.extra.diaryTerms[entry.id] = termId
        }
        if fromTake && !vyrethDay(VyrethClock.key()).diary {
            vyrethStampTake("diary", reels: 15)
        } else if !vyrethDay(VyrethClock.key()).diary && fromTake == false {
            vyrethStampTake("diary", reels: 15)
        } else {
            vyrethToast("Entry saved", "Your watch note is in the diary.")
            vyrethSyncBadges()
            vyrethSave()
        }
    }

    func vyrethDeleteDiary(_ id: String) {
        blob.diary.removeAll { $0.id == id }
        blob.extra.diaryTerms[id] = nil
        vyrethSave()
    }

    func vyrethAddWatch(title: String, note: String) -> Bool {
        guard blob.watch.count < 200 else { return false }
        let order = (blob.watch.map(\.order).max() ?? -1) + 1
        blob.watch.append(VyrethWatchKnot(id: UUID().uuidString, title: title, note: note, order: order))
        vyrethSyncBadges()
        vyrethSave()
        return true
    }

    func vyrethMoveWatch(from: IndexSet, to: Int) {
        var rows = blob.watch.sorted { $0.order < $1.order }
        rows.move(fromOffsets: from, toOffset: to)
        for index in rows.indices { rows[index].order = index }
        blob.watch = rows
        vyrethSave()
    }

    func vyrethDeleteWatch(_ id: String) {
        blob.watch.removeAll { $0.id == id }
        vyrethSave()
    }

    func vyrethToggleSavedTerm(_ id: String) {
        if blob.savedTerms.contains(id) {
            blob.savedTerms.removeAll { $0 == id }
        } else {
            blob.savedTerms.append(id)
        }
        vyrethSave()
    }

    func vyrethPin(slot: Int, posterId: String, caption: String) {
        guard slot >= 0, slot < blob.pins.count else { return }
        blob.pins[slot].posterId = posterId
        blob.pins[slot].caption = caption
        vyrethSave()
    }

    func vyrethResetLobby() {
        blob.pins = (0..<6).map { VyrethPinKnot(id: $0, posterId: "", caption: "") }
        vyrethSave()
    }

    func vyrethHas(_ kind: String, _ key: String) -> Bool {
        blob.unlocks.contains { $0.kind == kind && $0.key == key }
    }

    func vyrethUnlock(_ kind: String, _ key: String) {
        guard !vyrethHas(kind, key) else { return }
        blob.unlocks.append(VyrethUnlockKnot(id: "\(kind)|\(key)", kind: kind, key: key, at: VyrethClock.key()))
        burstTick += 1
        VyrethHaptic.rigid(blob.profile.haptics)
    }

    func vyrethGrantReels(_ amount: Int) {
        guard amount > 0 else { return }
        let before = VyrethRankTable.step(for: blob.reels)
        blob.reels += amount
        var day = vyrethDay(VyrethClock.key())
        day.reels += amount
        vyrethStoreDay(day)
        let after = VyrethRankTable.step(for: blob.reels)
        if after.index > before.index {
            rankTitle = after.name
            showRankSheet = true
            burstTick += 1
            vyrethApplyRankPerk(after.index)
            VyrethHaptic.success(blob.profile.haptics)
        }
    }

    func vyrethStampTake(_ kind: String, reels: Int) {
        let today = VyrethClock.key()
        var day = vyrethDay(today)
        var fresh = false
        switch kind {
        case "lesson":
            fresh = !day.lesson
            day.lesson = true
        case "spotter":
            fresh = !day.spotter
            day.spotter = true
        case "logline":
            fresh = !day.logline
            day.logline = true
        case "composer":
            fresh = !day.composer
            day.composer = true
        case "board":
            fresh = !blob.extra.boardDays.contains(today)
            if fresh { blob.extra.boardDays.append(today) }
        default:
            fresh = !day.diary
            day.diary = true
        }
        vyrethStoreDay(day)
        if reels > 0 { vyrethGrantReels(reels) }
        if fresh {
            let hour = Calendar.current.component(.hour, from: Date())
            if hour >= 22 { blob.tally.nightOwl = true }
            if hour < 8 { blob.tally.earlyBird = true }
            vyrethAddFestivalTake()
        }
        day = vyrethDay(today)
        let slots = VyrethSlate.kinds(blob.extra)
        let slateDone = slots.allSatisfy { VyrethSlate.done($0, day: day, extra: blob.extra) }
        if slateDone && !day.fullSlate {
            day.fullSlate = true
            vyrethStoreDay(day)
            blob.tally.fullSlates += 1
            if VyrethClock.weekdayIndex() >= 5 { blob.tally.weekendSlate = true }
            vyrethGrantReels(25)
            showCelebration = true
        } else if reels > 0 || fresh {
            vyrethToast("Take complete", reels > 0 ? "\(reels) Reels landed in your total." : "This Take is marked for today.")
        }
        vyrethMarkCountedIfReady()
        vyrethSyncBadges()
        vyrethSave()
        if vyrethDay(today).counted {
            VyrethNotifyBell.vyrethCancelRisk()
        }
    }

    func vyrethMarkCountedIfReady() {
        let today = VyrethClock.key()
        var day = vyrethDay(today)
        let slots = VyrethSlate.kinds(blob.extra)
        let done = slots.filter { VyrethSlate.done($0, day: day, extra: blob.extra) }.count
        guard done >= blob.profile.takesPerDay, !day.counted else { return }
        if blob.streak.light == "out" { blob.streak.current = 0 }
        blob.streak.current += 1
        blob.streak.best = max(blob.streak.best, blob.streak.current)
        blob.streak.lastCounted = today
        blob.streak.light = "bright"
        blob.streak.notedLight = "bright"
        if blob.streak.current.isMultiple(of: 7), blob.streak.passes < vyrethPassCap {
            blob.streak.passes += 1
            blob.tally.passesEarned += 1
        }
        day.counted = true
        vyrethStoreDay(day)
        vyrethMilestoneUnlocks()
        VyrethHaptic.success(blob.profile.haptics)
    }

    func vyrethSecondsLeft() -> Int {
        let start = VyrethClock.cal.startOfDay(for: Date())
        let next = VyrethClock.cal.date(byAdding: .day, value: 1, to: start) ?? Date()
        return max(0, Int(next.timeIntervalSinceNow))
    }

    func vyrethWeekMarks() -> [(key: String, mark: String)] {
        let monday = VyrethClock.mondayKey()
        let today = VyrethClock.key()
        return (0..<7).map { offset in
            let key = VyrethClock.addDays(monday, offset)
            let day = vyrethDay(key)
            let mark: String
            if key > today {
                mark = "future"
            } else if day.counted {
                mark = "done"
            } else if blob.passDays.contains(key) {
                mark = "pass"
            } else if key == today {
                mark = "today"
            } else {
                mark = "miss"
            }
            return (key, mark)
        }
    }

    func vyrethLightCopy() -> String {
        var lines: [String] = []
        switch blob.streak.light {
        case "bright":
            lines.append("The projector light is bright. Yesterday was counted, or a rest pass kept the beam steady.")
        case "dim":
            lines.append("The light is dim. One day was missed. Finish enough Takes today and the beam returns.")
        case "flicker":
            lines.append("The light is flickering. Two days were missed. Another missed day clears the current streak. Your best streak stays.")
        default:
            lines.append("The light is out. Three or more days were missed, so the current streak is back at zero. Your best streak is still saved.")
        }
        if blob.passNotePending {
            lines.append("A rest day pass covered a missed day, so the light was allowed to stay bright.")
        }
        return lines.joined(separator: " ")
    }

    func vyrethExportURL() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(blob) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("studio-ledger.json")
        try? data.write(to: url, options: .atomic)
        return url
    }

    func vyrethImport(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url),
              let incoming = try? JSONDecoder().decode(VyrethLedgerBlob.self, from: data) else {
            importNote = "That file could not be read as a studio ledger."
            return
        }
        blob = incoming
        vyrethSave()
        importNote = "Your ledger replaced the one on this device."
        vyrethWake()
    }

    func vyrethEraseAll() {
        blob = .fresh()
        quizOutcome = nil
        showCelebration = false
        showLightSheet = false
        showRankSheet = false
        toast = nil
        try? FileManager.default.removeItem(at: fileURL)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        vyrethSave()
    }

    func vyrethBadgeProgress(_ id: String) -> (Int, Int) {
        switch id {
        case "first-slate": return (blob.tally.fullSlates, 1)
        case "light-3": return (blob.streak.best, 3)
        case "light-7": return (blob.streak.best, 7)
        case "light-14": return (blob.streak.best, 14)
        case "light-30": return (blob.streak.best, 30)
        case "light-60": return (blob.streak.best, 60)
        case "light-100": return (blob.streak.best, 100)
        case "full-5": return (blob.tally.fullSlates, 5)
        case "perfect-3": return (blob.tally.perfectRounds, 3)
        case "composer-95": return (blob.composerBests.values.max() ?? 0, 95)
        case "diary-10": return (blob.diary.count, 10)
        case "lines-25": return (blob.loglines.count, 25)
        case "track-1": return (vyrethFinishedTracks(), 1)
        case "track-all": return (vyrethFinishedTracks(), 6)
        case "night-owl": return (blob.tally.nightOwl ? 1 : 0, 1)
        case "early-bird": return (blob.tally.earlyBird ? 1 : 0, 1)
        case "weekend": return (blob.tally.weekendSlate ? 1 : 0, 1)
        case "lesson-1": return (blob.lessons.values.filter(\.completed).count, 1)
        case "lesson-10": return (blob.lessons.values.filter(\.completed).count, 10)
        case "lesson-all": return (blob.lessons.values.filter(\.completed).count, 36)
        case "diary-1": return (blob.diary.count, 1)
        case "watch-10": return (blob.watch.count, 10)
        case "terms-10": return (blob.tally.termsOpened.count, 10)
        case "vault-12": return (blob.unlocks.filter { $0.kind == "card" }.count, 12)
        case "vault-all": return (blob.unlocks.filter { $0.kind == "card" }.count, 48)
        case "rank-editor": return (min(blob.reels, 1600), 1600)
        case "rank-auteur": return (min(blob.reels, 4000), 4000)
        case "spotter-50": return (blob.tally.spotterRounds, 50)
        case "pad-5": return (blob.loglines.count, 5)
        case "pass-earned": return (blob.tally.passesEarned, 1)
        default: return (0, 1)
        }
    }

    func vyrethSetSlate(slot: Int, kind: String) {
        if slot < 0 || kind.isEmpty {
            blob.extra.slateSlot = -1
            blob.extra.slateKind = ""
        } else {
            blob.extra.slateSlot = slot
            blob.extra.slateKind = kind
        }
        VyrethHaptic.tap(blob.profile.haptics)
        vyrethSave()
    }

    func vyrethSlateProgress() -> (done: Int, total: Int) {
        let day = vyrethDay(VyrethClock.key())
        let slots = VyrethSlate.kinds(blob.extra)
        let done = slots.filter { VyrethSlate.done($0, day: day, extra: blob.extra) }.count
        return (done, slots.count)
    }

    func vyrethSpotterPool() -> [String] {
        var pool = ["Extreme Wide", "Wide", "Full", "Medium", "Medium Close-Up", "Close-Up", "Extreme Close-Up", "Over-the-Shoulder", "Low Angle", "High Angle"]
        if blob.tally.spotterRounds >= 10 { pool.append("Dutch Angle") }
        return pool
    }

    func vyrethWeakKinds() -> [String] {
        let pool = Set(vyrethSpotterPool())
        return vyrethTypeAccuracy()
            .filter { pool.contains($0.0) && $0.2 >= 2 && $0.1 * 2 < $0.2 }
            .sorted { Double($0.1) / Double(max($0.2, 1)) < Double($1.1) / Double(max($1.2, 1)) }
            .map(\.0)
    }

    func vyrethWeakShot() -> (name: String, hits: Int, total: Int)? {
        let names = Set(vyrethWeakKinds())
        return vyrethTypeAccuracy()
            .filter { names.contains($0.0) }
            .sorted { Double($0.1) / Double(max($0.2, 1)) < Double($1.1) / Double(max($1.2, 1)) }
            .first
            .map { ($0.0, $0.1, $0.2) }
    }

    func vyrethReviewDeck() -> [VyrethReviewCard] {
        var rows: [VyrethReviewCard] = []
        for lesson in VyrethCatalog.book.lessons {
            let saved = blob.lessons[lesson.id]?.bookmarks ?? []
            for card in lesson.cards where saved.contains(card.id) {
                rows.append(VyrethReviewCard(id: "card-\(card.id)", title: card.title, body: card.body))
            }
        }
        for id in blob.savedTerms {
            if let term = VyrethCatalog.book.vyrethTerm(id) {
                rows.append(VyrethReviewCard(id: "term-\(id)", title: term.title, body: term.definition))
            }
        }
        return rows
    }

    func vyrethFilms(for termId: String) -> [VyrethDiaryKnot] {
        blob.diary.filter { blob.extra.diaryTerms[$0.id] == termId }
    }

    func vyrethShotFill(_ id: String) -> Int {
        (blob.extra.shots[id] ?? []).filter(\.filled).count
    }

    func vyrethFestivalCategory() -> String {
        blob.extra.weekRules[blob.festival.weekStart] ?? ""
    }

    func vyrethRuleBrief() -> VyrethBriefLine? {
        let category = vyrethFestivalCategory()
        let matches = VyrethCatalog.book.briefs.filter { $0.category == category }
        guard !matches.isEmpty else { return nil }
        return matches[VyrethMixer.dayNumber(blob.festival.weekStart) % matches.count]
    }

    func vyrethSpotterBest() -> Int {
        blob.attempts.filter { $0.tool == "spotter" }.map(\.score).max() ?? 0
    }

    func vyrethTypeAccuracy() -> [(String, Int, Int)] {
        var hit: [String: Int] = [:]
        var total: [String: Int] = [:]
        for attempt in blob.attempts where attempt.tool == "spotter" {
            for (key, value) in attempt.detail {
                total[key, default: 0] += 1
                if value > 0 { hit[key, default: 0] += 1 }
            }
        }
        return total.keys.sorted().map { ($0, hit[$0] ?? 0, total[$0] ?? 0) }
    }

    func vyrethRecommendTool() -> String {
        let monday = VyrethClock.mondayKey()
        func count(_ tool: String) -> Int {
            blob.attempts.filter { $0.tool == tool && $0.date >= monday }.count
        }
        let rows = [("Shot Spotter", count("spotter")), ("Frame Composer", count("composer")), ("Logline Lab", blob.loglines.filter { $0.updated >= monday }.count)]
        return rows.min { $0.1 < $1.1 }?.0 ?? "Shot Spotter"
    }

    private func vyrethFinishedTracks() -> Int {
        (0..<6).filter { track in
            let rows = VyrethCatalog.book.vyrethLessons(track: track)
            return !rows.isEmpty && rows.allSatisfy { blob.lessons[$0.id]?.completed == true }
        }.count
    }

    private func vyrethCloseGaps() {
        let today = VyrethClock.key()
        if !blob.streak.lastCounted.isEmpty, VyrethClock.dayDelta(today, blob.streak.lastCounted) > 0 {
            blob.streak.light = blob.streak.current > 0 ? "bright" : "out"
            return
        }
        let through = VyrethClock.addDays(today, -1)
        var cursor = blob.streak.sealedThrough
        if cursor.isEmpty { cursor = VyrethClock.addDays(blob.profile.installKey, -1) }
        var guardrail = 0
        while VyrethClock.dayDelta(cursor, through) > 0 && guardrail < 400 {
            cursor = VyrethClock.addDays(cursor, 1)
            vyrethSeal(cursor)
            guardrail += 1
        }
        blob.streak.sealedThrough = through
        vyrethPaintLight(today)
    }

    private func vyrethSeal(_ day: String) {
        guard !blob.streak.lastCounted.isEmpty else { return }
        if VyrethClock.dayDelta(blob.streak.lastCounted, day) <= 0 { return }
        if blob.streak.passes > 0 {
            blob.streak.passes -= 1
            blob.streak.lastCounted = day
            if !blob.passDays.contains(day) { blob.passDays.append(day) }
            blob.passNotePending = true
        }
    }

    private func vyrethPaintLight(_ today: String) {
        guard !blob.streak.lastCounted.isEmpty else {
            blob.streak.light = "out"
            return
        }
        let gap = VyrethClock.dayDelta(blob.streak.lastCounted, today)
        if gap <= 1 {
            blob.streak.light = "bright"
        } else if gap == 2 {
            blob.streak.light = "dim"
        } else if gap == 3 {
            blob.streak.light = "flicker"
        } else {
            blob.streak.current = 0
            blob.streak.light = "out"
        }
    }

    private func vyrethRollFestival() {
        let monday = VyrethClock.mondayKey()
        if blob.festival.weekStart != monday {
            if !blob.festival.weekStart.isEmpty {
                blob.festivalHistory.append(blob.festival)
            }
            blob.festival = VyrethFestivalKnot(weekStart: monday, takes: 0, tier: 0)
        }
        vyrethAssignWeekRule(blob.festival.weekStart)
    }

    private func vyrethAssignWeekRule(_ monday: String) {
        guard blob.extra.weekRules[monday] == nil else { return }
        let categories = Array(Set(VyrethCatalog.book.briefs.map(\.category))).sorted()
        guard !categories.isEmpty else { return }
        blob.extra.weekRules[monday] = categories[VyrethMixer.dayNumber(monday) % categories.count]
    }

    private func vyrethAddFestivalTake() {
        vyrethRollFestival()
        blob.festival.takes += 1
        let steps: [(Int, Int, Int, String)] = [(8, 1, 20, "poster-4"), (14, 2, 40, "poster-5"), (20, 3, 80, "poster-6")]
        for step in steps where blob.festival.takes >= step.0 && blob.festival.tier < step.1 {
            blob.festival.tier = step.1
            vyrethGrantReels(step.2)
            vyrethUnlock("poster", step.3)
        }
    }

    private func vyrethMilestoneUnlocks() {
        let pairs = [(3, "rack-focus"), (7, "jump-cut"), (14, "match-cut"), (30, "chiaroscuro"), (60, "dolly-zoom"), (100, "cold-open")]
        for pair in pairs where blob.streak.current >= pair.0 {
            vyrethUnlock("card", pair.1)
        }
        if blob.streak.current >= 7 { vyrethUnlock("poster", "poster-3") }
        if blob.streak.current >= 14 { vyrethUnlock("poster", "poster-8") }
        if blob.streak.current >= 30 { vyrethUnlock("poster", "poster-10") }
    }

    private func vyrethApplyRankPerk(_ index: Int) {
        if index >= 1 {
            vyrethUnlock("poster", "poster-1")
            vyrethUnlock("card", "macguffin")
        }
        if index >= 2 { vyrethUnlock("poster", "poster-2") }
        if index >= 4 {
            vyrethUnlock("poster", "poster-7")
            vyrethUnlock("card", "dutch-angle")
        }
        if index >= 5 {
            vyrethUnlock("poster", "poster-9")
            vyrethUnlock("card", "eyeline")
        }
        if index >= 6 { vyrethUnlock("poster", "poster-11") }
    }

    private func vyrethSyncBadges() {
        for badge in VyrethCatalog.book.badges {
            let progress = vyrethBadgeProgress(badge.id)
            if progress.0 >= progress.1, blob.badges[badge.id] == nil {
                blob.badges[badge.id] = VyrethClock.key()
                burstTick += 1
                if badge.id == "perfect-3" { vyrethUnlock("card", "practical") }
                if badge.id == "composer-95" { vyrethUnlock("card", "l-cut") }
                if badge.id == "diary-10" { vyrethUnlock("card", "insert-shot") }
            }
        }
    }

    private func vyrethToast(_ title: String, _ detail: String) {
        toast = VyrethToastNote(id: UUID().uuidString, title: title, detail: detail)
    }

    private func vyrethSave() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(blob) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
