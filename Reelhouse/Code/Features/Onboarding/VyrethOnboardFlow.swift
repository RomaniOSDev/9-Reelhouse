import SwiftUI

struct VyrethOnboardFlow: View {
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var page = 0
    @State private var track = 0
    @State private var takes = 2
    @State private var remind = true
    @State private var clock = Calendar.current.date(from: DateComponents(hour: 19, minute: 0)) ?? Date()
    @State private var clapping = false

    private let lines = [
        "Learn how films are made, one Take a day.",
        "Train your eye. Write. Log what you watch.",
        "Keep the projector light burning."
    ]

    var body: some View {
        Group {
            if clapping {
                VyrethClapper {
                    let parts = Calendar.current.dateComponents([.hour, .minute], from: clock)
                    hub.vyrethFinishOnboard(track: track, takes: takes, hour: parts.hour ?? 19, minute: parts.minute ?? 0, remind: remind)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(index == page ? Color.vyrethFlare : Color.vyrethMist.opacity(0.35))
                                    .frame(width: index == page ? 28 : 14, height: 8)
                            }
                        }
                        .accessibilityLabel("Page \(page + 1) of 3")
                        Text(lines[page])
                            .font(.system(.title, design: .serif).weight(.bold))
                            .foregroundStyle(Color.vyrethPaper)
                            .fixedSize(horizontal: false, vertical: true)
                        if page == 2 {
                            personalization
                        } else {
                            Text(page == 0
                                 ? "Each day builds a slate of short Takes: a lesson, an eye drill, a logline, and a watch note."
                                 : "Ranks, frame cards, and the weekly festival grow only from what you actually finish.")
                                .foregroundStyle(Color.vyrethMist)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        VyrethFlareButton(title: page == 2 ? "Start my first Slate" : "Continue") {
                            if page < 2 {
                                if hub.motionQuiet { page += 1 } else { withAnimation(.easeInOut(duration: 0.35)) { page += 1 } }
                            } else {
                                clapping = true
                            }
                        }
                        if page > 0 {
                            VyrethQuietButton(title: "Back") {
                                if hub.motionQuiet { page -= 1 } else { withAnimation { page -= 1 } }
                            }
                        }
                    }
                    .padding(20)
                }
                .vyrethScreen(image: "hero_projection_beam", opacity: page == 0 ? 0.62 : 0.4)
            }
        }
    }

    private var personalization: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose a starting track. You can open the others any time.")
                .foregroundStyle(Color.vyrethMist)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(VyrethCatalog.book.tracks) { item in
                Button {
                    track = item.id
                    VyrethHaptic.tap(hub.blob.profile.haptics)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(Color.vyrethPaper)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(item.blurb)
                            .font(.subheadline)
                            .foregroundStyle(Color.vyrethMist)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(track == item.id ? Color.vyrethFlare.opacity(0.28) : Color.vyrethPanel)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16).stroke(track == item.id ? Color.vyrethFlare : Color.vyrethMist.opacity(0.18), lineWidth: 1)
                            )
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(track == item.id ? .isSelected : [])
            }
            Text("How many Takes should count the day?")
                .font(.headline)
                .foregroundStyle(Color.vyrethPaper)
                .fixedSize(horizontal: false, vertical: true)
            takeChoice("Casual", 2, "Two Takes keep the streak.")
            takeChoice("Regular", 3, "Three Takes keep the streak.")
            takeChoice("Full Slate", 4, "All four Takes keep the streak.")
            Toggle(isOn: $remind) {
                Text("Daily reminder")
                    .foregroundStyle(Color.vyrethPaper)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .tint(Color.vyrethFlare)
            if remind {
                DatePicker("Reminder time", selection: $clock, displayedComponents: .hourAndMinute)
                    .foregroundStyle(Color.vyrethPaper)
            }
            Text("The reminder only asks you to open today's slate. You can change it later.")
                .font(.footnote)
                .foregroundStyle(Color.vyrethMist)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func takeChoice(_ title: String, _ value: Int, _ detail: String) -> some View {
        Button {
            takes = value
            VyrethHaptic.tap(hub.blob.profile.haptics)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: takes == value ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(takes == value ? Color.vyrethFlare : Color.vyrethMist)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(Color.vyrethPaper)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(Color.vyrethMist)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(detail)")
    }
}
