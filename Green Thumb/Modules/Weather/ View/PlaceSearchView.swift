import SwiftUI
import MapKit
import CoreLocation

struct PlaceSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @StateObject private var completerVM = CompleterViewModel()

    let onPick: (_ coordinate: CLLocationCoordinate2D, _ displayName: String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Search city or place", text: $query)
                    .textInputAutocapitalization(.words)
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding()
                    .onChange(of: query) { completerVM.update(query: $0) }

                List(completerVM.results, id: \.self) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title).font(.body)
                        if !item.subtitle.isEmpty {
                            Text(item.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { Task { await choose(item) } }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Search location")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func choose(_ completion: MKLocalSearchCompletion) async {
        do {
            let request = MKLocalSearch.Request(completion: completion)
            let response = try await MKLocalSearch(request: request).start()
            if let mapItem = response.mapItems.first {
                let coord = mapItem.placemark.coordinate
                let name = mapItem.name ?? completion.title
                onPick(coord, name)
                dismiss()
            }
        } catch {
            // Optional: present an alert if you want
        }
    }
}

// MARK: - Autocomplete VM

private final class CompleterViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer: MKLocalSearchCompleter = {
        let c = MKLocalSearchCompleter()
        c.resultTypes = [.address, .pointOfInterest]
        return c
    }()

    override init() {
        super.init()
        completer.delegate = self
    }

    func update(query: String) {
        completer.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}
