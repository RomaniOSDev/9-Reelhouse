import Foundation

enum VyrethClock {
    static var cal: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    static func key(_ date: Date = Date()) -> String {
        let parts = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func date(_ key: String) -> Date {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return Date() }
        return cal.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) ?? Date()
    }

    static func addDays(_ key: String, _ days: Int) -> String {
        let shifted = cal.date(byAdding: .day, value: days, to: date(key)) ?? Date()
        return self.key(shifted)
    }

    static func dayDelta(_ from: String, _ to: String) -> Int {
        let start = cal.startOfDay(for: date(from))
        let end = cal.startOfDay(for: date(to))
        return cal.dateComponents([.day], from: start, to: end).day ?? 0
    }

    static func mondayKey(_ date: Date = Date()) -> String {
        let start = cal.startOfDay(for: date)
        let weekday = cal.component(.weekday, from: start)
        let delta = (weekday + 5) % 7
        let monday = cal.date(byAdding: .day, value: -delta, to: start) ?? start
        return key(monday)
    }

    static func weekdayIndex(_ date: Date = Date()) -> Int {
        (cal.component(.weekday, from: date) + 5) % 7
    }

    static func monthKey(_ date: Date) -> String {
        let parts = cal.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }
}

enum VyrethMixer {
    static func dayNumber(_ key: String) -> Int {
        max(0, VyrethClock.dayDelta("2020-01-06", key))
    }
}

struct VyrethProfileKnot: Codable, Equatable {
    var trackId: Int
    var takesPerDay: Int
    var reminderOn: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var riskOn: Bool
    var haptics: Bool
    var reduceMotion: Bool
    var installKey: String
    var onboarded: Bool
}

struct VyrethStreakKnot: Codable, Equatable {
    var current: Int
    var best: Int
    var passes: Int
    var lastCounted: String
    var light: String
    var notedLight: String
    var sealedThrough: String
}

struct VyrethDayKnot: Codable, Equatable, Identifiable {
    var date: String
    var lesson: Bool
    var spotter: Bool
    var logline: Bool
    var diary: Bool
    var composer: Bool
    var reels: Int
    var fullSlate: Bool
    var counted: Bool
    var id: String { date }

    static func empty(_ date: String) -> VyrethDayKnot {
        VyrethDayKnot(date: date, lesson: false, spotter: false, logline: false, diary: false, composer: false, reels: 0, fullSlate: false, counted: false)
    }
}

struct VyrethLessonProg: Codable, Equatable {
    var completed: Bool
    var bestScore: Int
    var bookmarks: [String]
}

struct VyrethAttemptKnot: Codable, Equatable, Identifiable {
    var id: String
    var tool: String
    var date: String
    var score: Int
    var detail: [String: Int]
}

struct VyrethLoglineKnot: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var genre: String
    var status: String
    var whenLine: String
    var mustLine: String
    var elseLine: String
    var text: String
    var notes: String
    var checks: [Bool]
    var created: String
    var updated: String
}

struct VyrethDiaryKnot: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var year: String
    var watched: String
    var rating: Double
    var place: String
    var moods: [String]
    var noticed: String
    var verdict: String
}

struct VyrethWatchKnot: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var note: String
    var order: Int
}

struct VyrethUnlockKnot: Codable, Equatable, Identifiable, Hashable {
    var id: String
    var kind: String
    var key: String
    var at: String
}

struct VyrethPinKnot: Codable, Equatable, Identifiable {
    var id: Int
    var posterId: String
    var caption: String
}

struct VyrethFestivalKnot: Codable, Equatable, Identifiable {
    var weekStart: String
    var takes: Int
    var tier: Int
    var id: String { weekStart }
}

struct VyrethTallyKnot: Codable, Equatable {
    var perfectRounds: Int
    var nightOwl: Bool
    var earlyBird: Bool
    var weekendSlate: Bool
    var termsOpened: [String]
    var passesEarned: Int
    var fullSlates: Int
    var spotterRounds: Int
}

struct VyrethShotKnot: Codable, Equatable, Identifiable {
    var id: String
    var size: String
    var angle: String
    var move: String

    static func blankSix() -> [VyrethShotKnot] {
        (0..<6).map { VyrethShotKnot(id: "shot-\($0)", size: "", angle: "", move: "") }
    }

    var filled: Bool {
        !size.isEmpty && !angle.isEmpty && !move.isEmpty
    }
}

struct VyrethExtraKnot: Equatable {
    var shots: [String: [VyrethShotKnot]]
    var diaryTerms: [String: String]
    var boardDays: [String]
    var slateSlot: Int
    var slateKind: String
    var weekRules: [String: String]

    static var empty: VyrethExtraKnot {
        VyrethExtraKnot(shots: [:], diaryTerms: [:], boardDays: [], slateSlot: -1, slateKind: "", weekRules: [:])
    }
}

enum VyrethShotWords {
    static let sizes = ["Extreme Wide", "Wide", "Full", "Medium", "Medium Close-Up", "Close-Up", "Extreme Close-Up"]
    static let angles = ["Eye Level", "Low Angle", "High Angle", "Dutch Angle", "Over-the-Shoulder"]
    static let moves = ["Static", "Pan", "Tilt", "Dolly", "Handheld"]
}

enum VyrethSlate {
    static let base = ["lesson", "spotter", "logline", "diary"]

    static func kinds(_ extra: VyrethExtraKnot) -> [String] {
        var slots = base
        if (0..<4).contains(extra.slateSlot), extra.slateKind == "composer" || extra.slateKind == "board" {
            slots[extra.slateSlot] = extra.slateKind
        }
        return slots
    }

    static func done(_ kind: String, day: VyrethDayKnot, extra: VyrethExtraKnot) -> Bool {
        switch kind {
        case "lesson": return day.lesson
        case "spotter": return day.spotter
        case "logline": return day.logline
        case "diary": return day.diary
        case "composer": return day.composer
        case "board": return extra.boardDays.contains(day.date)
        default: return false
        }
    }

    static func title(_ kind: String) -> String {
        switch kind {
        case "lesson": return "Lesson"
        case "spotter": return "Shot Spotter"
        case "logline": return "Logline Lab"
        case "diary": return "Watch note"
        case "composer": return "Frame Composer"
        case "board": return "Shot list"
        default: return kind
        }
    }

    static func reward(_ kind: String) -> String {
        switch kind {
        case "lesson": return "20 Reels"
        case "spotter": return "Up to 25 Reels"
        case "logline": return "20 Reels"
        default: return "15 Reels"
        }
    }
}

struct VyrethReviewCard: Identifiable, Equatable {
    var id: String
    var title: String
    var body: String
}

struct VyrethLedgerBlob: Equatable {
    var profile: VyrethProfileKnot
    var reels: Int
    var days: [VyrethDayKnot]
    var streak: VyrethStreakKnot
    var lessons: [String: VyrethLessonProg]
    var attempts: [VyrethAttemptKnot]
    var composerBests: [String: Int]
    var loglines: [VyrethLoglineKnot]
    var diary: [VyrethDiaryKnot]
    var watch: [VyrethWatchKnot]
    var unlocks: [VyrethUnlockKnot]
    var pins: [VyrethPinKnot]
    var badges: [String: String]
    var festival: VyrethFestivalKnot
    var festivalHistory: [VyrethFestivalKnot]
    var tally: VyrethTallyKnot
    var savedTerms: [String]
    var lessonRepeatKey: String
    var spotterReelKey: String
    var spotterReelRounds: Int
    var loglineRerollKey: String
    var passDays: [String]
    var passNotePending: Bool
    var extra: VyrethExtraKnot

    static func fresh() -> VyrethLedgerBlob {
        let today = VyrethClock.key()
        return VyrethLedgerBlob(
            profile: VyrethProfileKnot(
                trackId: 0,
                takesPerDay: 2,
                reminderOn: true,
                reminderHour: 19,
                reminderMinute: 0,
                riskOn: true,
                haptics: true,
                reduceMotion: false,
                installKey: today,
                onboarded: false
            ),
            reels: 0,
            days: [],
            streak: VyrethStreakKnot(current: 0, best: 0, passes: 0, lastCounted: "", light: "out", notedLight: "out", sealedThrough: VyrethClock.addDays(today, -1)),
            lessons: [:],
            attempts: [],
            composerBests: [:],
            loglines: [],
            diary: [],
            watch: [],
            unlocks: [],
            pins: (0..<6).map { VyrethPinKnot(id: $0, posterId: "", caption: "") },
            badges: [:],
            festival: VyrethFestivalKnot(weekStart: VyrethClock.mondayKey(), takes: 0, tier: 0),
            festivalHistory: [],
            tally: VyrethTallyKnot(perfectRounds: 0, nightOwl: false, earlyBird: false, weekendSlate: false, termsOpened: [], passesEarned: 0, fullSlates: 0, spotterRounds: 0),
            savedTerms: [],
            lessonRepeatKey: "",
            spotterReelKey: "",
            spotterReelRounds: 0,
            loglineRerollKey: "",
            passDays: [],
            passNotePending: false,
            extra: .empty
        )
    }
}

extension VyrethExtraKnot: Codable {
    enum CodingKeys: String, CodingKey {
        case shots, diaryTerms, boardDays, slateSlot, slateKind, weekRules
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        shots = try box.decodeIfPresent([String: [VyrethShotKnot]].self, forKey: .shots) ?? [:]
        diaryTerms = try box.decodeIfPresent([String: String].self, forKey: .diaryTerms) ?? [:]
        boardDays = try box.decodeIfPresent([String].self, forKey: .boardDays) ?? []
        slateSlot = try box.decodeIfPresent(Int.self, forKey: .slateSlot) ?? -1
        slateKind = try box.decodeIfPresent(String.self, forKey: .slateKind) ?? ""
        weekRules = try box.decodeIfPresent([String: String].self, forKey: .weekRules) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var box = encoder.container(keyedBy: CodingKeys.self)
        try box.encode(shots, forKey: .shots)
        try box.encode(diaryTerms, forKey: .diaryTerms)
        try box.encode(boardDays, forKey: .boardDays)
        try box.encode(slateSlot, forKey: .slateSlot)
        try box.encode(slateKind, forKey: .slateKind)
        try box.encode(weekRules, forKey: .weekRules)
    }
}

extension VyrethLedgerBlob: Codable {
    enum CodingKeys: String, CodingKey {
        case profile, reels, days, streak, lessons, attempts, composerBests, loglines, diary, watch, unlocks, pins, badges, festival, festivalHistory, tally, savedTerms, lessonRepeatKey, spotterReelKey, spotterReelRounds, loglineRerollKey, passDays, passNotePending, extra
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        profile = try box.decode(VyrethProfileKnot.self, forKey: .profile)
        reels = try box.decode(Int.self, forKey: .reels)
        days = try box.decode([VyrethDayKnot].self, forKey: .days)
        streak = try box.decode(VyrethStreakKnot.self, forKey: .streak)
        lessons = try box.decode([String: VyrethLessonProg].self, forKey: .lessons)
        attempts = try box.decode([VyrethAttemptKnot].self, forKey: .attempts)
        composerBests = try box.decode([String: Int].self, forKey: .composerBests)
        loglines = try box.decode([VyrethLoglineKnot].self, forKey: .loglines)
        diary = try box.decode([VyrethDiaryKnot].self, forKey: .diary)
        watch = try box.decode([VyrethWatchKnot].self, forKey: .watch)
        unlocks = try box.decode([VyrethUnlockKnot].self, forKey: .unlocks)
        pins = try box.decode([VyrethPinKnot].self, forKey: .pins)
        badges = try box.decode([String: String].self, forKey: .badges)
        festival = try box.decode(VyrethFestivalKnot.self, forKey: .festival)
        festivalHistory = try box.decode([VyrethFestivalKnot].self, forKey: .festivalHistory)
        tally = try box.decode(VyrethTallyKnot.self, forKey: .tally)
        savedTerms = try box.decode([String].self, forKey: .savedTerms)
        lessonRepeatKey = try box.decode(String.self, forKey: .lessonRepeatKey)
        spotterReelKey = try box.decode(String.self, forKey: .spotterReelKey)
        spotterReelRounds = try box.decode(Int.self, forKey: .spotterReelRounds)
        loglineRerollKey = try box.decode(String.self, forKey: .loglineRerollKey)
        passDays = try box.decode([String].self, forKey: .passDays)
        passNotePending = try box.decode(Bool.self, forKey: .passNotePending)
        extra = try box.decodeIfPresent(VyrethExtraKnot.self, forKey: .extra) ?? .empty
    }

    func encode(to encoder: Encoder) throws {
        var box = encoder.container(keyedBy: CodingKeys.self)
        try box.encode(profile, forKey: .profile)
        try box.encode(reels, forKey: .reels)
        try box.encode(days, forKey: .days)
        try box.encode(streak, forKey: .streak)
        try box.encode(lessons, forKey: .lessons)
        try box.encode(attempts, forKey: .attempts)
        try box.encode(composerBests, forKey: .composerBests)
        try box.encode(loglines, forKey: .loglines)
        try box.encode(diary, forKey: .diary)
        try box.encode(watch, forKey: .watch)
        try box.encode(unlocks, forKey: .unlocks)
        try box.encode(pins, forKey: .pins)
        try box.encode(badges, forKey: .badges)
        try box.encode(festival, forKey: .festival)
        try box.encode(festivalHistory, forKey: .festivalHistory)
        try box.encode(tally, forKey: .tally)
        try box.encode(savedTerms, forKey: .savedTerms)
        try box.encode(lessonRepeatKey, forKey: .lessonRepeatKey)
        try box.encode(spotterReelKey, forKey: .spotterReelKey)
        try box.encode(spotterReelRounds, forKey: .spotterReelRounds)
        try box.encode(loglineRerollKey, forKey: .loglineRerollKey)
        try box.encode(passDays, forKey: .passDays)
        try box.encode(passNotePending, forKey: .passNotePending)
        try box.encode(extra, forKey: .extra)
    }
}

struct VyrethTrackLine: Codable, Identifiable, Equatable {
    var id: Int
    var title: String
    var blurb: String
}

struct VyrethCardLine: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var body: String
    var sketch: String?
}

struct VyrethQuizLine: Codable, Identifiable, Equatable {
    var id: String
    var prompt: String
    var options: [String]
    var answer: Int
    var why: String
}

struct VyrethLessonLine: Codable, Identifiable, Equatable {
    var id: String
    var track: Int
    var title: String
    var minutes: Int
    var termId: String
    var cards: [VyrethCardLine]
    var quiz: [VyrethQuizLine]
}

struct VyrethTermLine: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var definition: String
    var tip: String
    var unlock: String
}

struct VyrethBadgeLine: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var detail: String
}

struct VyrethBriefLine: Codable, Identifiable, Equatable {
    var id: String
    var category: String
    var title: String
    var detail: String
    var subjectX: Double
    var subjectY: Double
    var horizon: Double
    var faceRight: Bool
    var headroom: Double
    var lead: Double
}

struct VyrethPosterLine: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var unlock: String
}

struct VyrethBook: Codable, Equatable {
    var tracks: [VyrethTrackLine]
    var lessons: [VyrethLessonLine]
    var terms: [VyrethTermLine]
    var badges: [VyrethBadgeLine]
    var briefs: [VyrethBriefLine]
    var genres: [String]
    var protagonists: [String]
    var obstacles: [String]
    var twists: [String]
    var stakes: [String]
    var reminders: [String]
    var moods: [String]
    var posters: [VyrethPosterLine]

    func vyrethLessons(track: Int) -> [VyrethLessonLine] {
        lessons.filter { $0.track == track }
    }

    func vyrethLesson(_ id: String) -> VyrethLessonLine? {
        lessons.first { $0.id == id }
    }

    func vyrethTerm(_ id: String) -> VyrethTermLine? {
        terms.first { $0.id == id }
    }
}

struct VyrethMissLine: Equatable, Identifiable {
    var id: String
    var prompt: String
    var why: String
}

struct VyrethQuizOutcome: Equatable {
    var lessonId: String
    var score: Int
    var reels: Int
    var missed: [VyrethMissLine]
}

struct VyrethToastNote: Identifiable, Equatable {
    var id: String
    var title: String
    var detail: String
}

struct VyrethRankStep: Equatable {
    var index: Int
    var name: String
    var need: Int
    var next: Int?
}

enum VyrethRankTable {
    static let steps: [(String, Int)] = [
        ("Runner", 0),
        ("Clapper Loader", 150),
        ("Script Reader", 400),
        ("Assistant Director", 900),
        ("Editor", 1600),
        ("Director", 2600),
        ("Auteur", 4000)
    ]

    static func step(for reels: Int) -> VyrethRankStep {
        var current = 0
        for (index, item) in steps.enumerated() where reels >= item.1 {
            current = index
        }
        let next = current + 1 < steps.count ? steps[current + 1].1 : nil
        return VyrethRankStep(index: current, name: steps[current].0, need: steps[current].1, next: next)
    }
}
