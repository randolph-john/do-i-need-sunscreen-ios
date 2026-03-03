import SwiftUI
import CoreLocation

struct LocationChangeView: View {
    @Binding var isPresented: Bool
    let onLocationSelected: (CLLocation, String, Double?, TimeZone?) -> Void

    @State private var searchText = ""
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var results: [GeocodedLocation] = []

    private let geocoder = CLGeocoder()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search for a city or address", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit { search() }
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            results = []
                            errorMessage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)

                if isSearching {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else if results.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "map")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("Enter a location name to search")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(results) { result in
                        Button {
                            selectLocation(result)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                if let detail = result.detail {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Change Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    private func search() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isSearching = true
        errorMessage = nil
        results = []

        geocoder.cancelGeocode()
        geocoder.geocodeAddressString(query) { placemarks, error in
            DispatchQueue.main.async {
                isSearching = false
                if let error = error {
                    errorMessage = "Could not find that location. Try a different search."
                    _ = error // silence warning
                    return
                }
                guard let placemarks = placemarks, !placemarks.isEmpty else {
                    errorMessage = "No results found for \"\(query)\"."
                    return
                }
                results = placemarks.compactMap { placemark in
                    guard let location = placemark.location else { return nil }

                    let placemarkName = placemark.name
                    let subLocality = placemark.subLocality
                    let city = placemark.locality
                    let state = placemark.administrativeArea
                    let country = placemark.country

                    // Build display name — use the most specific info available
                    // placemark.name is often a landmark, address, or POI name
                    var nameParts: [String] = []
                    if let placemarkName = placemarkName { nameParts.append(placemarkName) }
                    if let subLocality = subLocality, subLocality != placemarkName { nameParts.append(subLocality) }
                    if let city = city, city != placemarkName, city != subLocality { nameParts.append(city) }
                    if let state = state { nameParts.append(state) }
                    let name = nameParts.isEmpty ? query : nameParts.joined(separator: ", ")

                    // Build detail line
                    var detailParts: [String] = []
                    if let country = country { detailParts.append(country) }
                    let coord = location.coordinate
                    detailParts.append("\(String(format: "%.2f", coord.latitude)), \(String(format: "%.2f", coord.longitude))")
                    let detail = detailParts.joined(separator: " · ")

                    return GeocodedLocation(
                        name: name,
                        detail: detail,
                        location: location,
                        elevation: location.altitude,
                        timeZone: placemark.timeZone
                    )
                }
            }
        }
    }

    private func selectLocation(_ result: GeocodedLocation) {
        let elevation: Double? = result.elevation > 0 ? result.elevation : nil
        onLocationSelected(result.location, result.name, elevation, result.timeZone)
        isPresented = false
    }
}

struct GeocodedLocation: Identifiable {
    let id = UUID()
    let name: String
    let detail: String?
    let location: CLLocation
    let elevation: Double
    let timeZone: TimeZone?
}
