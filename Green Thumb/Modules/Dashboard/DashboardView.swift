//import SwiftUI
//
//struct DashboardView: View {
//    private let items = DashboardItem.all
//    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 16)]
//
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                LazyVGrid(columns: columns, spacing: 16) {
//                    ForEach(items) { item in
//                        NavigationLink(destination: item.destination) {
//                            DashboardTile(item: item)
//                        }
//                        .buttonStyle(.plain)
//                    }
//                }
//                .padding()
//            }
//            .navigationTitle("Dashboard")
//        }
//    }
//}

import SwiftUI

struct DashboardView: View {
    private let items = DashboardItem.all
    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(items) { item in
                        NavigationLink(destination: item.destination) {
                            DashboardTile(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                    }
                }
            }
        }
    }
}

