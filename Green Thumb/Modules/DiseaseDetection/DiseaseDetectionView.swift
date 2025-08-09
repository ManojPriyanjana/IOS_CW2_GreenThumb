import SwiftUI

struct DiseaseDetectionView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Disease Identifier")
                .font(.largeTitle).bold()
            Text("Coming soon…")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
