# Project: Do I Need Sunscreen Right Now? (iOS)

## Meta

This file should be kept up to date. As you learn new things about the project — bugs, patterns, architectural decisions, workarounds — add them here so future sessions benefit.

## Overview
iOS port of the web app at sunscreen.fyi. Source web app is at `~/Desktop/github/do-i-need-sunscreen/`.
GitHub repo: `randolph-john/do-i-need-sunscreen-ios`

## Build & Deploy

- Uses **XcodeGen** to generate the Xcode project from `project.yml`. Homebrew install fails due to permissions — download the binary directly from GitHub releases instead:
  ```
  curl -sL https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip -o /tmp/xcodegen.zip
  unzip -o /tmp/xcodegen.zip -d /tmp/xcodegen_install
  /tmp/xcodegen_install/xcodegen/bin/xcodegen generate
  ```
- After changing any Swift files or project structure, regenerate with `xcodegen generate` before building.
- Build command:
  ```
  xcodebuild -project DoINeedSunscreen.xcodeproj -scheme DoINeedSunscreen -destination 'platform=iOS Simulator,id=<SIMULATOR_ID>' -derivedDataPath build build
  ```
- Deploy to simulator:
  ```
  xcrun simctl terminate <SIMULATOR_ID> com.sunscreenfyi.DoINeedSunscreen
  xcrun simctl install <SIMULATOR_ID> build/Build/Products/Debug-iphonesimulator/DoINeedSunscreen.app
  xcrun simctl launch <SIMULATOR_ID> com.sunscreenfyi.DoINeedSunscreen
  ```
- Find booted simulator ID with: `xcrun simctl list devices booted`

## Project Structure

- `App/` — Main app SwiftUI views (ContentView, LocationManager, WeatherService, etc.)
- `Shared/` — Algorithm, preferences, SolarCalculator (shared between app and widget)
- `Widget/` — WidgetKit extension
- `project.yml` — XcodeGen config. Two targets: DoINeedSunscreen (app) and SunscreenWidgetExtension
- App Group: `group.com.sunscreenfyi.shared`
- Bundle ID: `com.sunscreenfyi.DoINeedSunscreen`

## Architecture Notes

- **ContentView.swift** is the main view, organized into sections: `heroSection`, `uvInfoSection`, `controlsCard`, `featuresSection`, `backedByDoctorsButton`, `footerSection`
- **SolarCalculator.swift** computes sunrise/sunset using NOAA equations. Accepts a `timeZone` parameter — must pass the location's timezone when using custom locations, not `TimeZone.current`.
- **WeatherService.swift** wraps WeatherKit. Fetches current conditions + 48-hour hourly forecast. Has `selectTime()` to update displayed values for a chosen time.
- **LocationManager.swift** wraps CLLocationManager with reverse geocoding for location name.
- **SunscreenAlgorithm.swift** contains the MED-based algorithm ported from `utils.js`.

## Known Simulator Limitations

- `mailto:` URLs don't work (no Mail app in simulator). Works on real devices.
- WeatherKit's `isDaylight` property is unreliable in simulator — that's why we use SolarCalculator instead.
- Simulator timezone is the Mac's timezone, not the simulated location's. This caused a bug where SolarCalculator showed night at 9am for a different-timezone location. Fixed by passing timezone from CLPlacemark.

## Styling

- Accent color: gold `#FFD700`
- UV-reactive background colors defined in `uvBackgroundColor()` at top of ContentView.swift
- Dark text for low UV (<=5), white text for high UV or nighttime
- Controls card background uses skin-type-specific color
- Night: NightSkyView (stars + moon). Day: FloatingSunView (animated, UV-colored)
- Custom `FlowLayout` (Layout protocol) for wrapping pill buttons
