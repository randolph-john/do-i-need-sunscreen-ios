import SwiftUI

struct UVGraphView: View {
    let hourlyForecast: [HourlyUVData]
    let selectedTime: Date?
    let onTimeSelect: (Date) -> Void

    private let chartHeight: CGFloat = 200

    private var allSortedData: [HourlyUVData] {
        hourlyForecast.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("UV Forecast")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)

            if allSortedData.isEmpty {
                Text("Loading UV trend data...")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(height: chartHeight)
            } else {
                chartView
            }
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        let data = allSortedData
        let maxUV: Double = 11

        return GeometryReader { geo in
            let yAxisWidth: CGFloat = 28
            let visibleChartWidth = geo.size.width - yAxisWidth
            let pointSpacing = visibleChartWidth / 11
            let edgePadding = pointSpacing / 2
            let totalWidth = pointSpacing * CGFloat(data.count - 1) + edgePadding * 2
            let yPadding: CGFloat = 20
            let xLabelHeight: CGFloat = 16
            let plotHeight = chartHeight - yPadding - xLabelHeight

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.2))

                HStack(spacing: 0) {
                    // Fixed Y-axis
                    ZStack {
                        ForEach([0, 3, 6, 9, 11], id: \.self) { level in
                            let y = yPadding + plotHeight * (1 - CGFloat(level) / CGFloat(maxUV))
                            Text("\(level)")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                                .position(x: yAxisWidth / 2, y: y)
                        }
                    }
                    .frame(width: yAxisWidth, height: chartHeight)

                    // Scrollable chart
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            scrollableChartContent(
                                data: data,
                                maxUV: maxUV,
                                totalWidth: totalWidth,
                                pointSpacing: pointSpacing,
                                edgePadding: edgePadding,
                                yPadding: yPadding,
                                plotHeight: plotHeight
                            )
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                scrollToNow(proxy: proxy, animated: false)
                            }
                        }
                        .onChange(of: allSortedData.count) { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                scrollToNow(proxy: proxy, animated: false)
                            }
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .frame(height: chartHeight)
    }

    // MARK: - Scrollable Chart Content

    @ViewBuilder
    private func scrollableChartContent(
        data: [HourlyUVData],
        maxUV: Double,
        totalWidth: CGFloat,
        pointSpacing: CGFloat,
        edgePadding: CGFloat,
        yPadding: CGFloat,
        plotHeight: CGFloat
    ) -> some View {
        let points = data.enumerated().map { (i, entry) -> CGPoint in
            let x = edgePadding + CGFloat(i) * pointSpacing
            let y = yPadding + plotHeight * (1 - CGFloat(min(entry.uvIndex, maxUV)) / CGFloat(maxUV))
            return CGPoint(x: x, y: y)
        }

        ZStack(alignment: .topLeading) {
            // Horizontal grid lines
            ForEach([0, 3, 6, 9, 11], id: \.self) { level in
                let y = yPadding + plotHeight * (1 - CGFloat(level) / CGFloat(maxUV))
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: totalWidth, y: y))
                }
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
            }

            if points.count > 1 {
                // Gradient fill under smooth curve
                catmullRomFillPath(points: points, baseline: yPadding + plotHeight)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#FFD700").opacity(0.3),
                                Color(hex: "#FFD700").opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Smooth curve line
                catmullRomPath(points: points)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "#FFD700"), Color(hex: "#FFED4E")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2.5
                    )

                // White vertical line + dot at current real time
                ForEach(Array(data.enumerated()), id: \.offset) { i, entry in
                    let isRealNow = abs(entry.date.timeIntervalSince(Date())) < 1800
                    let isSelected = selectedTime != nil && abs(entry.date.timeIntervalSince(selectedTime!)) < 1800

                    // Show white indicator at real time, but not if it's also the selected time (green will cover it)
                    if isRealNow && !isSelected {
                        Path { path in
                            path.move(to: CGPoint(x: points[i].x, y: yPadding))
                            path.addLine(to: CGPoint(x: points[i].x, y: yPadding + plotHeight))
                        }
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    }
                }

                // Green vertical indicator line at selected position
                ForEach(Array(data.enumerated()), id: \.offset) { i, entry in
                    let isSelected = selectedTime != nil
                        ? abs(entry.date.timeIntervalSince(selectedTime!)) < 1800
                        : abs(entry.date.timeIntervalSince(Date())) < 1800

                    if isSelected {
                        Path { path in
                            path.move(to: CGPoint(x: points[i].x, y: yPadding))
                            path.addLine(to: CGPoint(x: points[i].x, y: yPadding + plotHeight))
                        }
                        .stroke(Color.green.opacity(0.4), lineWidth: 1.5)
                    }
                }

                // Dots
                ForEach(Array(data.enumerated()), id: \.offset) { i, entry in
                    let isRealNow = abs(entry.date.timeIntervalSince(Date())) < 1800
                    let isSelected = selectedTime != nil
                        ? abs(entry.date.timeIntervalSince(selectedTime!)) < 1800
                        : abs(entry.date.timeIntervalSince(Date())) < 1800

                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 20, height: 20)
                            Circle()
                                .stroke(Color.green.opacity(0.5), lineWidth: 1)
                                .frame(width: 14, height: 14)
                        }
                        Circle()
                            .fill(isSelected ? Color.green
                                  : isRealNow ? Color.white
                                  : Color(hex: "#FFD700"))
                            .frame(width: isSelected ? 9 : isRealNow ? 7 : 5,
                                   height: isSelected ? 9 : isRealNow ? 7 : 5)
                    }
                    .position(x: points[i].x, y: points[i].y)
                    .id(i)
                }

                // Invisible tap targets (full column width for easy tapping)
                ForEach(Array(data.enumerated()), id: \.offset) { i, entry in
                    Color.clear
                        .frame(width: pointSpacing, height: plotHeight)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onTimeSelect(entry.date)
                        }
                        .position(x: points[i].x, y: yPadding + plotHeight / 2)
                }
            }

            // X-axis labels
            if !points.isEmpty {
                ForEach(Array(data.enumerated()), id: \.offset) { i, entry in
                    if i % 2 == 0 || i == data.count - 1 {
                        Text(formatHour(entry.date))
                            .font(.system(size: 8, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .position(x: points[i].x, y: chartHeight - 6)
                    }
                }
            }
        }
        .frame(width: totalWidth, height: chartHeight)
    }

    // MARK: - Catmull-Rom Spline

    private func catmullRomPath(points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        path.move(to: points[0])
        for i in 0..<(points.count - 1) {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]
            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6,
                y: p1.y + (p2.y - p0.y) / 6
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6,
                y: p2.y - (p3.y - p1.y) / 6
            )
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }
        return path
    }

    private func catmullRomFillPath(points: [CGPoint], baseline: CGFloat) -> Path {
        var path = catmullRomPath(points: points)
        if let last = points.last {
            path.addLine(to: CGPoint(x: last.x, y: baseline))
        }
        path.addLine(to: CGPoint(x: points[0].x, y: baseline))
        path.closeSubpath()
        return path
    }

    // MARK: - Scroll

    private func scrollToNow(proxy: ScrollViewProxy, animated: Bool) {
        let data = allSortedData
        guard !data.isEmpty else { return }
        let nowIndex = data.firstIndex(where: { $0.date >= Date() }) ?? 0
        // Offset back ~3 hours so "now" lands about 1/3 from the left edge
        let targetIndex = max(0, nowIndex - 3)
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(targetIndex, anchor: .leading)
            }
        } else {
            proxy.scrollTo(targetIndex, anchor: .leading)
        }
    }

    // MARK: - Helpers

    private func formatHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let str = formatter.string(from: date)
        let cal = Calendar.current
        if !cal.isDateInToday(date) {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "M/d"
            return str + "\n" + dayFormatter.string(from: date)
        }
        return str
    }
}
