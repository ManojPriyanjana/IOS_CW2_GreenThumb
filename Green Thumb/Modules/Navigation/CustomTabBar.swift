import SwiftUI


private struct TopRoundedBackground: Shape {
    var cornerRadius: CGFloat = 24
    func path(in rect: CGRect) -> Path {
        let p = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        return Path(p.cgPath)
    }
}

struct CustomTabBar: View {
    @Binding var selected: AppTab

    private let cornerRadius: CGFloat = 24
    private let iconSize: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let bottomInset = geo.safeAreaInsets.bottom

            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        selected = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: iconSize, weight: .semibold))
                            Text(tab.title)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(selected == tab ? Color.green : Color.gray)
                        .accessibilityLabel(tab.title)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, max(bottomInset, 14)) // extend into home-indicator area
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .background(
                TopRoundedBackground(cornerRadius: cornerRadius)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: -2)
                    .overlay(
                        TopRoundedBackground(cornerRadius: cornerRadius)
                            .stroke(Color.green.opacity(0.18), lineWidth: 1)
                    )
                    .ignoresSafeArea(edges: .bottom) // cover bottom edge fully
            )
        }
        .frame(height: 88)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

