import SwiftUI
import Combine

struct KorrinTodayDeck: View {
    var active: Bool
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var now = Date()
    @State private var flipped = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(greeting)
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                    .fixedSize(horizontal: false, vertical: true)
                rankChip
                hero
                slateCard
                if hub.vyrethDay(VyrethClock.key()).spotter {
                    composerBonus
                }
                frameCard
                if !hub.vyrethReviewDeck().isEmpty {
                    NavigationLink(value: VyrethPath.review) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Review saved cards")
                                .font(.headline)
                                .foregroundStyle(Color.vyrethPaper)
                            Text("\(hub.vyrethReviewDeck().count) cards you marked. Flip, then keep or send one back.")
                                .font(.subheadline)
                                .foregroundStyle(Color.vyrethMist)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .vyrethPanel()
                    }
                    .buttonStyle(.plain)
                }
                continueCard
                festivalCard
                weekRow
            }
            .padding(16)
            .padding(.bottom, 12)
        }
        .vyrethScreen(image: "banner_filmstrip", opacity: 0.16)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            if active { now = date }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: now)
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private var rankChip: some View {
        let rank = VyrethRankTable.step(for: hub.blob.reels)
        let span = max(1, (rank.next ?? rank.need) - rank.need)
        let into = min(1, Double(hub.blob.reels - rank.need) / Double(span))
        return HStack(spacing: 10) {
            ZStack {
                Circle().stroke(Color.vyrethMist.opacity(0.25), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: rank.next == nil ? 1 : into)
                    .stroke(Color.vyrethFlare, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(rank.name)
                    .font(.headline)
                    .foregroundStyle(Color.vyrethPaper)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(hub.blob.reels) Reels")
                    .font(.subheadline)
                    .foregroundStyle(Color.vyrethMist)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            KorrinBeam(active: active)
            HStack(alignment: .firstTextBaseline) {
                VyrethCountRoll(value: hub.blob.streak.current, font: .system(size: 42, weight: .bold, design: .serif))
                Text(hub.blob.streak.current == 1 ? "day" : "days")
                    .foregroundStyle(Color.vyrethMist)
            }
            Text(lightTitle)
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(Color.vyrethPaper)
                .fixedSize(horizontal: false, vertical: true)
            Text(countdownLine)
                .font(.subheadline)
                .foregroundStyle(Color.vyrethMist)
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                ForEach(0..<hub.vyrethPassCap, id: \.self) { index in
                    Image(systemName: index < hub.blob.streak.passes ? "ticket.fill" : "ticket")
                        .foregroundStyle(index < hub.blob.streak.passes ? Color.vyrethFlare : Color.vyrethMist)
                        .accessibilityLabel(index < hub.blob.streak.passes ? "Rest pass ready" : "Empty rest pass")
                }
                Text("Rest passes")
                    .font(.caption)
                    .foregroundStyle(Color.vyrethMist)
            }
        }
        .vyrethPanel(strong: true)
    }

    private var lightTitle: String {
        switch hub.blob.streak.light {
        case "bright": return "Light is bright"
        case "dim": return "Light is dim"
        case "flicker": return "Light is flickering"
        default: return "Light is out"
        }
    }

    private var countdownLine: String {
        let left = hub.vyrethSecondsLeft()
        let hours = left / 3600
        let minutes = (left % 3600) / 60
        let day = hub.vyrethDay(VyrethClock.key())
        let done = hub.vyrethSlateProgress().done
        if day.counted {
            return "Today is already counted. Next slate in \(hours)h \(minutes)m."
        }
        let need = max(0, hub.blob.profile.takesPerDay - done)
        if need == 0 {
            return "Enough Takes are done. The day will count when you leave this slate."
        }
        return "\(need) more Take\(need == 1 ? "" : "s") keep the light safe. \(hours)h \(minutes)m remain."
    }

    private var slateCard: some View {
        let day = hub.vyrethDay(VyrethClock.key())
        let slots = VyrethSlate.kinds(hub.blob.extra)
        let flags = slots.map { VyrethSlate.done($0, day: day, extra: hub.blob.extra) }
        return VStack(alignment: .leading, spacing: 12) {
            Text("Daily slate")
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(Color.vyrethPaper)
            if let gap = hub.vyrethWeakShot() {
                Text("\(gap.name) is the miss. The next Shot Spotter round leans on it. \(gap.hits) of \(gap.total) so far.")
                    .font(.subheadline)
                    .foregroundStyle(Color.vyrethFlare)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VyrethSprocket(filled: flags.filter { $0 }.count, total: slots.count)
            ForEach(slots.indices, id: \.self) { index in
                let kind = slots[index]
                let done = flags[index]
                takeRow(index, VyrethSlate.title(kind), done ? "Done today" : slotReward(kind), done)
            }
            slateMenu
        }
        .vyrethPanel()
    }

    private func slotReward(_ kind: String) -> String {
        if kind == "spotter", let gap = hub.vyrethWeakShot() {
            return "\(gap.name) is the gap"
        }
        return VyrethSlate.reward(kind)
    }

    private var slateMenuTitle: String {
        let extra = hub.blob.extra
        guard (0..<4).contains(extra.slateSlot), !extra.slateKind.isEmpty else { return "Replace one slot" }
        let from = VyrethSlate.title(VyrethSlate.base[extra.slateSlot])
        return "\(from) is now \(VyrethSlate.title(extra.slateKind))"
    }

    private var slateMenu: some View {
        Menu {
            Button("Standard slate") { hub.vyrethSetSlate(slot: -1, kind: "") }
            ForEach(VyrethSlate.base.indices, id: \.self) { index in
                Menu("Replace \(VyrethSlate.title(VyrethSlate.base[index]))") {
                    Button("Frame Composer") { hub.vyrethSetSlate(slot: index, kind: "composer") }
                    Button("Shot list") { hub.vyrethSetSlate(slot: index, kind: "board") }
                }
            }
        } label: {
            Text(slateMenuTitle)
                .font(.footnote)
                .foregroundStyle(Color.vyrethFlare)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityLabel(slateMenuTitle)
    }

    private func takeRow(_ index: Int, _ title: String, _ reward: String, _ done: Bool) -> some View {
        NavigationLink(value: VyrethPath.runner(index)) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(done ? Color.vyrethFlare : Color.vyrethMist)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(Color.vyrethPaper)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(done ? "Done today" : reward)
                        .font(.footnote)
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.vyrethMist)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(done ? "Done today" : reward)")
    }

    private var composerBonus: some View {
        NavigationLink(value: VyrethPath.composer) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Framing bonus")
                    .font(.headline)
                    .foregroundStyle(Color.vyrethPaper)
                    .fixedSize(horizontal: false, vertical: true)
                Text(hub.vyrethDay(VyrethClock.key()).composer ? "Bonus already saved today." : "Place one frame for 15 extra Reels.")
                    .font(.subheadline)
                    .foregroundStyle(Color.vyrethMist)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .vyrethPanel()
        }
        .buttonStyle(.plain)
    }

    private var frameCard: some View {
        let term = hub.vyrethFrameTerm()
        return VStack(alignment: .leading, spacing: 8) {
            Text("Frame of the day")
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(Color.vyrethPaper)
            Text(term?.title ?? "Term")
                .font(.headline)
                .foregroundStyle(Color.vyrethFlare)
                .fixedSize(horizontal: false, vertical: true)
            if flipped {
                Text(term?.definition ?? "")
                    .foregroundStyle(Color.vyrethMist)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Flip the card to read the definition.")
                    .foregroundStyle(Color.vyrethMist)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Button(flipped ? "Hide definition" : "Flip card") {
                    if hub.motionQuiet {
                        flipped.toggle()
                    } else {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { flipped.toggle() }
                    }
                }
                .foregroundStyle(Color.vyrethPaper)
                Spacer()
                if let term {
                    NavigationLink(value: VyrethPath.term(term.id)) {
                        Text("Open term")
                            .foregroundStyle(Color.vyrethFlare)
                    }
                    .simultaneousGesture(TapGesture().onEnded { hub.vyrethOpenTerm(term.id) })
                }
            }
        }
        .vyrethPanel()
        .rotation3DEffect(.degrees(flipped && !hub.motionQuiet ? 0 : 0), axis: (x: 0, y: 1, z: 0))
    }

    private var continueCard: some View {
        Group {
            if let lesson = hub.vyrethTodayLesson() {
                NavigationLink(value: VyrethPath.lesson(lesson.id)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Continue learning")
                            .font(.headline)
                            .foregroundStyle(Color.vyrethPaper)
                        Text(lesson.title)
                            .foregroundStyle(Color.vyrethFlare)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("About \(lesson.minutes) minutes")
                            .font(.footnote)
                            .foregroundStyle(Color.vyrethMist)
                    }
                    .vyrethPanel()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var festivalCard: some View {
        NavigationLink(value: VyrethPath.festival) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Weekly festival")
                    .font(.headline)
                    .foregroundStyle(Color.vyrethPaper)
                Text("\(hub.blob.festival.takes) of 20 Takes this week")
                    .foregroundStyle(Color.vyrethMist)
                    .monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)
                if !hub.vyrethFestivalCategory().isEmpty {
                    Text("Week frame: \(hub.vyrethFestivalCategory())")
                        .font(.subheadline)
                        .foregroundStyle(Color.vyrethFlare)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .vyrethPanel()
        }
        .buttonStyle(.plain)
    }

    private var weekRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This week")
                .font(.headline)
                .foregroundStyle(Color.vyrethPaper)
            HStack {
                ForEach(hub.vyrethWeekMarks(), id: \.key) { item in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(fill(item.mark))
                            .overlay(Circle().stroke(item.mark == "pass" ? Color.vyrethFlare : Color.clear, lineWidth: 2))
                            .frame(width: 18, height: 18)
                        Text(shortDay(item.key))
                            .font(.caption2)
                            .foregroundStyle(Color.vyrethMist)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("\(shortDay(item.key)) \(item.mark)")
                }
            }
        }
        .vyrethPanel()
    }

    private func fill(_ mark: String) -> Color {
        switch mark {
        case "done": return Color.vyrethFlare
        case "miss": return Color.vyrethEmber
        case "today": return Color.vyrethMist.opacity(0.45)
        default: return Color.vyrethMist.opacity(0.18)
        }
    }

    private func shortDay(_ key: String) -> String {
        let symbols = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let index = VyrethClock.weekdayIndex(VyrethClock.date(key))
        return symbols[index]
    }
}

struct KorrinBeam: View {
    var active: Bool
    @EnvironmentObject private var hub: VyrethLedgerHub

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: !active || hub.motionQuiet)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let flicker = abs(sin(time * 3.1) * 0.5 + sin(time * 7.3) * 0.5)
                let alpha: Double
                switch hub.blob.streak.light {
                case "bright": alpha = 0.55
                case "dim": alpha = 0.28
                case "flicker": alpha = 0.15 + flicker * 0.4
                default: alpha = 0.05
                }
                var beam = Path()
                beam.move(to: CGPoint(x: size.width * 0.5, y: 0))
                beam.addLine(to: CGPoint(x: size.width * 0.18, y: size.height))
                beam.addLine(to: CGPoint(x: size.width * 0.82, y: size.height))
                beam.closeSubpath()
                context.fill(beam, with: .color(Color.vyrethFlare.opacity(alpha)))
                if hub.blob.streak.light == "out" {
                    let pulse = 0.4 + 0.6 * abs(sin(time * 2))
                    let ember = CGRect(x: size.width * 0.5 - 6, y: size.height * 0.72, width: 12, height: 12)
                    context.fill(Path(ellipseIn: ember), with: .color(Color.vyrethEmber.opacity(pulse)))
                }
                if !hub.motionQuiet {
                    for index in 0..<12 {
                        let phase = time * 18 + Double(index) * 17
                        let x = size.width * (0.25 + CGFloat(index % 6) * 0.09) + CGFloat(sin(phase * 0.2)) * 8
                        let y = CGFloat(phase.truncatingRemainder(dividingBy: Double(size.height)))
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)), with: .color(Color.white.opacity(0.35)))
                    }
                }
            }
            .frame(height: 86)
            .accessibilityHidden(true)
        }
    }
}

struct BrivTakeRunner: View {
    let index: Int
    @State private var ready = false
    @EnvironmentObject private var hub: VyrethLedgerHub

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Take \(index + 1) of 4")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vyrethMist)
                VyrethSprocket(filled: index, total: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            Group {
                if ready || hub.motionQuiet {
                    inner
                } else {
                    VyrethClapper { ready = true }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }

    @ViewBuilder
    private var inner: some View {
        let slots = VyrethSlate.kinds(hub.blob.extra)
        let kind = slots.indices.contains(index) ? slots[index] : "diary"
        switch kind {
        case "lesson":
            if let lesson = hub.vyrethTodayLesson() {
                MeldLessonReel(lessonId: lesson.id)
            } else {
                Text("No lesson is available yet.")
                    .foregroundStyle(Color.vyrethPaper)
                    .padding()
            }
        case "spotter":
            QuillShotSpotter()
        case "logline":
            QuillLoglineLab(prompted: true)
        case "composer":
            QuillFrameComposer(briefId: hub.vyrethRuleBrief()?.id)
        case "board":
            QuillShotList()
        default:
            NoxEntryEditor(entryId: "new", fromTake: true)
        }
    }
}

struct KorrinCelebration: View {
    @EnvironmentObject private var hub: VyrethLedgerHub
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Full slate")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                    .fixedSize(horizontal: false, vertical: true)
                Text("All four Takes are done. A 25 Reel bonus was added, and the day is counted if your goal asked for it.")
                    .foregroundStyle(Color.vyrethMist)
                    .fixedSize(horizontal: false, vertical: true)
                let day = hub.vyrethDay(VyrethClock.key())
                Text("Reels recorded today: \(day.reels)")
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(Color.vyrethPaper)
                Text("Streak: \(hub.blob.streak.current)")
                    .foregroundStyle(Color.vyrethFlare)
                VyrethFlareButton(title: "Back to today") {
                    hub.showCelebration = false
                    dismiss()
                }
            }
            .padding(20)
        }
        .vyrethScreen(image: "hero_projection_beam", opacity: 0.55)
    }
}

struct KorrinFestivalWeek: View {
    @EnvironmentObject private var hub: VyrethLedgerHub

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Weekly festival")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Finish 20 Takes between Monday and Sunday. Milestones award extra Reels and a poster.")
                    .foregroundStyle(Color.vyrethMist)
                    .fixedSize(horizontal: false, vertical: true)
                if !hub.vyrethFestivalCategory().isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("This week's frame")
                            .font(.headline)
                            .foregroundStyle(Color.vyrethPaper)
                        Text(hub.vyrethFestivalCategory())
                            .font(.system(.title3, design: .serif).weight(.semibold))
                            .foregroundStyle(Color.vyrethFlare)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Every Take this week serves that brief family. The count still runs to 20.")
                            .foregroundStyle(Color.vyrethMist)
                            .fixedSize(horizontal: false, vertical: true)
                        if let brief = hub.vyrethRuleBrief() {
                            Text(brief.title)
                                .foregroundStyle(Color.vyrethPaper)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(brief.detail)
                                .font(.subheadline)
                                .foregroundStyle(Color.vyrethMist)
                                .fixedSize(horizontal: false, vertical: true)
                            NavigationLink(value: VyrethPath.brief(brief.id)) {
                                Text("Open this brief")
                                    .foregroundStyle(Color.vyrethFlare)
                            }
                        }
                    }
                    .vyrethPanel(strong: true)
                }
                tier("Selected", 8, 20, hub.blob.festival.tier >= 1)
                tier("Nominee", 14, 40, hub.blob.festival.tier >= 2)
                tier("Winner", 20, 80, hub.blob.festival.tier >= 3)
                Text("This week: \(hub.blob.festival.takes) Takes")
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(Color.vyrethPaper)
                if hub.blob.festivalHistory.isEmpty {
                    Text("Finished weeks will gather here.")
                        .foregroundStyle(Color.vyrethMist)
                } else {
                    ForEach(hub.blob.festivalHistory.reversed()) { week in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Week of \(week.weekStart)")
                                .foregroundStyle(Color.vyrethPaper)
                            Text(historyLine(week))
                                .foregroundStyle(Color.vyrethMist)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .vyrethPanel()
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Festival")
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }

    private func tier(_ name: String, _ takes: Int, _ reels: Int, _ done: Bool) -> some View {
        HStack(alignment: .top) {
            Image(systemName: done ? "checkmark.seal.fill" : "seal")
                .foregroundStyle(done ? Color.vyrethFlare : Color.vyrethMist)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .foregroundStyle(Color.vyrethPaper)
                Text("\(takes) Takes · \(reels) Reels")
                    .font(.footnote)
                    .foregroundStyle(Color.vyrethMist)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private func tierName(_ tier: Int) -> String {
        switch tier {
        case 1: return "Selected"
        case 2: return "Nominee"
        case 3: return "Winner"
        default: return "Open"
        }
    }

    private func historyLine(_ week: VyrethFestivalKnot) -> String {
        let rule = hub.blob.extra.weekRules[week.weekStart] ?? ""
        if rule.isEmpty { return "\(week.takes) Takes · \(tierName(week.tier))" }
        return "\(week.takes) Takes · \(tierName(week.tier)) · \(rule)"
    }
}
