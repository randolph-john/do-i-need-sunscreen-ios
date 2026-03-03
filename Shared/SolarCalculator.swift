import Foundation

/// Simple solar position calculator for sunrise/sunset times.
/// Uses the NOAA solar equations to determine if it's daylight at a given time and location.
struct SolarCalculator {

    /// Returns true if the sun is above the horizon at the given time and location.
    static func isDaylight(at date: Date, latitude: Double, longitude: Double) -> Bool {
        let (sunrise, sunset) = sunriseSunset(for: date, latitude: latitude, longitude: longitude)
        guard let sr = sunrise, let ss = sunset else {
            // Polar day/night: if no sunrise/sunset, check if we're in polar day
            // At high latitudes in summer, the sun never sets
            let month = Calendar.current.component(.month, from: date)
            let isNorthernSummer = (month >= 4 && month <= 9)
            if latitude > 66 { return isNorthernSummer }
            if latitude < -66 { return !isNorthernSummer }
            return false
        }
        return date >= sr && date <= ss
    }

    /// Calculate sunrise and sunset times for a given date and location.
    /// Returns nil for either if the sun doesn't rise or set (polar regions).
    static func sunriseSunset(for date: Date, latitude: Double, longitude: Double) -> (sunrise: Date?, sunset: Date?) {
        let cal = Calendar.current
        let tz = TimeZone.current

        // Day of year
        let dayOfYear = Double(cal.ordinality(of: .day, in: .year, for: date) ?? 1)

        // Longitude hour
        let lngHour = longitude / 15.0

        // Approximate time (sunrise)
        let tRise = dayOfYear + (6.0 - lngHour) / 24.0
        let tSet = dayOfYear + (18.0 - lngHour) / 24.0

        let sunrise = calcSunEvent(dayOfYear: tRise, latitude: latitude, longitude: longitude, isSunrise: true, date: date, cal: cal, tz: tz)
        let sunset = calcSunEvent(dayOfYear: tSet, latitude: latitude, longitude: longitude, isSunrise: false, date: date, cal: cal, tz: tz)

        return (sunrise, sunset)
    }

    private static func calcSunEvent(dayOfYear t: Double, latitude: Double, longitude: Double, isSunrise: Bool, date: Date, cal: Calendar, tz: TimeZone) -> Date? {
        let lngHour = longitude / 15.0

        // Sun's mean anomaly
        let M = (0.9856 * t) - 3.289

        // Sun's true longitude
        var L = M + (1.916 * sin(M.radians)) + (0.020 * sin(2 * M.radians)) + 282.634
        L = L.mod(360)

        // Right ascension
        var RA = atan(0.91764 * tan(L.radians)).degrees
        RA = RA.mod(360)

        // Adjust RA to same quadrant as L
        let lQuadrant = (floor(L / 90)) * 90
        let raQuadrant = (floor(RA / 90)) * 90
        RA = RA + (lQuadrant - raQuadrant)
        RA = RA / 15.0

        // Sun's declination
        let sinDec = 0.39782 * sin(L.radians)
        let cosDec = cos(asin(sinDec))

        // Sun's local hour angle
        let zenith = 90.833 // Official zenith (with atmospheric refraction)
        let cosH = (cos(zenith.radians) - (sinDec * sin(latitude.radians))) / (cosDec * cos(latitude.radians))

        // Sun doesn't rise or set at this location on this date
        if cosH > 1 || cosH < -1 {
            return nil
        }

        var H: Double
        if isSunrise {
            H = 360 - acos(cosH).degrees
        } else {
            H = acos(cosH).degrees
        }
        H = H / 15.0

        // Local mean time of event
        let localMeanTime = H + RA - (0.06571 * t) - 6.622

        // UTC time
        var utcTime = localMeanTime - lngHour
        utcTime = utcTime.mod(24)

        // Convert to Date
        let tzOffset = Double(tz.secondsFromGMT(for: date)) / 3600.0
        var localTime = utcTime + tzOffset
        localTime = localTime.mod(24)

        let hour = Int(localTime)
        let minute = Int((localTime - Double(hour)) * 60)

        var components = cal.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.timeZone = tz

        return cal.date(from: components)
    }
}

// MARK: - Math helpers

private extension Double {
    var radians: Double { self * .pi / 180.0 }
    var degrees: Double { self * 180.0 / .pi }
    func mod(_ value: Double) -> Double {
        let result = self.truncatingRemainder(dividingBy: value)
        return result < 0 ? result + value : result
    }
}
