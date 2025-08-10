import SwiftUI
import MapKit

struct StoreLocatorView: View {
    @StateObject private var vm = StoreLocatorViewModel()
    @State private var searchText: String = "plant nursery"

    private var regionBinding: Binding<MKCoordinateRegion> {
        Binding(get: { vm.region }, set: { vm.region = $0 })
    }

    private let quickFilters = [
        "plant nursery", "garden center", "agro shop", "fertilizer", "hardware"
    ]

    var body: some View {
        VStack(spacing: 0) {

            // iOS 14–16 Map initializer (no iOS 17 API used)
            Map(
                coordinateRegion: regionBinding,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: vm.results
            ) { place in
                MapMarker(coordinate: place.coordinate)
            }
            .ignoresSafeArea(edges: .top)
            .frame(height: 320)

            // Controls + results
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    TextField("Search nearby…", text: $searchText, onCommit: {
                        vm.searchNearby(searchText)
                    })
                    .textFieldStyle(.roundedBorder)

                    Button("Search") { vm.searchNearby(searchText) }
                        .buttonStyle(.borderedProminent)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(quickFilters, id: \.self) { q in
                            Button(q.capitalized) {
                                searchText = q
                                vm.searchNearby(q)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                if let msg = vm.statusMessage {
                    Text(msg).font(.footnote).foregroundStyle(.secondary)
                }

                List(vm.results, id: \.id) { place in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(place.name).font(.headline)
                        if !place.address.isEmpty {
                            Text(place.address).font(.subheadline).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 16) {
                            if let url = place.website {
                                Link("Website", destination: url)
                            }
                            Button("Open in Maps") {
                                place.item.openInMaps(
                                    launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                                )
                            }
                        }
                        .font(.callout)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
            .padding()
        }
        .navigationTitle("Nearby Stores")
        .onAppear { vm.requestLocation() }
        .alert("Location Permission Needed", isPresented: $vm.authorizationDenied) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Enable location access in Settings to search nearby stores.")
        }
    }
}
