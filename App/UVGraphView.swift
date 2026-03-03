import SwiftUI

enum GraphMode: String {
    case today, now, tomorrow
}

struct UVGraphView: View {
    let hourlyForecast: [HourlyUVData]
    let selectedTime: Date?
    let onTimeSelect: (Date) -> Void

    @State private var graphMode: GraphMode = .now
    @State private var graphOffset: Int = 0

    private let chartHeight: CGFloat = 180
    private let windowSize = 12

    // MARK: - Data windowing

    private var windowedData: [HourlyUVData] {
        let sorted = hourlyForecast.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return [] }

        let startIndex: Int
        switch graphMode {
        case .now:
            let now = Date()
            startIndex = sorted.firstIndex(where: { $0.date >= now }) ?? 0
        case .today:
            let startOfDay = Calendar.current.startOfDay(for: Date())
            startIndex = sorted.firstIndex(where: { $0.date >= startOfDay }) ?? 0
        case .tomorrow:
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
            startIndex = sorted.firstIndex(where: { $0.date >= tomorrow }) ?? max(sorted.count - windowSize, 0)
        }

        let adjustedStart = max(0, min(startIndex + (graphOffset * windowSize), sorted.count - windowSize))
        let end = min(adjustedStart + windowSize, sorted.count)
        return Array(sorted[adjustedStart..<end])
    }

    private var canGoLeft: Bool {
        let sorted = hourlyForecast.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return false }
        let startIndex: Int
        switch graphMode {
        case .now:
            startIndex = sorted.firstIndex(where: { $0.date >= Date() }) ?? 0
        case .today:
            startIndex = sorted.firstIndex(where: { $0.date >= Calendar.current.startOfDay(for: Date()) }) ?? 0
        case .tomorrow:
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
            startIndex = sorted.firstIndex(where: { $0.date >= tomorrow }) ?? max(sorted.count - windowSize, 0)
        }
        return startIndex + ((graphOffset - 1) * windowSize) >= 0
    }

    private var canGoRight: Bool {
        let sorted = hourlyForecast.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return false }
        let startIndex: Int
        switch graphMode {
        case .now:
            startIndex = sorted.firstIndex(where: { $0.date >= Date() }) ?? 0
        case .today:
            startIndex = sorted.firstIndex(where: { $0.date >= Calendar.current.startOfDay(for: Date()) }) ?? 0
        case .tomorrow:
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
            startIndex = sorted.firstIndex(where: { $0.date >= tomorrow }) ?? max(sorted.count - windowSize, 0)
        }
        return startIndex + ((graphOffset + 1) * windowSize) + windowSize <= sorted.count
    }

    var body: some View {
        VStack(spacing: 12) {
            // Title
            Text("12-hour UV window")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)

            // Navigation row
            navigationRow

            // Chart
            if windowedData.isEmpty {
                Text("Loading UV trend data...")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(height: chartHeight)
            } else {
                chartView
            }
        }
    }

    // MARK: - Navigation Row

    private var navigationRow: some View {
        HStack(spacing: 12) {
            Button {
                if canGoLeft { graphOffset -= 1 }
            } label: {
                Text("←")
                    .font(.system(size: 18))
                    .foregroundColor(canGoLeft ? .white : .white.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(canGoLeft ? 0.15 : 0.05)))
            }
            .disabled(!canGoLeft)

            HStack(spacing: 6) {
                modeButton("Today", mode: .today)
                modeButton("Now", mode: .now)
                modeButton("Tomorrow", mode: .tomorrow)
            }

            Button {
                if canGoRight { graphOffset += 1 }
            } label: {
                Text("→")
                    .font(.system(size: 18))
                    .foregroundColor(canGoRight ? .white : .white.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(canGoRight ? 0.15 : 0.05)))
            }
            .disabled(!canGoRight)
        }
    }

    private func modeButton(_ label: String, mode: GraphMode) -> some View {
        let isActive = graphMode == mode && graphOffset == 0
        return Button {
            graphMode = mode
            graphOffset = 0
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isActive ? .white : .black)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isActive ? Color(hex: "#FFD700") : Color(hex: "#F0F0F0"))
                )
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        let data = windowedData
        let maxUV: Double = 11

        return GeometryReader { geo in
            let chartWidth = geo.size.width - 30 // leave space for Y axis
            let xOrigin: CGFloat = 30
            let yPadding: CGFloat = 20
            let plotHeight = chartHeight - yPadding * 2

            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.15))

                // Grid lines
                ForEach([0, 3, 6, 9, 11], id: \.self) { level in
                    let y = yPadding + plotHeight * (1 - CGFloat(level) / CGFloat(maxUV))

                    // Grid line
                    Path { path in
                        path.move(to: CGPoint(x: xOrigin, y: y))
                        path.addLine(to: CGPoint(x: xOrigin + chartWidth, y: y))
                    }
                    .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    // Y axis label
                    Text("\(level)")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))
                        .position(x: 14, y: y)
                }

                // Line path
                if data.count > 1 {
                    let points = data.enumerated().map { (i, entry) -> CGPoint in
                        let x = xOrigin + (CGFloat(i) / CGFloat(data.count - 1)) * chartWidth
                        let y = yPadding + plotHeight * (1 - CGFloat(entry.uvIndex) / CGFloat(maxUV))
                        return CGPoint(x: x, y: y)
                    }

                    // Filled area under curve
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: yPadding + plotHeight))
                        for pt in points {
                            path.addLine(to: pt)
                        }
                        path.addLine(to: CGPoint(x: points.last!.x, y: yPadding + plotHeight))
                        path.closeSubpath()
                    }
                    .fill(Color(hex: "#FFD700").opacity(0.1))

                    // Line
                    Path { path in
                        path.move(to: points[0])
                        for pt in points.dropFirst() {
                            path.addLine(to: pt)
                        }
                    }
                    .stroke(Color(hex: "#FFD700"), lineWidth: 2)

                    // Dots
                    ForEach(Array(data.enumerated()), id: \.offset) { i, entry in
                        let x = xOrigin + (CGFloat(i) / CGFloat(data.count - 1)) * chartWidth
                        let y = yPadding + plotHeight * (1 - CGFloat(entry.uvIndex) / CGFloat(maxUV))

                        let isNow = abs(entry.date.timeIntervalSince(Date())) < 1800
                        let isSelected = selectedTime != nil && abs(entry.date.timeIntervalSince(selectedTime!)) < 1800

                        Circle()
                            .fill(isNow || isSelected ? Color.green : Color(hex: "#FFD700"))
                            .frame(width: isNow || isSelected ? 12 : 8, height: isNow || isSelected ? 12 : 8)
                            .position(x: x, y: y)
                            .onTapGesture {
                                onTimeSelect(entry.date)
                            }
                    }
                }

                // X axis labels
                ForEach(Array(data.enumerated()), id: \.offset) { i, entry in
                    if i % xLabelInterval(count: data.count) == 0 || i == data.count - 1 {
                        let x = xOrigin + (CGFloat(i) / CGFloat(max(data.count - 1, 1))) * chartWidth

                        Text(formatHour(entry.date))
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.7))
                            .position(x: x, y: chartHeight - 4)
                    }
                }
            }
        }
        .frame(height: chartHeight)
    }

    // MARK: - Helpers

    private func xLabelInterval(count: Int) -> Int {
        if count <= 6 { return 1 }
        if count <= 12 { return 2 }
        return 3
    }

    private func formatHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let str = formatter.string(from: date)

        // Add date suffix if not today
        let cal = Calendar.current
        if !cal.isDateInToday(date) {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "M/d"
            return str + "\n" + dayFormatter.string(from: date)
        }
        return str
    }
}
