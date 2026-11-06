import SwiftUI
import UIKit

extension Color {
    static let vyrethInk = Color(red: 11 / 255, green: 0, blue: 20 / 255)
    static let vyrethPanel = Color(red: 33 / 255, green: 25 / 255, blue: 37 / 255)
    static let vyrethFlare = Color(red: 255 / 255, green: 53 / 255, blue: 74 / 255)
    static let vyrethEmber = Color(red: 196 / 255, green: 0, blue: 18 / 255)
    static let vyrethPaper = Color(red: 1, green: 1, blue: 1)
    static let vyrethMist = Color(red: 170 / 255, green: 163 / 255, blue: 174 / 255)
}

enum VyrethHaptic {
    static func tap(_ on: Bool) {
        guard on else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success(_ on: Bool) {
        guard on else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warn(_ on: Bool) {
        guard on else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func rigid(_ on: Bool) {
        guard on else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
}

struct VyrethPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.vyrethFlare, Color.vyrethEmber.opacity(0.92)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.vyrethFlare.opacity(configuration.isPressed ? 0.18 : 0.38), radius: configuration.isPressed ? 4 : 10, y: 4)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct VyrethQuietStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.vyrethPanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.vyrethMist.opacity(0.28), lineWidth: 1)
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct VyrethPanelMod: ViewModifier {
    var strong: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.vyrethPanel, Color.vyrethInk.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.vyrethMist.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(strong ? 0.4 : 0.22), radius: strong ? 12 : 5, y: 4)
            }
    }
}

struct VyrethGrain: View {
    var body: some View {
        Canvas { context, size in
            var seed: UInt64 = 0xC0FFEE
            func unit() -> CGFloat {
                seed = seed &* 6364136223846793005 &+ 1
                return CGFloat((seed >> 33) % 1000) / 1000
            }
            for _ in 0..<140 {
                let x = unit() * size.width
                let y = unit() * size.height
                let dot = CGRect(x: x, y: y, width: 1.3, height: 1.3)
                context.fill(Path(ellipseIn: dot), with: .color(Color.white.opacity(0.045)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct VyrethBackdrop: ViewModifier {
    var imageName: String?
    var imageOpacity: Double

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color.vyrethInk
                    .overlay {
                        if let imageName {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .opacity(imageOpacity)
                        }
                    }
                    .overlay(alignment: .top) {
                        LinearGradient(
                            colors: [Color.vyrethFlare.opacity(0.22), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .allowsHitTesting(false)
                    }
                    .overlay {
                        VyrethGrain()
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}

extension View {
    func vyrethScreen(image: String? = nil, opacity: Double = 0.34) -> some View {
        modifier(VyrethBackdrop(imageName: image, imageOpacity: opacity))
    }

    func vyrethPanel(strong: Bool = false) -> some View {
        modifier(VyrethPanelMod(strong: strong))
    }

    func vyrethKeysAway() -> some View {
        simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
    }
}

struct VyrethFlareButton: View {
    var title: String
    var action: () -> Void
    @EnvironmentObject private var hub: VyrethLedgerHub

    var body: some View {
        Button {
            VyrethHaptic.tap(hub.blob.profile.haptics)
            action()
        } label: {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.vyrethPaper)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
        }
        .buttonStyle(VyrethPressStyle())
        .accessibilityLabel(title)
    }
}

struct VyrethQuietButton: View {
    var title: String
    var action: () -> Void
    @EnvironmentObject private var hub: VyrethLedgerHub

    var body: some View {
        Button {
            VyrethHaptic.tap(hub.blob.profile.haptics)
            action()
        } label: {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.vyrethPaper)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
        }
        .buttonStyle(VyrethQuietStyle())
        .accessibilityLabel(title)
    }
}

struct VyrethRollText: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text("\(Int(value.rounded()))")
            .monospacedDigit()
    }
}

struct VyrethCountRoll: View {
    var value: Int
    var font: Font = .system(.title, design: .serif).weight(.bold)
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var shown: Double = 0

    var body: some View {
        VyrethRollText(value: shown)
            .font(font)
            .foregroundStyle(Color.vyrethPaper)
            .onAppear { vyrethRoll() }
            .onChange(of: value) { _ in vyrethRoll() }
    }

    private func vyrethRoll() {
        if hub.motionQuiet {
            shown = Double(value)
        } else {
            shown = 0
            withAnimation(.easeOut(duration: 0.65)) {
                shown = Double(value)
            }
        }
    }
}

struct VyrethSprocket: View {
    var filled: Int
    var total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(index < filled ? Color.vyrethFlare : Color.vyrethMist.opacity(0.2))
                    .frame(height: 18)
                    .overlay(alignment: .leading) {
                        HStack(spacing: 4) {
                            Circle().fill(Color.vyrethInk.opacity(0.85)).frame(width: 5, height: 5)
                            Spacer(minLength: 0)
                            Circle().fill(Color.vyrethInk.opacity(0.85)).frame(width: 5, height: 5)
                        }
                        .padding(.horizontal, 4)
                    }
                    .accessibilityHidden(true)
            }
        }
    }
}

struct VyrethSketch: View {
    var kind: String

    var body: some View {
        Canvas { context, size in
            let frame = CGRect(origin: .zero, size: size)
            context.fill(Path(roundedRect: frame, cornerRadius: 12), with: .color(Color.vyrethInk))
            func line(_ a: CGPoint, _ b: CGPoint, _ color: Color, _ width: CGFloat) {
                var path = Path()
                path.move(to: a)
                path.addLine(to: b)
                context.stroke(path, with: .color(color), lineWidth: width)
            }
            let w = size.width
            let h = size.height
            switch kind {
            case "scale":
                ForEachBox.draw(context: &context, rects: [
                    CGRect(x: w * 0.08, y: h * 0.2, width: w * 0.18, height: h * 0.6),
                    CGRect(x: w * 0.34, y: h * 0.28, width: w * 0.22, height: h * 0.44),
                    CGRect(x: w * 0.64, y: h * 0.36, width: w * 0.26, height: h * 0.28)
                ])
            case "angle":
                line(CGPoint(x: w * 0.15, y: h * 0.8), CGPoint(x: w * 0.5, y: h * 0.2), Color.vyrethFlare, 3)
                line(CGPoint(x: w * 0.85, y: h * 0.8), CGPoint(x: w * 0.5, y: h * 0.35), Color.vyrethMist, 2)
            case "thirds":
                line(CGPoint(x: w / 3, y: 8), CGPoint(x: w / 3, y: h - 8), Color.vyrethFlare.opacity(0.8), 1.5)
                line(CGPoint(x: w * 2 / 3, y: 8), CGPoint(x: w * 2 / 3, y: h - 8), Color.vyrethFlare.opacity(0.8), 1.5)
                line(CGPoint(x: 8, y: h / 3), CGPoint(x: w - 8, y: h / 3), Color.vyrethMist.opacity(0.7), 1)
                line(CGPoint(x: 8, y: h * 2 / 3), CGPoint(x: w - 8, y: h * 2 / 3), Color.vyrethMist.opacity(0.7), 1)
                context.fill(Path(ellipseIn: CGRect(x: w / 3 - 7, y: h / 3 - 7, width: 14, height: 14)), with: .color(Color.vyrethFlare))
            case "depth":
                ForEachBox.draw(context: &context, rects: [
                    CGRect(x: w * 0.1, y: h * 0.45, width: w * 0.22, height: h * 0.4),
                    CGRect(x: w * 0.38, y: h * 0.3, width: w * 0.24, height: h * 0.42),
                    CGRect(x: w * 0.66, y: h * 0.16, width: w * 0.2, height: h * 0.34)
                ])
            case "lens":
                context.stroke(Path(ellipseIn: CGRect(x: w * 0.28, y: h * 0.18, width: w * 0.44, height: h * 0.64)), with: .color(Color.vyrethFlare), lineWidth: 3)
                context.stroke(Path(ellipseIn: CGRect(x: w * 0.36, y: h * 0.3, width: w * 0.28, height: h * 0.4)), with: .color(Color.vyrethMist), lineWidth: 2)
            case "move":
                var arrow = Path()
                arrow.move(to: CGPoint(x: w * 0.12, y: h * 0.5))
                arrow.addLine(to: CGPoint(x: w * 0.78, y: h * 0.5))
                context.stroke(arrow, with: .color(Color.vyrethFlare), lineWidth: 3)
                context.fill(Path(ellipseIn: CGRect(x: w * 0.72, y: h * 0.38, width: 18, height: 18)), with: .color(Color.vyrethEmber))
            case "trio":
                context.fill(Path(ellipseIn: CGRect(x: w * 0.42, y: h * 0.18, width: 22, height: 22)), with: .color(Color.vyrethFlare))
                context.fill(Path(ellipseIn: CGRect(x: w * 0.18, y: h * 0.55, width: 16, height: 16)), with: .color(Color.vyrethMist))
                context.fill(Path(ellipseIn: CGRect(x: w * 0.7, y: h * 0.42, width: 14, height: 14)), with: .color(Color.vyrethEmber))
            case "soft":
                context.fill(Path(ellipseIn: CGRect(x: w * 0.3, y: h * 0.22, width: w * 0.4, height: h * 0.55)), with: .color(Color.vyrethFlare.opacity(0.35)))
                context.stroke(Path(roundedRect: CGRect(x: w * 0.38, y: h * 0.3, width: w * 0.24, height: h * 0.4), cornerRadius: 4), with: .color(Color.vyrethPaper), lineWidth: 2)
            case "temp":
                context.fill(Path(CGRect(x: 0, y: 0, width: w * 0.5, height: h)), with: .color(Color.vyrethEmber.opacity(0.55)))
                context.fill(Path(CGRect(x: w * 0.5, y: 0, width: w * 0.5, height: h)), with: .color(Color.vyrethMist.opacity(0.35)))
            case "contrast":
                context.fill(Path(CGRect(x: w * 0.15, y: h * 0.2, width: w * 0.28, height: h * 0.6)), with: .color(Color.vyrethPaper.opacity(0.85)))
                context.fill(Path(CGRect(x: w * 0.55, y: h * 0.2, width: w * 0.28, height: h * 0.6)), with: .color(Color.vyrethEmber))
            case "motiv":
                context.fill(Path(roundedRect: CGRect(x: w * 0.62, y: h * 0.18, width: w * 0.2, height: h * 0.28), cornerRadius: 4), with: .color(Color.vyrethFlare.opacity(0.8)))
                line(CGPoint(x: w * 0.7, y: h * 0.48), CGPoint(x: w * 0.4, y: h * 0.75), Color.vyrethFlare.opacity(0.7), 6)
            case "mood":
                context.fill(Path(ellipseIn: CGRect(x: w * 0.2, y: h * 0.25, width: w * 0.6, height: h * 0.5)), with: .color(Color.vyrethEmber.opacity(0.45)))
            case "cuts":
                for index in 0..<5 {
                    let x = w * (0.08 + CGFloat(index) * 0.18)
                    context.fill(Path(CGRect(x: x, y: h * 0.35, width: w * 0.12, height: h * 0.3)), with: .color(index.isMultiple(of: 2) ? Color.vyrethFlare : Color.vyrethMist))
                }
            case "match":
                context.stroke(Path(ellipseIn: CGRect(x: w * 0.12, y: h * 0.28, width: 36, height: 36)), with: .color(Color.vyrethFlare), lineWidth: 3)
                context.stroke(Path(ellipseIn: CGRect(x: w * 0.62, y: h * 0.28, width: 36, height: 36)), with: .color(Color.vyrethFlare), lineWidth: 3)
                line(CGPoint(x: w * 0.28, y: h * 0.46), CGPoint(x: w * 0.6, y: h * 0.46), Color.vyrethMist, 2)
            case "rhythm":
                for index in 0..<8 {
                    let bar = h * (0.2 + CGFloat(index % 4) * 0.12)
                    context.fill(Path(CGRect(x: w * (0.08 + CGFloat(index) * 0.11), y: h * 0.7 - bar, width: 8, height: bar)), with: .color(Color.vyrethFlare))
                }
            case "montage":
                ForEachBox.draw(context: &context, rects: [
                    CGRect(x: 12, y: 16, width: w * 0.4, height: h * 0.35),
                    CGRect(x: w * 0.5, y: 16, width: w * 0.4, height: h * 0.35),
                    CGRect(x: 12, y: h * 0.55, width: w * 0.4, height: h * 0.3),
                    CGRect(x: w * 0.5, y: h * 0.55, width: w * 0.4, height: h * 0.3)
                ])
            case "wipe":
                context.fill(Path(CGRect(x: 0, y: 0, width: w * 0.45, height: h)), with: .color(Color.vyrethFlare.opacity(0.45)))
                line(CGPoint(x: w * 0.45, y: 0), CGPoint(x: w * 0.62, y: h), Color.vyrethPaper, 2)
            case "pace":
                var curve = Path()
                curve.move(to: CGPoint(x: 10, y: h * 0.75))
                curve.addQuadCurve(to: CGPoint(x: w - 10, y: h * 0.3), control: CGPoint(x: w * 0.4, y: h * 0.1))
                context.stroke(curve, with: .color(Color.vyrethFlare), lineWidth: 3)
            case "diegetic":
                context.stroke(Path(ellipseIn: CGRect(x: w * 0.18, y: h * 0.25, width: w * 0.28, height: h * 0.5)), with: .color(Color.vyrethFlare), lineWidth: 3)
                context.stroke(Path(ellipseIn: CGRect(x: w * 0.52, y: h * 0.25, width: w * 0.28, height: h * 0.5)), with: .color(Color.vyrethMist), lineWidth: 2)
            case "foley":
                context.fill(Path(ellipseIn: CGRect(x: w * 0.2, y: h * 0.35, width: 28, height: 18)), with: .color(Color.vyrethFlare))
                context.fill(Path(roundedRect: CGRect(x: w * 0.5, y: h * 0.4, width: 40, height: 16), cornerRadius: 4), with: .color(Color.vyrethMist))
            case "silence":
                line(CGPoint(x: 16, y: h * 0.5), CGPoint(x: w * 0.35, y: h * 0.5), Color.vyrethMist, 2)
                line(CGPoint(x: w * 0.62, y: h * 0.5), CGPoint(x: w - 16, y: h * 0.5), Color.vyrethMist, 2)
            case "talk":
                context.stroke(Path(roundedRect: CGRect(x: w * 0.12, y: h * 0.22, width: w * 0.5, height: h * 0.28), cornerRadius: 8), with: .color(Color.vyrethFlare), lineWidth: 2)
                context.stroke(Path(roundedRect: CGRect(x: w * 0.38, y: h * 0.55, width: w * 0.48, height: h * 0.24), cornerRadius: 8), with: .color(Color.vyrethMist), lineWidth: 2)
            case "score":
                var wave = Path()
                wave.move(to: CGPoint(x: 8, y: h * 0.5))
                for step in 0..<24 {
                    let x = 8 + CGFloat(step) * (w - 16) / 24
                    let y = h * 0.5 + CGFloat(sin(Double(step) * 0.7)) * 18
                    wave.addLine(to: CGPoint(x: x, y: y))
                }
                context.stroke(wave, with: .color(Color.vyrethFlare), lineWidth: 2)
            case "mix":
                for index in 0..<4 {
                    let x = w * (0.18 + CGFloat(index) * 0.18)
                    context.fill(Path(CGRect(x: x, y: h * 0.2, width: 10, height: h * 0.6)), with: .color(Color.vyrethMist.opacity(0.4)))
                    context.fill(Path(ellipseIn: CGRect(x: x - 4, y: h * (0.25 + CGFloat(index) * 0.08), width: 18, height: 12)), with: .color(Color.vyrethFlare))
                }
            case "beats":
                for index in 0..<4 {
                    context.fill(Path(ellipseIn: CGRect(x: w * (0.12 + CGFloat(index) * 0.2), y: h * 0.4, width: 16, height: 16)), with: .color(Color.vyrethFlare))
                }
            case "desire":
                line(CGPoint(x: w * 0.15, y: h * 0.7), CGPoint(x: w * 0.8, y: h * 0.3), Color.vyrethFlare, 3)
                context.fill(Path(ellipseIn: CGRect(x: w * 0.12, y: h * 0.62, width: 16, height: 16)), with: .color(Color.vyrethPaper))
            case "goal":
                context.stroke(Path(ellipseIn: CGRect(x: w * 0.3, y: h * 0.2, width: w * 0.4, height: h * 0.6)), with: .color(Color.vyrethMist), lineWidth: 2)
                context.fill(Path(ellipseIn: CGRect(x: w * 0.45, y: h * 0.42, width: 16, height: 16)), with: .color(Color.vyrethFlare))
            case "subtext":
                line(CGPoint(x: 20, y: h * 0.35), CGPoint(x: w - 20, y: h * 0.35), Color.vyrethPaper, 2)
                line(CGPoint(x: 20, y: h * 0.62), CGPoint(x: w - 40, y: h * 0.62), Color.vyrethFlare.opacity(0.8), 2)
            case "lines":
                for index in 0..<3 {
                    line(CGPoint(x: 18, y: h * (0.28 + CGFloat(index) * 0.18)), CGPoint(x: w - 18, y: h * (0.28 + CGFloat(index) * 0.18)), Color.vyrethMist, 2)
                }
            case "logline":
                context.stroke(Path(roundedRect: CGRect(x: 16, y: h * 0.28, width: w - 32, height: h * 0.44), cornerRadius: 10), with: .color(Color.vyrethFlare), lineWidth: 2)
            case "block":
                context.fill(Path(ellipseIn: CGRect(x: w * 0.2, y: h * 0.35, width: 18, height: 18)), with: .color(Color.vyrethFlare))
                context.fill(Path(ellipseIn: CGRect(x: w * 0.55, y: h * 0.5, width: 18, height: 18)), with: .color(Color.vyrethMist))
                line(CGPoint(x: w * 0.25, y: h * 0.44), CGPoint(x: w * 0.58, y: h * 0.55), Color.vyrethMist.opacity(0.6), 1)
            case "cover":
                for index in 0..<3 {
                    var cam = Path()
                    cam.addEllipse(in: CGRect(x: w * (0.18 + CGFloat(index) * 0.22), y: h * 0.38, width: 22, height: 16))
                    context.stroke(cam, with: .color(index == 1 ? Color.vyrethFlare : Color.vyrethMist), lineWidth: 2)
                }
            case "rehearse":
                context.stroke(Path(ellipseIn: CGRect(x: w * 0.28, y: h * 0.22, width: w * 0.44, height: h * 0.56)), with: .color(Color.vyrethFlare), lineWidth: 3)
            case "tone":
                context.fill(Path(roundedRect: CGRect(x: w * 0.2, y: h * 0.35, width: w * 0.6, height: 16), cornerRadius: 8), with: .color(Color.vyrethMist.opacity(0.35)))
                context.fill(Path(ellipseIn: CGRect(x: w * 0.48, y: h * 0.3, width: 24, height: 24)), with: .color(Color.vyrethFlare))
            case "list":
                for index in 0..<4 {
                    context.fill(Path(CGRect(x: 20, y: h * (0.18 + CGFloat(index) * 0.18), width: w * 0.7, height: 8)), with: .color(Color.vyrethMist.opacity(0.7)))
                }
            default:
                context.stroke(Path(roundedRect: frame.insetBy(dx: 10, dy: 10), cornerRadius: 8), with: .color(Color.vyrethFlare), lineWidth: 2)
            }
        }
        .frame(height: 112)
        .accessibilityHidden(true)
    }
}

private enum ForEachBox {
    static func draw(context: inout GraphicsContext, rects: [CGRect]) {
        for (index, rect) in rects.enumerated() {
            let color = index == 1 ? Color.vyrethFlare : Color.vyrethMist.opacity(0.75)
            context.stroke(Path(roundedRect: rect, cornerRadius: 4), with: .color(color), lineWidth: 2)
        }
    }
}

struct VyrethPosterArt: View {
    var slot: Int

    var body: some View {
        Canvas { context, size in
            let base = Path(CGRect(origin: .zero, size: size))
            context.fill(base, with: .linearGradient(
                Gradient(colors: [Color.vyrethInk, Color.vyrethEmber.opacity(0.85), Color.vyrethPanel]),
                startPoint: CGPoint(x: CGFloat(slot % 3) * size.width / 2, y: 0),
                endPoint: CGPoint(x: size.width, y: size.height)
            ))
            let rings = 3 + (slot % 4)
            for index in 0..<rings {
                let inset = CGFloat(index) * 10 + CGFloat(slot % 5)
                let rect = CGRect(x: inset, y: inset * 1.4, width: size.width - inset * 2, height: size.height - inset * 2.2)
                context.stroke(Path(roundedRect: rect, cornerRadius: 8), with: .color(Color.vyrethFlare.opacity(0.35 + Double(index) * 0.08)), lineWidth: 2)
            }
            for hole in 0..<6 {
                let y = size.height * (0.12 + CGFloat(hole) * 0.14)
                context.fill(Path(ellipseIn: CGRect(x: 6, y: y, width: 7, height: 7)), with: .color(Color.vyrethInk))
                context.fill(Path(ellipseIn: CGRect(x: size.width - 13, y: y, width: 7, height: 7)), with: .color(Color.vyrethInk))
            }
        }
        .accessibilityHidden(true)
    }
}

struct VyrethBurst: View {
    var token: Int
    @State private var live = false

    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index.isMultiple(of: 2) ? Color.vyrethFlare : Color.vyrethMist)
                    .frame(width: 8, height: 14)
                    .offset(y: live ? -90 : 0)
                    .rotationEffect(.degrees(Double(index) / 10 * 360))
                    .opacity(live ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: token) { _ in
            live = false
            withAnimation(.easeOut(duration: 0.7)) { live = true }
        }
    }
}

struct VyrethClapper: View {
    var done: () -> Void
    @EnvironmentObject private var hub: VyrethLedgerHub
    @State private var shut = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.vyrethPanel)
                    .frame(width: 230, height: 110)
                    .shadow(color: Color.black.opacity(0.35), radius: 10, y: 6)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(colors: [Color.vyrethFlare, Color.vyrethEmber], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: 230, height: 34)
                    .rotationEffect(.degrees(shut ? 0 : -32), anchor: .leading)
            }
            .frame(width: 250, height: 150)
            Text("Marker is set")
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(Color.vyrethPaper)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .vyrethScreen(image: "hero_projection_beam", opacity: 0.45)
        .onAppear {
            VyrethHaptic.rigid(hub.blob.profile.haptics)
            if hub.motionQuiet {
                done()
            } else {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.62)) { shut = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) { done() }
            }
        }
    }
}

struct VyrethBannerStrip: View {
    var name: String

    var body: some View {
        Color.clear
            .frame(height: 92)
            .frame(maxWidth: .infinity)
            .background {
                Image(name)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.vyrethMist.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
            .accessibilityHidden(true)
    }
}
