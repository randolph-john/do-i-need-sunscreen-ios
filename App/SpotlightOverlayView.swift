import SwiftUI

// MARK: - Tutorial Step Definition

enum TutorialStep: Int, CaseIterable {
    case answer = 0
    case inputs
    case timeLocation
    case notifications

    var title: String {
        switch self {
        case .answer: return "Your Answer"
        case .inputs: return "Personalize It"
        case .timeLocation: return "Change Time & Place"
        case .notifications: return "Daily Reminders"
        }
    }

    var description: String {
        switch self {
        case .answer: return "Your real-time sunscreen recommendation."
        case .inputs: return "Set your skin type and time outside."
        case .timeLocation: return "Check any time or place."
        case .notifications: return "Get reminded before you go out."
        }
    }

    var scrollID: String? {
        switch self {
        case .answer: return "hero"
        case .inputs: return "controls"
        case .timeLocation: return "uvInfo"
        case .notifications: return "features"
        }
    }
}

// MARK: - Preference Key for Spotlight Anchors

struct SpotlightAnchorKey: PreferenceKey {
    static var defaultValue: [TutorialStep: Anchor<CGRect>] = [:]
    static func reduce(value: inout [TutorialStep: Anchor<CGRect>], nextValue: () -> [TutorialStep: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Spotlight Overlay View

struct SpotlightOverlayView: View {
    @Binding var isPresented: Bool
    var onComplete: () -> Void
    var anchors: [TutorialStep: Anchor<CGRect>]
    var proxy: GeometryProxy
    var scrollProxy: ScrollViewProxy?

    @State private var currentStep: TutorialStep = .answer
    @State private var isAnimating = false

    private var totalSteps: Int { TutorialStep.allCases.count }
    private var currentIndex: Int { currentStep.rawValue }

    var body: some View {
        ZStack {
            // Spotlight overlay
            spotlightOverlay
                .transition(.opacity)

            tooltipCard
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.35), value: currentStep)
        .onAppear {
            if let scrollID = TutorialStep.answer.scrollID {
                withAnimation { scrollProxy?.scrollTo(scrollID, anchor: .top) }
            }
        }
    }

    @ViewBuilder
    private var spotlightOverlay: some View {
        Canvas { context, size in
            // Fill entire screen with dark overlay
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.75)))

            // Cut out the highlighted area with soft edges
            if let anchor = anchors[currentStep] {
                let rect = proxy[anchor]
                // Offset by safe area top inset because Canvas ignores safe area
                // but anchor coordinates are in GeometryReader's safe-area-inset space
                let safeTop = proxy.safeAreaInsets.top
                let paddedRect = rect.insetBy(dx: -16, dy: -12).offsetBy(dx: 0, dy: safeTop)

                // Clear the spotlight area with a radial-style soft edge
                context.blendMode = .destinationOut

                // Inner fully-clear region
                let innerPath = RoundedRectangle(cornerRadius: 16).path(in: paddedRect)
                context.fill(innerPath, with: .color(.white))

                // Soft feathered edge — multiple expanding translucent rings
                let featherSteps = 6
                let featherDistance: CGFloat = 12
                for i in 1...featherSteps {
                    let fraction = CGFloat(i) / CGFloat(featherSteps)
                    let expand = featherDistance * fraction
                    let opacity = 1.0 - fraction
                    let featherRect = paddedRect.insetBy(dx: -expand, dy: -expand)
                    let featherPath = RoundedRectangle(cornerRadius: 16 + expand).path(in: featherRect)
                    context.fill(featherPath, with: .color(.white.opacity(opacity)))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
        .onTapGesture {
            advance()
        }
    }

    @ViewBuilder
    private var tooltipCard: some View {
        if let anchor = anchors[currentStep] {
            let rect = proxy[anchor]
            let safeTop = proxy.safeAreaInsets.top
            let adjustedRect = rect.offsetBy(dx: 0, dy: safeTop)
            let screenHeight = proxy.size.height + safeTop
            let showBelow = adjustedRect.midY < screenHeight / 2

            VStack(spacing: 16) {
                Text(currentStep.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text(currentStep.description)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // Step dots
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Circle()
                            .fill(i == currentIndex ? Color(hex: "#FFD700") : Color.white.opacity(0.4))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 4)

                // Buttons
                HStack(spacing: 16) {
                    Button("Skip") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Button {
                        advance()
                    } label: {
                        Text(currentIndex < totalSteps - 1 ? "Next" : "Done")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#FFD700"), Color(hex: "#FFED4E")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(8)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
            .position(
                x: proxy.size.width / 2,
                y: showBelow
                    ? min(adjustedRect.maxY + 24 + 80, screenHeight - 120)
                    : max(adjustedRect.minY - 24 - 80, 120)
            )
        }
    }

    private func advance() {
        guard !isAnimating else { return }
        isAnimating = true

        if let nextStep = TutorialStep(rawValue: currentStep.rawValue + 1) {
            if let scrollID = nextStep.scrollID {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollProxy?.scrollTo(scrollID, anchor: .center)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    currentStep = nextStep
                }
            }
        } else {
            dismiss()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            isAnimating = false
        }
    }

    private func dismiss() {
        onComplete()
        withAnimation(.easeOut(duration: 0.25)) {
            isPresented = false
        }
    }
}
