import SwiftUI

enum VyrethPath: Hashable {
    case runner(Int)
    case composer
    case festival
    case track(Int)
    case lesson(String)
    case spotter
    case logline
    case loglineOpen
    case pad
    case idea(String)
    case diaryEdit(String)
    case diaryFromWatch(String)
    case diaryDetail(String)
    case watch
    case stats
    case ranks
    case vault
    case card(String)
    case lobby
    case badges
    case glossary
    case term(String)
    case saved
    case settings
    case brief(String)
    case review
}

struct ContentView: View {
    @StateObject private var hub = VyrethLedgerHub()

    var body: some View {
        Group {
            if hub.blob.profile.onboarded {
                VyrethTabShell()
            } else {
                VyrethOnboardFlow()
            }
        }
        .environmentObject(hub)
        .preferredColorScheme(.dark)
        .onAppear { hub.vyrethWake() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            hub.vyrethWake()
        }
    }
}

struct VyrethTabShell: View {
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var tab = 0
    @Namespace private var tabGlow

    private let items: [(String, String)] = [
        ("Today", "sun.max.fill"),
        ("Academy", "film"),
        ("Practice", "viewfinder"),
        ("Diary", "book.closed.fill"),
        ("Profile", "person.crop.circle.fill")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                stack(KorrinTodayDeck(active: tab == 0), index: 0)
                stack(MeldAcademyHall(), index: 1)
                stack(QuillPracticeBay(), index: 2)
                stack(NoxDiaryFolio(), index: 3)
                stack(AurelProfileAtrium(), index: 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    Button {
                        VyrethHaptic.tap(hub.blob.profile.haptics)
                        if hub.motionQuiet {
                            tab = index
                        } else {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) { tab = index }
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: items[index].1)
                            Text(items[index].0)
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            ZStack {
                                Capsule().fill(Color.clear).frame(height: 3)
                                if tab == index {
                                    Capsule()
                                        .fill(Color.vyrethFlare)
                                        .frame(height: 3)
                                        .matchedGeometryEffect(id: "vyrethTabGlow", in: tabGlow)
                                        .shadow(color: Color.vyrethFlare.opacity(0.7), radius: 4)
                                }
                            }
                        }
                        .foregroundStyle(tab == index ? Color.vyrethFlare : Color.vyrethMist)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)
                        .padding(.bottom, 2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(items[index].0)
                    .accessibilityAddTraits(tab == index ? .isSelected : [])
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)
            .background(Color.vyrethPanel.opacity(0.98))
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .fullScreenCover(isPresented: $hub.showCelebration) {
            KorrinCelebration()
                .environmentObject(hub)
        }
        .sheet(isPresented: $hub.showLightSheet, onDismiss: { hub.vyrethAckLight() }) {
            VyrethLightSheet()
                .environmentObject(hub)
        }
        .sheet(isPresented: $hub.showRankSheet) {
            VyrethRankSheet()
                .environmentObject(hub)
        }
        .sheet(item: $hub.toast) { note in
            VyrethToastSheet(note: note)
                .environmentObject(hub)
        }
    }

    private func stack<Content: View>(_ content: Content, index: Int) -> some View {
        NavigationStack {
            content.vyrethRoutes()
        }
        .opacity(tab == index ? 1 : 0)
        .allowsHitTesting(tab == index)
        .accessibilityHidden(tab != index)
    }
}

extension View {
    func vyrethRoutes() -> some View {
        navigationDestination(for: VyrethPath.self) { path in
            VyrethDestination(path: path)
        }
    }
}

struct VyrethDestination: View {
    let path: VyrethPath

    var body: some View {
        switch path {
        case .runner(let index):
            BrivTakeRunner(index: index)
        case .composer:
            QuillFrameComposer(briefId: nil)
        case .festival:
            KorrinFestivalWeek()
        case .track(let id):
            MeldTrackStrip(track: id)
        case .lesson(let id):
            MeldLessonReel(lessonId: id)
        case .spotter:
            QuillShotSpotter()
        case .logline:
            QuillLoglineLab(prompted: true)
        case .loglineOpen:
            QuillLoglineLab(prompted: false)
        case .pad:
            QuillScriptPad()
        case .idea(let id):
            QuillIdeaEditor(ideaId: id)
        case .diaryEdit(let id):
            NoxEntryEditor(entryId: id, fromTake: false)
        case .diaryFromWatch(let id):
            NoxEntryEditor(entryId: "new", fromTake: true, watchSeed: id)
        case .diaryDetail(let id):
            NoxEntryDetail(entryId: id)
        case .watch:
            NoxWatchShelf()
        case .stats:
            NoxDiaryStats()
        case .ranks:
            AurelRankLadder()
        case .vault:
            AurelFrameVault()
        case .card(let id):
            AurelCardDetail(termId: id)
        case .lobby:
            AurelStudioLobby()
        case .badges:
            AurelBadgeHall()
        case .glossary:
            AurelGlossaryIndex()
        case .term(let id):
            AurelCardDetail(termId: id)
        case .saved:
            AurelSavedCards()
        case .settings:
            SableSettingsPane()
        case .brief(let id):
            QuillFrameComposer(briefId: id)
        case .review:
            AurelCardReview()
        }
    }
}

struct VyrethLightSheet: View {
    @EnvironmentObject private var hub: VyrethLedgerHub

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Projector light")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(Color.vyrethPaper)
                    .fixedSize(horizontal: false, vertical: true)
                Text(hub.vyrethLightCopy())
                    .font(.body)
                    .foregroundStyle(Color.vyrethMist)
                    .fixedSize(horizontal: false, vertical: true)
                VyrethFlareButton(title: "Keep going") {
                    hub.showLightSheet = false
                }
            }
            .padding(20)
        }
        .vyrethScreen()
        .presentationDetents([.medium, .large])
    }
}

struct VyrethRankSheet: View {
    @EnvironmentObject private var hub: VyrethLedgerHub

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VyrethBurst(token: hub.burstTick)
                .frame(height: 80)
            Text("New rank")
                .font(.system(.title, design: .serif).weight(.bold))
                .foregroundStyle(Color.vyrethPaper)
            Text(hub.rankTitle)
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(Color.vyrethFlare)
                .fixedSize(horizontal: false, vertical: true)
            Text("A new perk is open in the career ladder and the studio lobby.")
                .foregroundStyle(Color.vyrethMist)
                .fixedSize(horizontal: false, vertical: true)
            VyrethFlareButton(title: "Continue") { hub.showRankSheet = false }
        }
        .padding(20)
        .vyrethScreen(image: "texture_velvet", opacity: 0.4)
    }
}

struct VyrethToastSheet: View {
    @EnvironmentObject private var hub: VyrethLedgerHub
    let note: VyrethToastNote

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(note.title)
                .font(.system(.title2, design: .serif).weight(.bold))
                .foregroundStyle(Color.vyrethPaper)
                .fixedSize(horizontal: false, vertical: true)
            Text(note.detail)
                .foregroundStyle(Color.vyrethMist)
                .fixedSize(horizontal: false, vertical: true)
            VyrethFlareButton(title: "Close") { hub.toast = nil }
        }
        .padding(20)
        .vyrethScreen()
        .presentationDetents([.medium])
    }
}
