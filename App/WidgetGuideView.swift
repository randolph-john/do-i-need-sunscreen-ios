import SwiftUI

struct WidgetGuideView: View {
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Title
                    VStack(spacing: 12) {
                        Image(systemName: "apps.iphone")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "#FFD700"))

                        Text("Add a Widget")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("See your sunscreen status at a glance.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)

                    // Home Screen Widget
                    homeScreenPreview
                    widgetInstructionCard(
                        icon: "square.grid.2x2",
                        title: "Home Screen Widget",
                        steps: [
                            WidgetStep(icon: "hand.tap", text: "Long press on your home screen"),
                            WidgetStep(icon: "plus.circle", text: "Tap the + button in the top corner"),
                            WidgetStep(icon: "magnifyingglass", text: "Search for \"Sunscreen\""),
                            WidgetStep(icon: "checkmark.circle", text: "Choose a size and tap \"Add Widget\"")
                        ]
                    )

                    // Lock Screen Widget
                    lockScreenPreview
                    widgetInstructionCard(
                        icon: "lock.iphone",
                        title: "Lock Screen Widget",
                        steps: [
                            WidgetStep(icon: "hand.tap", text: "Long press on your lock screen"),
                            WidgetStep(icon: "slider.horizontal.3", text: "Tap \"Customize\" then select your lock screen"),
                            WidgetStep(icon: "rectangle.badge.plus", text: "Tap the widget area above or below the time"),
                            WidgetStep(icon: "magnifyingglass", text: "Search for \"Sunscreen\" and add it")
                        ]
                    )

                    // Done button
                    Button {
                        AnalyticsService.logEvent("widget_guide_completed")
                        onDismiss()
                    } label: {
                        Text("Got it!")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#FFD700"), Color(hex: "#FFED4E")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Widget Previews

    private var homeScreenPreview: some View {
        VStack(spacing: 8) {
            Text("Home Screen")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1)

            smallWidgetPreview
        }
    }

    private var lockScreenPreview: some View {
        VStack(spacing: 8) {
            Text("Lock Screen")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 16) {
                circularWidgetPreview
                rectangularWidgetPreview
            }
        }
    }

    // Small home screen widget
    private var smallWidgetPreview: some View {
        VStack(spacing: 6) {
            Image(systemName: "sun.max.trianglebadge.exclamationmark")
                .font(.system(size: 32))
                .foregroundColor(.black)

            Text("YES")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)

            Text("UV 7")
                .font(.system(size: 13))
                .foregroundColor(.black.opacity(0.8))

            Text("Apply in 45m")
                .font(.system(size: 11))
                .foregroundColor(.black.opacity(0.8))

            Text("Now")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.black.opacity(0.6))
        }
        .frame(width: 155, height: 155)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(red: 1.0, green: 0.55, blue: 0.0))
        )
    }

    // Circular lock screen widget
    private var circularWidgetPreview: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.15))
            VStack(spacing: 1) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Text("YES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 52, height: 52)
    }

    // Rectangular lock screen widget
    private var rectangularWidgetPreview: some View {
        HStack(spacing: 8) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 22))
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Sunscreen needed")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Text("UV 7")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.15))
        )
    }

    // MARK: - Instruction Card

    private func widgetInstructionCard(icon: String, title: String, steps: [WidgetStep]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#FFD700"))
                    .frame(width: 32)

                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#FFD700").opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: step.icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#FFD700"))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Step \(index + 1)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "#FFD700").opacity(0.7))
                            Text(step.text)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }
}

private struct WidgetStep {
    let icon: String
    let text: String
}
