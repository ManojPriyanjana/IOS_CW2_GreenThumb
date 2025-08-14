import SwiftUI

struct StepperHeader: View {
    let titles: [String]; let current: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<titles.count, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? AppTheme.brand : Color.gray.opacity(0.25))
                    .frame(height: 4)
                    .accessibilityLabel(Text("\(titles[i]) step \(i+1) \(i <= current ? "completed" : "pending")"))
            }
        }.padding(.vertical, 4)
    }
}
