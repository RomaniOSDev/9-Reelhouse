import SwiftUI
import Combine

struct QuillPracticeBay: View {
    @EnvironmentObject private var hub: VyrethLedgerHub

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Practice")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                    .fixedSize(horizontal: false, vertical: true)
                if let gap = hub.vyrethWeakShot() {
                    Text("Coverage gap: \(gap.name). \(gap.hits) of \(gap.total) so far. The next round leans on it.")
                        .foregroundStyle(Color.vyrethFlare)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Today's recommendation: \(hub.vyrethRecommendTool())")
                        .foregroundStyle(Color.vyrethFlare)
                        .fixedSize(horizontal: false, vertical: true)
                }
                toolLink(.spotter, "Shot Spotter", "Name the shot size or angle.", "viewfinder", hub.vyrethSpotterBest(), lastDate("spotter"))
                toolLink(.composer, "Frame Composer", "Place a subject inside the brief.", "square.grid.3x3", hub.blob.composerBests.values.max() ?? 0, "Best of \(hub.blob.composerBests.count) briefs")
                toolLink(.logline, "Logline Lab", "Shape a one-sentence story.", "text.quote", hub.blob.loglines.count, "Saved ideas")
                NavigationLink(value: VyrethPath.pad) {
                    Text("Open script pad")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.vyrethPaper)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(VyrethQuietStyle())
            }
            .padding(16)
        }
        .vyrethScreen()
    }

    private func lastDate(_ tool: String) -> String {
        let date = hub.blob.attempts.filter { $0.tool == tool }.map(\.date).max() ?? ""
        return date.isEmpty ? "Not played yet" : "Last played \(date)"
    }

    private func toolLink(_ path: VyrethPath, _ title: String, _ detail: String, _ icon: String, _ score: Int, _ meta: String) -> some View {
        NavigationLink(value: path) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.vyrethFlare)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.vyrethPaper)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Best \(score) · \(meta)")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .vyrethPanel(strong: true)
        }
        .buttonStyle(.plain)
    }
}

struct QuillRoundFrame: Identifiable, Equatable {
    let id = UUID()
    let kind: String
    let pose: Int
    let options: [String]
}

struct QuillShotSpotter: View {
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var frames: [QuillRoundFrame] = []
    @State private var index = 0
    @State private var score = 0
    @State private var hits = 0
    @State private var left = 10.0
    @State private var running = false
    @State private var detail: [String: Int] = [:]
    @State private var note = ""
    @State private var locked = false
    @State private var done = false
    @State private var stored = false

    var body: some View {
        Group {
            if done {
                results
            } else if frames.indices.contains(index) {
                round
            } else {
                VStack(spacing: 12) {
                    Text("Shot Spotter")
                        .font(.system(.title, design: .serif).weight(.bold))
                        .foregroundStyle(Color.vyrethPaper)
                    VyrethFlareButton(title: "Start round") { build() }
                }
                .padding(16)
            }
        }
        .onAppear { if frames.isEmpty { build() } }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard running, !locked, !done else { return }
            left -= 0.1
            if left <= 0 {
                miss()
            }
        }
        .navigationTitle("Shot Spotter")
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }

    private var round: some View {
        let frame = frames[index]
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Frame \(index + 1) of 5")
                    .foregroundStyle(Color.vyrethMist)
                QuillFrameStage(kind: frame.kind, pose: frame.pose)
                GeometryReader { geo in
                    Capsule()
                        .fill(Color.vyrethMist.opacity(0.2))
                        .frame(height: 8)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(left < 4 ? Color.vyrethEmber : Color.vyrethFlare)
                                .frame(width: max(0, geo.size.width * left / 10), height: 8)
                        }
                }
                .frame(height: 8)
                Text(String(format: "%.1f s", max(0, left)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.vyrethMist)
                ForEach(frame.options, id: \.self) { option in
                    Button {
                        answer(option, frame: frame)
                    } label: {
                        Text(option)
                            .foregroundStyle(Color.vyrethPaper)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background {
                                RoundedRectangle(cornerRadius: 14).fill(Color.vyrethPanel)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(locked)
                }
                if !note.isEmpty {
                    Text(note)
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
        }
    }

    private var results: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Round result")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                Text("Score \(score)")
                    .font(.title.monospacedDigit())
                    .foregroundStyle(Color.vyrethFlare)
                Text("Accuracy \(hits) of 5. Best saved score \(max(hub.vyrethSpotterBest(), score)).")
                    .foregroundStyle(Color.vyrethMist)
                    .fixedSize(horizontal: false, vertical: true)
                if let gap = hub.vyrethWeakShot() {
                    Text("Next round leans on \(gap.name).")
                        .foregroundStyle(Color.vyrethFlare)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(hub.vyrethTypeAccuracy(), id: \.0) { row in
                    Text("\(row.0): \(row.1) of \(row.2)")
                        .foregroundStyle(Color.vyrethPaper)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VyrethFlareButton(title: "Play again") { resetRound() }
            }
            .padding(16)
        }
    }

    private func build() {
        let pool = hub.vyrethSpotterPool()
        let weak = hub.vyrethWeakKinds()
        var rng = VyrethMixer.dayNumber(VyrethClock.key()) + hub.blob.tally.spotterRounds * 19 + Int(Date().timeIntervalSince1970) % 200
        func next() -> Int {
            rng = (rng * 1103515245 + 12345) & 0x7fffffff
            return rng
        }
        var made: [QuillRoundFrame] = []
        var used: [String] = []
        var spins = 0
        while made.count < 5 && spins < 40 {
            spins += 1
            let openWeak = weak.filter { !used.contains($0) }
            let kind: String
            if !openWeak.isEmpty, next() % 5 < 3 {
                kind = openWeak[next() % openWeak.count]
            } else {
                kind = pool[next() % pool.count]
            }
            if used.contains(kind) { continue }
            used.append(kind)
            var options = [kind]
            var inner = 0
            while options.count < 4 && inner < 30 {
                inner += 1
                let pick = pool[next() % pool.count]
                if !options.contains(pick) { options.append(pick) }
            }
            var shuffled = options
            if shuffled.count > 1 {
                for slot in stride(from: shuffled.count - 1, through: 1, by: -1) {
                    shuffled.swapAt(slot, next() % (slot + 1))
                }
            }
            made.append(QuillRoundFrame(kind: kind, pose: next() % 3, options: shuffled))
        }
        frames = made
        index = 0
        score = 0
        hits = 0
        left = 10
        detail = [:]
        note = ""
        locked = false
        done = false
        stored = false
        running = true
    }

    private func resetRound() {
        build()
    }

    private func answer(_ option: String, frame: QuillRoundFrame) {
        guard !locked else { return }
        locked = true
        running = false
        let correct = option == frame.kind
        if correct {
            hits += 1
            score += left >= 6 ? 4 : 3
            detail[frame.kind] = 1
            VyrethHaptic.success(hub.blob.profile.haptics)
        } else {
            detail[frame.kind] = 0
            VyrethHaptic.warn(hub.blob.profile.haptics)
        }
        note = quillExplain(frame.kind)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) { advance() }
    }

    private func miss() {
        guard frames.indices.contains(index), !locked else { return }
        locked = true
        running = false
        let frame = frames[index]
        detail[frame.kind] = 0
        note = quillExplain(frame.kind)
        VyrethHaptic.warn(hub.blob.profile.haptics)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) { advance() }
    }

    private func advance() {
        if index + 1 >= frames.count {
            finish()
        } else {
            index += 1
            left = 10
            note = ""
            locked = false
            running = true
        }
    }

    private func finish() {
        done = true
        running = false
        guard !stored else { return }
        stored = true
        hub.vyrethFinishSpotter(score: min(20, score), perfect: hits == 5, detail: detail)
    }
}

func quillExplain(_ kind: String) -> String {
    switch kind {
    case "Extreme Wide": return "The person is tiny inside a large place, so the world feels bigger than the figure."
    case "Wide": return "You still see the full place, and the person is small but readable from head to toe."
    case "Full": return "The whole body fits with a modest margin above the head and below the feet."
    case "Medium": return "Shows the subject from the head toward the knees, a medium framing."
    case "Medium Close-Up": return "The frame holds the head and upper chest, close enough to read expression."
    case "Close-Up": return "The face fills most of the frame, so a small change in the eyes matters."
    case "Extreme Close-Up": return "Only a fragment of the face remains, often eyes or mouth."
    case "Over-the-Shoulder": return "A nearer shoulder blocks one edge while the other person stays in focus."
    case "Low Angle": return "The camera looks up, the horizon drops, and the figure feels taller."
    case "High Angle": return "The camera looks down, the horizon rises, and the figure feels smaller."
    default: return "The horizon tilts, so the frame feels uneasy without changing the shot size."
    }
}

struct QuillFrameStage: View {
    var kind: String
    var pose: Int

    var body: some View {
        Color.vyrethInk
            .aspectRatio(kind == "Extreme Wide" ? 2.39 : 1.78, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    let pack = transform(in: geo.size)
                    ZStack {
                        scene(in: geo.size)
                        if kind == "Over-the-Shoulder" {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.vyrethPanel)
                                .frame(width: geo.size.width * 0.34, height: geo.size.height * 0.78)
                                .offset(x: -geo.size.width * 0.34, y: geo.size.height * 0.18)
                        }
                    }
                    .scaleEffect(pack.0)
                    .offset(pack.1)
                    .rotationEffect(.degrees(kind == "Dutch Angle" ? -12 : (kind == "Low Angle" ? -4 : 0)))
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14).stroke(Color.vyrethMist.opacity(0.25), lineWidth: 1)
            )
            .accessibilityLabel(kind)
    }

    private func transform(in size: CGSize) -> (CGFloat, CGSize) {
        switch kind {
        case "Extreme Wide": return (0.42, CGSize(width: 0, height: size.height * 0.05))
        case "Wide": return (0.62, .zero)
        case "Full": return (0.92, .zero)
        case "Medium": return (1.35, CGSize(width: 0, height: -size.height * 0.12))
        case "Medium Close-Up": return (1.7, CGSize(width: 0, height: -size.height * 0.22))
        case "Close-Up": return (2.25, CGSize(width: 0, height: -size.height * 0.32))
        case "Extreme Close-Up": return (3.1, CGSize(width: 0, height: -size.height * 0.42))
        case "Over-the-Shoulder": return (1.45, CGSize(width: size.width * 0.08, height: -size.height * 0.05))
        case "Low Angle": return (1.15, CGSize(width: 0, height: size.height * 0.16))
        case "High Angle": return (0.86, CGSize(width: 0, height: -size.height * 0.12))
        default: return (1, .zero)
        }
    }

    private func scene(in size: CGSize) -> some View {
        let bodyHeight: CGFloat = pose == 1 ? size.height * 0.28 : size.height * 0.34
        return ZStack {
            Rectangle()
                .fill(Color.vyrethPanel)
                .frame(height: size.height * (kind == "High Angle" ? 0.62 : 0.38))
                .frame(maxHeight: .infinity, alignment: .bottom)
            Rectangle()
                .fill(Color.vyrethMist.opacity(0.35))
                .frame(width: size.width * 0.22, height: size.height * 0.28)
                .offset(x: size.width * 0.28, y: -size.height * 0.08)
            Capsule()
                .fill(Color.vyrethMist.opacity(0.5))
                .frame(width: size.width * 0.28, height: 10)
                .offset(y: size.height * 0.18)
            VStack(spacing: 2) {
                Circle().fill(Color.vyrethPaper).frame(width: 22, height: 22)
                RoundedRectangle(cornerRadius: 8).fill(Color.vyrethFlare).frame(width: 28, height: bodyHeight)
                if pose != 1 {
                    HStack(spacing: 6) {
                        Capsule().fill(Color.vyrethPaper).frame(width: 8, height: pose == 2 ? 36 : 28)
                        Capsule().fill(Color.vyrethPaper).frame(width: 8, height: 28)
                    }
                }
            }
            .offset(x: pose == 2 ? -18 : 0, y: pose == 1 ? 16 : 0)
        }
    }
}

struct QuillFrameComposer: View {
    var briefId: String?
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var subject = CGPoint(x: 0.5, y: 0.45)
    @State private var horizon: CGFloat = 0.55
    @State private var dragStart = CGPoint(x: 0.5, y: 0.45)
    @State private var horizonStart: CGFloat = 0.55
    @State private var score: Int?
    @State private var critique = ""

    private var brief: VyrethBriefLine? {
        if let briefId, let found = VyrethCatalog.book.briefs.first(where: { $0.id == briefId }) {
            return found
        }
        return hub.vyrethTodayBrief()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(brief?.title ?? "Frame")
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                    .fixedSize(horizontal: false, vertical: true)
                Text(brief?.detail ?? "")
                    .foregroundStyle(Color.vyrethMist)
                    .fixedSize(horizontal: false, vertical: true)
                stage
                if let score {
                    Text("Score \(score)")
                        .font(.title.monospacedDigit())
                        .foregroundStyle(Color.vyrethFlare)
                    Text(stars(score))
                        .foregroundStyle(Color.vyrethPaper)
                    Text(critique)
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VyrethFlareButton(title: "Score this frame") { judge() }
                Text("Choose any brief")
                    .font(.headline)
                    .foregroundStyle(Color.vyrethPaper)
                ForEach(VyrethCatalog.book.briefs) { item in
                    NavigationLink(value: VyrethPath.brief(item.id)) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .foregroundStyle(Color.vyrethPaper)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Best \(hub.blob.composerBests[item.id] ?? 0)")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(Color.vyrethMist)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Frame Composer")
        .navigationBarTitleDisplayMode(.inline)
        .vyrethScreen()
    }

    private var stage: some View {
        Color.vyrethInk
            .aspectRatio(1.78, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        Path { path in
                            path.move(to: CGPoint(x: geo.size.width / 3, y: 0))
                            path.addLine(to: CGPoint(x: geo.size.width / 3, y: geo.size.height))
                            path.move(to: CGPoint(x: geo.size.width * 2 / 3, y: 0))
                            path.addLine(to: CGPoint(x: geo.size.width * 2 / 3, y: geo.size.height))
                            path.move(to: CGPoint(x: 0, y: geo.size.height / 3))
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 3))
                            path.move(to: CGPoint(x: 0, y: geo.size.height * 2 / 3))
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height * 2 / 3))
                        }
                        .stroke(Color.vyrethFlare.opacity(0.35), lineWidth: 1)
                        Rectangle()
                            .fill(Color.vyrethMist.opacity(0.45))
                            .frame(height: 3)
                            .position(x: geo.size.width / 2, y: horizon * geo.size.height)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if horizonStart == 0 { horizonStart = horizon }
                                        let next = horizonStart + value.translation.height / geo.size.height
                                        horizon = min(0.92, max(0.08, next))
                                    }
                                    .onEnded { _ in horizonStart = horizon }
                            )
                        Circle()
                            .fill(Color.vyrethFlare)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: brief?.faceRight == false ? "arrow.left" : "arrow.right")
                                    .foregroundStyle(Color.vyrethPaper)
                            )
                            .position(x: subject.x * geo.size.width, y: subject.y * geo.size.height)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let nextX = dragStart.x + value.translation.width / geo.size.width
                                        let nextY = dragStart.y + value.translation.height / geo.size.height
                                        subject = CGPoint(x: min(0.92, max(0.08, nextX)), y: min(0.9, max(0.1, nextY)))
                                    }
                                    .onEnded { _ in
                                        snap()
                                        dragStart = subject
                                    }
                            )
                    }
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityLabel("Framing stage")
    }

    private func snap() {
        let marks: [CGFloat] = [1.0 / 3.0, 0.5, 2.0 / 3.0]
        var point = subject
        for mark in marks where abs(point.x - mark) < 0.045 { point.x = mark }
        for mark in marks where abs(point.y - mark) < 0.045 { point.y = mark }
        subject = point
        dragStart = point
    }

    private func judge() {
        guard let brief else { return }
        let result = quillJudge(brief, subject: subject, horizon: horizon)
        score = result.0
        critique = result.1
        hub.vyrethFinishComposer(briefId: brief.id, score: result.0)
        VyrethHaptic.success(hub.blob.profile.haptics)
    }

    private func stars(_ value: Int) -> String {
        if value >= 95 { return "Three stars" }
        if value >= 80 { return "Two stars" }
        if value >= 60 { return "One star" }
        return "Keep adjusting the frame"
    }
}

func quillJudge(_ brief: VyrethBriefLine, subject: CGPoint, horizon: CGFloat) -> (Int, String) {
    let dx = Double(subject.x) - brief.subjectX
    let dy = Double(subject.y) - brief.subjectY
    let dist = (dx * dx + dy * dy).squareRoot()
    let place = max(0, 40 - dist * 150)
    let head = max(0, 20 - abs(Double(subject.y) - brief.headroom) * 90)
    let front = brief.faceRight ? (1 - Double(subject.x)) : Double(subject.x)
    let lead = max(0, 20 - abs(front - brief.lead) * 80)
    let horizonScore = brief.horizon < 0 ? 20 : max(0, 20 - abs(Double(horizon) - brief.horizon) * 90)
    let total = min(100, max(0, Int((place + head + lead + horizonScore).rounded())))
    var lines: [String] = []
    if dist < 0.08 {
        lines.append("The subject sits in the target zone.")
    } else {
        lines.append("Slide the subject closer to the requested spot.")
    }
    if abs(Double(subject.y) - brief.headroom) < 0.08 {
        lines.append("Headroom matches the brief.")
    } else if Double(subject.y) > brief.headroom {
        lines.append("There is more empty space above the subject than requested.")
    } else {
        lines.append("Leave a little more room above the subject.")
    }
    if brief.horizon >= 0 {
        if abs(Double(horizon) - brief.horizon) < 0.08 {
            lines.append("The horizon sits in range.")
        } else {
            lines.append("Drag the horizon line toward the requested height.")
        }
    }
    return (total, lines.joined(separator: " "))
}
