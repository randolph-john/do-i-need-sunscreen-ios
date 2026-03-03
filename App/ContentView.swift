import SwiftUI
import CoreLocation

// MARK: - UV Background Colors (from utils.js)

func uvBackgroundColor(uvIndex: Double, isDark: Bool) -> Color {
    if isDark { return Color(hex: "#0A0A0A") }
    let idx = Int(uvIndex)
    switch idx {
    case 0: return Color(hex: "#B0E0E6")
    case 1: return Color(hex: "#ADD8E6")
    case 2: return Color(hex: "#87CEFA")
    case 3: return Color(hex: "#FFF8DC")
    case 4: return Color(hex: "#FFEB3B")
    case 5: return Color(hex: "#FFD700")
    case 6: return Color(hex: "#FFA500")
    case 7: return Color(hex: "#FF8C00")
    case 8: return Color(hex: "#FF6347")
    case 9: return Color(hex: "#FF4500")
    case 10: return Color(hex: "#DC143C")
    default: return Color(hex: "#8B0000")
    }
}

func uvTextColor(uvIndex: Double, isDark: Bool) -> Color {
    if isDark { return .white }
    return uvIndex <= 5 ? .black : .white
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherService = WeatherService()
    @StateObject private var preferences = UserPreferences()

    @State private var showQuiz = false
    @State private var showOtherFactors = false
    @State private var showLocationChange = false
    @State private var customLocation: CLLocation?
    @State private var customLocationName: String?

    private var isDark: Bool {
        weatherService.uvIndex == 0
    }

    private var bgColor: Color {
        uvBackgroundColor(uvIndex: weatherService.uvIndex, isDark: isDark)
    }

    private var textColor: Color {
        uvTextColor(uvIndex: weatherService.uvIndex, isDark: isDark)
    }

    private var activeLocation: CLLocation? {
        customLocation ?? locationManager.location
    }

    private var activeLocationName: String? {
        customLocationName ?? locationManager.locationName
    }

    private var isUsingCustomLocation: Bool {
        customLocation != nil
    }

    var body: some View {
        ZStack {
            // Full-screen background
            bgColor.ignoresSafeArea()

            // Sky elements (stars/moon at night, sun during day)
            if isDark {
                NightSkyView()
                    .ignoresSafeArea()
            } else {
                FloatingSunView(uvIndex: weatherService.uvIndex)
                    .ignoresSafeArea()
            }

            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    uvInfoSection
                    controlsCard
                    featuresSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .refreshable {
                locationManager.requestLocation()
            }
        }
        .onAppear {
            locationManager.requestPermission()
        }
        .onChange(of: locationManager.location) { newLocation in
            // Only use GPS location if not using a custom one
            guard customLocation == nil, let location = newLocation else { return }
            let altitudeMeters = location.altitude
            if altitudeMeters >= 0 {
                preferences.elevationFeet = altitudeMeters * 3.28084
            }
            Task {
                await weatherService.fetchWeather(for: location)
            }
        }
        .sheet(isPresented: $showQuiz) {
            SkinTypeQuizView(isPresented: $showQuiz, preferences: preferences)
        }
        .sheet(isPresented: $showLocationChange) {
            LocationChangeView(isPresented: $showLocationChange) { location, name, elevation in
                customLocation = location
                customLocationName = name
                if let elevation = elevation {
                    preferences.elevationFeet = elevation * 3.28084
                }
                Task {
                    await weatherService.fetchWeather(for: location)
                }
            }
        }
    }

    // MARK: - Algorithm Result

    private var result: SunscreenResult {
        let needs = SunscreenAlgorithm.needsSunscreen(
            uvIndex: weatherService.uvIndex,
            skinType: preferences.skinType,
            durationMinutes: preferences.durationMinutes,
            cloudCover: preferences.cloudCover,
            surface: preferences.surface,
            elevationFeet: preferences.elevationFeet,
            otherFactors: preferences.otherFactors
        )
        let safeTime = SunscreenAlgorithm.safeExposureTime(
            uvIndex: weatherService.uvIndex,
            skinType: preferences.skinType,
            cloudCover: preferences.cloudCover,
            surface: preferences.surface,
            elevationFeet: preferences.elevationFeet,
            otherFactors: preferences.otherFactors
        )
        let reapply = SunscreenAlgorithm.reapplicationTime(
            uvIndex: weatherService.uvIndex,
            skinType: preferences.skinType,
            durationMinutes: preferences.durationMinutes
        )
        return SunscreenResult(
            needsSunscreen: needs,
            uvIndex: weatherService.uvIndex,
            safeExposureMinutes: safeTime,
            reapplicationMinutes: reapply
        )
    }

    // MARK: - Hero Section (Title + Giant YES/NO)

    @ViewBuilder
    private var heroSection: some View {
        VStack(spacing: 0) {
            if weatherService.isLoading {
                Spacer().frame(height: 60)
                ProgressView()
                    .tint(textColor)
                Text("Getting your location and UV data...")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(textColor)
                    .padding(.top, 16)
                Spacer().frame(height: 60)
            } else if locationManager.authorizationStatus == .notDetermined {
                Spacer().frame(height: 40)
                Text("do i need sunscreen\nright now?")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor)
                    .padding(.bottom, 30)
                Image(systemName: "location.circle")
                    .font(.system(size: 48))
                    .foregroundColor(textColor.opacity(0.7))
                Text("Location access needed to\ncheck UV conditions")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor.opacity(0.8))
                    .padding(.top, 8)
                Button("Enable Location") {
                    locationManager.requestPermission()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: "#FFD700"))
                .cornerRadius(8)
                .padding(.top, 16)
                Spacer().frame(height: 40)
            } else if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                Spacer().frame(height: 40)
                Text("do i need sunscreen\nright now?")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor)
                Image(systemName: "location.slash")
                    .font(.system(size: 48))
                    .foregroundColor(textColor.opacity(0.7))
                    .padding(.top, 20)
                Text("Location access denied.\nPlease enable in Settings.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor.opacity(0.8))
                    .padding(.top, 8)
                Spacer().frame(height: 40)
            } else {
                // Title
                Text("do i need sunscreen\nright now?")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor)
                    .tracking(1)
                    .padding(.top, 30)

                // Giant YES/NO recommendation
                Text(result.needsSunscreen ? "YES" : "NO")
                    .font(.system(size: 120, weight: .bold))
                    .foregroundColor(textColor)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                    .tracking(4)
                    .padding(.vertical, 20)
            }
        }
    }

    // MARK: - UV Info Section

    @ViewBuilder
    private var uvInfoSection: some View {
        if !weatherService.isLoading && locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            VStack(spacing: 6) {
                Text("UV Index: \(Int(weatherService.uvIndex))")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(textColor)

                if let name = activeLocationName {
                    HStack(spacing: 4) {
                        Text(name)
                            .font(.system(size: 14))
                            .foregroundColor(textColor.opacity(0.8))
                            .italic()

                        Text("(")
                            .font(.system(size: 12))
                            .foregroundColor(textColor.opacity(0.8))
                        Button("change") {
                            showLocationChange = true
                        }
                        .font(.system(size: 12).italic())
                        .foregroundColor(Color(hex: "#4A90E2"))

                        if isUsingCustomLocation {
                            Text("|")
                                .font(.system(size: 12))
                                .foregroundColor(textColor.opacity(0.8))
                            Button("reset") {
                                customLocation = nil
                                customLocationName = nil
                                if let loc = locationManager.location {
                                    let alt = loc.altitude
                                    if alt >= 0 { preferences.elevationFeet = alt * 3.28084 }
                                    Task { await weatherService.fetchWeather(for: loc) }
                                }
                            }
                            .font(.system(size: 12).italic())
                            .foregroundColor(Color(hex: "#4A90E2"))
                        }

                        Text(")")
                            .font(.system(size: 12))
                            .foregroundColor(textColor.opacity(0.8))
                    }
                }

                Text("Elevation: \(Int(preferences.elevationFeet)) ft")
                    .font(.system(size: 14))
                    .foregroundColor(textColor.opacity(0.8))
                    .italic()

                if let error = weatherService.errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                }
            }
            .padding(.bottom, 30)
        }
    }

    // MARK: - Controls Card (skin-type colored background)

    private var controlsCard: some View {
        VStack(spacing: 24) {
            // Skin Type Slider
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text("Skin \(preferences.skinType.label)")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)

                    Button("What's my skin type?") {
                        showQuiz = true
                    }
                    .font(.system(size: 14).italic())
                    .foregroundColor(Color(hex: "#4A90E2"))
                }

                Text(preferences.skinType.description)
                    .font(.system(size: 14).italic())
                    .foregroundColor(.white.opacity(0.85))

                skinTypeSlider
            }

            // Time Outdoors Slider
            VStack(spacing: 8) {
                Text("Time Outdoors: \(SunscreenAlgorithm.formatDuration(minutes: Int(preferences.durationMinutes)))")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)

                Slider(value: $preferences.durationMinutes, in: 15...480, step: 15)
                    .tint(.blue)
            }

            // Cloud Cover Toggle Buttons
            VStack(spacing: 10) {
                Text("Cloud Cover")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)

                FlowLayout(spacing: 8) {
                    ForEach(CloudCover.allCases, id: \.self) { cloud in
                        TogglePill(
                            label: cloud == .scattered ? "Scattered Clouds"
                                : cloud == .broken ? "Broken Clouds"
                                : cloud.displayName,
                            isSelected: preferences.cloudCover == cloud
                        ) {
                            preferences.cloudCover = cloud
                        }
                    }
                }
            }

            // Surface Toggle Buttons
            VStack(spacing: 10) {
                Text("Surface")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)

                FlowLayout(spacing: 8) {
                    ForEach(SurfaceType.allCases, id: \.self) { surface in
                        TogglePill(
                            label: surface.displayName,
                            isSelected: preferences.surface == surface
                        ) {
                            preferences.surface = surface
                        }
                    }
                }
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal)

            // Other Risk Factors
            VStack(spacing: 12) {
                Text("Other risk factors")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)

                Button {
                    withAnimation { showOtherFactors.toggle() }
                } label: {
                    Text(showOtherFactors ? "Hide other risk factors" : "Show other risk factors")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.85))
                        .cornerRadius(8)
                }

                if showOtherFactors {
                    VStack(spacing: 8) {
                        ForEach(OtherFactor.allCases, id: \.self) { factor in
                            Button {
                                if preferences.otherFactors.contains(factor) {
                                    preferences.otherFactors.remove(factor)
                                } else {
                                    preferences.otherFactors.insert(factor)
                                }
                            } label: {
                                HStack {
                                    Text(factor.displayName)
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                    Spacer()
                                    Image(systemName: preferences.otherFactors.contains(factor) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(preferences.otherFactors.contains(factor) ? Color(hex: "#FFD700") : .white.opacity(0.5))
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                            }
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: preferences.skinType.swatchColorHex))
        )
        .padding(.bottom, 20)
    }

    // MARK: - Skin Type Slider (custom to match website)

    private var skinTypeSlider: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let steps = 5 // 6 types, 5 intervals
            let currentStep = CGFloat(preferences.skinType.rawValue - 1)
            let thumbX = (currentStep / CGFloat(steps)) * totalWidth

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 8)

                // Filled portion
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue)
                    .frame(width: max(thumbX, 0), height: 8)

                // Thumb
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
                    .offset(x: thumbX - 12)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let fraction = min(max(value.location.x / totalWidth, 0), 1)
                                let step = Int(round(fraction * CGFloat(steps))) + 1
                                if let type = SkinType(rawValue: step) {
                                    preferences.skinType = type
                                }
                            }
                    )
            }
        }
        .frame(height: 24)
    }

    // MARK: - Share Text

    private func shareText(perspective: SharePerspective) -> String {
        let uvInt = Int(weatherService.uvIndex)
        let needs = result.needsSunscreen
        let emoji = needs ? "☀️" : "🌙"

        let subject: String
        let verb: String
        switch perspective {
        case .me:
            subject = "I"
            verb = needs ? "need" : "don't need"
        case .you:
            subject = "You"
            verb = needs ? "need" : "don't need"
        }

        let headline = "\(emoji) \(subject) \(verb) sunscreen right now!"
        let skin = "Skin: \(preferences.skinType.label) · UV: \(uvInt) · \(preferences.cloudCover.displayName)"
        var location = ""
        if let name = activeLocationName {
            location = "📍 \(name) · \(Int(preferences.elevationFeet)) ft"
        }

        var parts = [headline, "", skin]
        if !location.isEmpty { parts.append(location) }
        parts.append("")
        parts.append("https://sunscreen.fyi/")
        return parts.joined(separator: "\n")
    }

    // MARK: - Features Section (dark card at bottom)

    private var featuresSection: some View {
        VStack(spacing: 0) {
            // Skin Type Quiz
            featureRow(title: "What skin type am I?") {
                Button {
                    showQuiz = true
                } label: {
                    goldButtonLabel("Take quiz")
                }
            }

            // Divider
            Rectangle()
                .fill(textColor.opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal)

            // Share Result
            featureRow(title: "Share result") {
                HStack(spacing: 0) {
                    Button {
                        showShareSheet(text: shareText(perspective: .me))
                    } label: {
                        Text("Me")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 70)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#FFD700"), Color(hex: "#FFED4E")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .clipShape(RoundedCorner(radius: 6, corners: [.topLeft, .bottomLeft]))

                    // Thin separator
                    Rectangle()
                        .fill(Color.black.opacity(0.15))
                        .frame(width: 1)

                    Button {
                        showShareSheet(text: shareText(perspective: .you))
                    } label: {
                        Text("You")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 70)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#FFD700"), Color(hex: "#FFED4E")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .clipShape(RoundedCorner(radius: 6, corners: [.topRight, .bottomRight]))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDark
                      ? Color.white.opacity(0.08)
                      : Color.black.opacity(0.15))
        )
        .padding(.bottom, 20)
    }

    private func goldButtonLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#FFD700"), Color(hex: "#FFED4E")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(6)
    }

    private func showShareSheet(text: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        // Prevent iPad crash
        activityVC.popoverPresentationController?.sourceView = rootVC.view
        activityVC.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
        rootVC.present(activityVC, animated: true)
    }

    private func featureRow(title: String, @ViewBuilder action: () -> some View) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(textColor)
            action()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - Share Perspective

enum SharePerspective {
    case me, you
}

// MARK: - Rounded Corner Helper

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Toggle Pill Button

struct TogglePill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : .black)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isSelected ? Color(hex: "#FFD700") : Color(hex: "#F0F0F0"))
                )
        }
    }
}

// MARK: - Night Sky View

private struct Star: Identifiable {
    let id: Int
    let x: CGFloat      // 0...1 fraction
    let y: CGFloat       // 0...1 fraction
    let size: CGFloat    // point size
    let brightness: Double
    let twinkleSpeed: Double
}

struct NightSkyView: View {
    @State private var stars: [Star] = []
    @State private var twinkle = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Stars
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .opacity(twinkle ? star.brightness : star.brightness * 0.4)
                        .animation(
                            .easeInOut(duration: star.twinkleSpeed)
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                            value: twinkle
                        )
                        .position(
                            x: star.x * geo.size.width,
                            y: star.y * geo.size.height
                        )
                }

                // Moon
                MoonView()
                    .position(
                        x: geo.size.width * 0.8,
                        y: geo.size.height * 0.12
                    )
            }
            .onAppear {
                stars = (0..<40).map { i in
                    Star(
                        id: i,
                        x: CGFloat.random(in: 0...1),
                        y: CGFloat.random(in: 0...1),
                        size: CGFloat.random(in: 2...4),
                        brightness: Double.random(in: 0.6...1.0),
                        twinkleSpeed: Double.random(in: 2...5)
                    )
                }
                twinkle = true
            }
        }
    }
}

struct MoonView: View {
    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)

            // Moon body
            Circle()
                .fill(Color(hex: "#F5F5DC"))
                .frame(width: 40, height: 40)
                .shadow(color: Color.white.opacity(0.6), radius: 10)

            // Crescent shadow
            Circle()
                .fill(Color(hex: "#0A0A0A"))
                .frame(width: 34, height: 34)
                .offset(x: -8, y: -4)
        }
    }
}

// MARK: - Floating Sun View

struct FloatingSunView: View {
    let uvIndex: Double
    @State private var phase: CGFloat = 0

    private var sunColor: Color {
        if uvIndex <= 0 { return Color(hex: "#FFD700") }
        if uvIndex <= 2 { return Color(hex: "#FFE55C") }
        if uvIndex <= 5 { return Color(hex: "#FFF4A3") }
        if uvIndex <= 7 { return Color(hex: "#FFF8DC") }
        if uvIndex <= 9 { return Color(hex: "#FFFACD") }
        return .white
    }

    private var intensity: Double {
        min(uvIndex / 11.0, 1.0)
    }

    private var sunOpacity: Double {
        0.6 + (intensity * 0.4)
    }

    private var glowRadius: CGFloat {
        20 + CGFloat(intensity) * 80
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Outer glow layers
                Circle()
                    .fill(sunColor)
                    .frame(width: 80, height: 80)
                    .blur(radius: glowRadius * 0.8)
                    .opacity(sunOpacity * 0.3)

                Circle()
                    .fill(sunColor)
                    .frame(width: 80, height: 80)
                    .blur(radius: glowRadius * 0.4)
                    .opacity(sunOpacity * 0.5)

                // Sun body
                Circle()
                    .fill(sunColor)
                    .frame(width: 80, height: 80)
                    .blur(radius: 2)
                    .opacity(sunOpacity)
            }
            .position(
                x: geo.size.width * 0.82 + sin(phase) * 10,
                y: geo.size.height * 0.1 + cos(phase * 0.7) * 15
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 6)
                    .repeatForever(autoreverses: true)
                ) {
                    phase = .pi * 2
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Flow Layout (wrapping horizontal layout for pills)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        // First pass: calculate all sizes
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }

        // Calculate total width of all items in a row to center them
        var rows: [[Int]] = [[]]
        var rowWidth: CGFloat = 0

        for (index, size) in sizes.enumerated() {
            if rowWidth + size.width + (rows[rows.count - 1].isEmpty ? 0 : spacing) > maxWidth {
                rows.append([index])
                rowWidth = size.width
            } else {
                rowWidth += (rows[rows.count - 1].isEmpty ? 0 : spacing) + size.width
                rows[rows.count - 1].append(index)
            }
        }

        // Second pass: place centered
        currentY = 0
        for row in rows {
            let rowWidthTotal = row.reduce(CGFloat(0)) { sum, idx in
                sum + sizes[idx].width
            } + CGFloat(max(row.count - 1, 0)) * spacing

            currentX = (maxWidth - rowWidthTotal) / 2
            lineHeight = 0

            for idx in row {
                while positions.count <= idx {
                    positions.append(.zero)
                }
                positions[idx] = CGPoint(x: currentX, y: currentY)
                currentX += sizes[idx].width + spacing
                lineHeight = max(lineHeight, sizes[idx].height)
                maxX = max(maxX, currentX)
            }
            currentY += lineHeight + spacing
        }

        // Fill any remaining positions
        while positions.count < subviews.count {
            positions.append(.zero)
        }

        return (positions, CGSize(width: maxWidth, height: currentY - spacing))
    }
}
