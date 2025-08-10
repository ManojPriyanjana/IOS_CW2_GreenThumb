import MapKit

/// Simple wrapper so we can use Map(annotationItems:) on iOS 14–16
struct Place: Identifiable, Hashable {
    let id = UUID()
    let item: MKMapItem

    var name: String { item.name ?? "Unnamed place" }
    var coordinate: CLLocationCoordinate2D { item.placemark.coordinate }
    var address: String { item.placemark.title ?? "" }
    var website: URL? { item.url }
}
