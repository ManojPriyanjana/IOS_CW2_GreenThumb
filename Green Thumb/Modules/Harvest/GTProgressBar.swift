import SwiftUI

struct GTProgressBar: View {
    var value: Double // 0...1
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: geo.size.height/2).fill(Color(.systemGray5))
                RoundedRectangle(cornerRadius: geo.size.height/2).fill(Color.green)
                    .frame(width: geo.size.width * max(0, min(1, value)))
            }
        }
        .frame(height: 8)
        .accessibilityLabel("Readiness")
        .accessibilityValue("\(Int(value*100)) percent")
    }
}
