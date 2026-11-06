import SwiftUI

struct MeldAcademyHall: View {
    @EnvironmentObject private var hub: VyrethLedgerHub

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Academy")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                    .fixedSize(horizontal: false, vertical: true)
                VyrethBannerStrip(name: "banner_filmstrip")
                ring
                ForEach(VyrethCatalog.book.tracks) { track in
                    NavigationLink(value: VyrethPath.track(track.id)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(track.title)
                                .font(.system(.title3, design: .serif).weight(.semibold))
                                .foregroundStyle(Color.vyrethPaper)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(track.blurb)
                                .font(.subheadline)
                                .foregroundStyle(Color.vyrethMist)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(progressLine(track.id))
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(Color.vyrethFlare)
                        }
                        .vyrethPanel()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .vyrethScreen()
    }

    private var ring: some View {
        let done = hub.blob.lessons.values.filter(\.completed).count
        let ratio = Double(done) / 36
        return HStack(spacing: 14) {
            ZStack {
                Circle().stroke(Color.vyrethMist.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: ratio)
                    .stroke(Color.vyrethFlare, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(done)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.vyrethPaper)
            }
            .frame(width: 72, height: 72)
            Text("\(done) of 36 lessons passed. Tracks stay open, and lessons inside a track unlock in order.")
                .foregroundStyle(Color.vyrethMist)
                .fixedSize(horizontal: false, vertical: true)
        }
        .vyrethPanel()
    }

    private func progressLine(_ track: Int) -> String {
        let rows = VyrethCatalog.book.vyrethLessons(track: track)
        let done = rows.filter { hub.blob.lessons[$0.id]?.completed == true }.count
        return "\(done) of \(rows.count) passed"
    }
}

struct MeldTrackStrip: View {
    let track: Int
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var lockedNote = ""

    var body: some View {
        let info = VyrethCatalog.book.tracks.first { $0.id == track }
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(info?.title ?? "Track")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                    .fixedSize(horizontal: false, vertical: true)
                Text(info?.blurb ?? "")
                    .foregroundStyle(Color.vyrethMist)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(Array(VyrethCatalog.book.vyrethLessons(track: track).enumerated()), id: \.element.id) { index, lesson in
                    lessonRow(index: index, lesson: lesson)
                }
                if !lockedNote.isEmpty {
                    Text(lockedNote)
                        .foregroundStyle(Color.vyrethEmber)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }

    @ViewBuilder
    private func lessonRow(index: Int, lesson: VyrethLessonLine) -> some View {
        let open = hub.vyrethLessonOpen(lesson)
        let prog = hub.blob.lessons[lesson.id]
        let card = VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(String(format: "%02d", index + 1))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.vyrethFlare)
                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .foregroundStyle(Color.vyrethPaper)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(lesson.minutes) min · best \(prog?.bestScore ?? 0)/3")
                        .font(.footnote)
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: prog?.completed == true ? "checkmark.circle.fill" : (open ? "play.circle" : "lock.fill"))
                    .foregroundStyle(prog?.completed == true ? Color.vyrethFlare : Color.vyrethMist)
            }
        }
        .vyrethPanel()

        if open {
            NavigationLink(value: VyrethPath.lesson(lesson.id)) { card }
                .buttonStyle(.plain)
        } else {
            Button {
                lockedNote = "Finish the previous lesson in this track before opening this one."
                VyrethHaptic.warn(hub.blob.profile.haptics)
            } label: { card }
            .buttonStyle(.plain)
            .accessibilityLabel("\(lesson.title), locked")
        }
    }
}

struct MeldLessonReel: View {
    let lessonId: String
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var page = 0
    @State private var picks: [Int] = []
    @State private var quizStep = 0
    @State private var chosen: Int?
    @State private var showWhy = false
    @State private var finished = false

    private var lesson: VyrethLessonLine? { VyrethCatalog.book.vyrethLesson(lessonId) }

    var body: some View {
        Group {
            if finished, let lesson {
                MeldLessonResult(lesson: lesson) {
                    finished = false
                    page = 0
                    picks = []
                    quizStep = 0
                    chosen = nil
                    showWhy = false
                }
            } else if let lesson {
                reader(lesson)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }

    private func reader(_ lesson: VyrethLessonLine) -> some View {
        VStack(spacing: 0) {
            if page < lesson.cards.count {
                TabView(selection: $page) {
                    ForEach(lesson.cards.indices, id: \.self) { index in
                        ScrollView {
                            card(lesson, index)
                                .padding(16)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                HStack {
                    Button("Previous card") { if page > 0 { page -= 1 } }
                        .foregroundStyle(page == 0 ? Color.vyrethMist : Color.vyrethPaper)
                        .disabled(page == 0)
                    Spacer()
                    Button("Next card") { page += 1 }
                        .foregroundStyle(Color.vyrethFlare)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            } else {
                quiz(lesson)
            }
        }
    }

    private func card(_ lesson: VyrethLessonLine, _ index: Int) -> some View {
        let item = lesson.cards[index]
        let saved = hub.blob.lessons[lesson.id]?.bookmarks.contains(item.id) == true
        return VStack(alignment: .leading, spacing: 12) {
            Text(item.title)
                .font(.system(.title2, design: .serif).weight(.semibold))
                .foregroundStyle(Color.vyrethPaper)
                .fixedSize(horizontal: false, vertical: true)
            if let sketch = item.sketch {
                VyrethSketch(kind: sketch)
            }
            Text(item.body)
                .foregroundStyle(Color.vyrethMist)
                .fixedSize(horizontal: false, vertical: true)
            Button(saved ? "Bookmarked" : "Bookmark card") {
                hub.vyrethToggleBookmark(lessonId: lesson.id, cardId: item.id)
            }
            .foregroundStyle(Color.vyrethFlare)
            .accessibilityLabel(saved ? "Remove bookmark" : "Bookmark card")
        }
        .vyrethPanel()
    }

    private func quiz(_ lesson: VyrethLessonLine) -> some View {
        let question = lesson.quiz[min(quizStep, lesson.quiz.count - 1)]
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Checkpoint \(quizStep + 1) of \(lesson.quiz.count)")
                    .font(.caption)
                    .foregroundStyle(Color.vyrethMist)
                Text(question.prompt)
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundStyle(Color.vyrethPaper)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(question.options.indices, id: \.self) { index in
                    Button {
                        guard chosen == nil else { return }
                        chosen = index
                        showWhy = true
                        picks.append(index)
                        if index == question.answer {
                            VyrethHaptic.success(hub.blob.profile.haptics)
                        } else {
                            VyrethHaptic.warn(hub.blob.profile.haptics)
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: icon(index, answer: question.answer))
                                .foregroundStyle(Color.vyrethFlare)
                            Text(question.options[index])
                                .foregroundStyle(Color.vyrethPaper)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background {
                            RoundedRectangle(cornerRadius: 14).fill(Color.vyrethPanel)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(chosen != nil)
                }
                if showWhy {
                    Text(chosen == question.answer ? "Correct" : "Not quite")
                        .font(.headline)
                        .foregroundStyle(Color.vyrethPaper)
                    Text(question.why)
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                    VyrethFlareButton(title: quizStep + 1 == lesson.quiz.count ? "See result" : "Next question") {
                        if quizStep + 1 == lesson.quiz.count {
                            hub.vyrethScoreLesson(lesson, picks: picks)
                            finished = true
                        } else {
                            quizStep += 1
                            chosen = nil
                            showWhy = false
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func icon(_ index: Int, answer: Int) -> String {
        guard let chosen else { return "circle" }
        if index == answer { return "checkmark.circle.fill" }
        if index == chosen { return "xmark.circle.fill" }
        return "circle"
    }
}

struct MeldLessonResult: View {
    let lesson: VyrethLessonLine
    var retry: () -> Void
    @EnvironmentObject private var hub: VyrethLedgerHub
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let outcome = hub.quizOutcome
        let score = outcome?.score ?? 0
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Lesson result")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                ZStack {
                    Circle().stroke(Color.vyrethMist.opacity(0.2), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: Double(score) / 3)
                        .stroke(score >= 2 ? Color.vyrethFlare : Color.vyrethEmber, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(score)/3")
                        .font(.title2.monospacedDigit())
                        .foregroundStyle(Color.vyrethPaper)
                }
                .frame(width: 96, height: 96)
                Text(score >= 2 ? "Passed. The next lesson in this track is open." : "Two correct answers are needed to pass.")
                    .foregroundStyle(Color.vyrethMist)
                    .fixedSize(horizontal: false, vertical: true)
                if let missed = outcome?.missed, !missed.isEmpty {
                    ForEach(missed) { line in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(line.prompt)
                                .foregroundStyle(Color.vyrethPaper)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(line.why)
                                .foregroundStyle(Color.vyrethMist)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .vyrethPanel()
                    }
                }
                if score >= 2, let next = nextLesson {
                    NavigationLink(value: VyrethPath.lesson(next.id)) {
                        Text("Next lesson")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.vyrethPaper)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(VyrethPressStyle())
                } else if score < 2 {
                    VyrethFlareButton(title: "Try the checkpoint again") { retry() }
                }
                VyrethQuietButton(title: "Back to track") { dismiss() }
            }
            .padding(16)
        }
    }

    private var nextLesson: VyrethLessonLine? {
        let rows = VyrethCatalog.book.vyrethLessons(track: lesson.track)
        guard let index = rows.firstIndex(where: { $0.id == lesson.id }), index + 1 < rows.count else { return nil }
        return rows[index + 1]
    }
}
