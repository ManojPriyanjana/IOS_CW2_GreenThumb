import SwiftUI

struct CurvedTabBarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let h = rect.height
        let w = rect.width
        let dip: CGFloat = 18   // depth of the concave curve

        path.move(to: .init(x: 0, y: 0))
        path.addLine(to: .init(x: 0, y: h))
        path.addLine(to: .init(x: w, y: h))
        path.addLine(to: .init(x: w, y: 0))

        // concave curve along the top
        path.addQuadCurve(
            to: .init(x: 0, y: 0),
            control: .init(x: w/2, y: dip)
        )
        path.closeSubpath()
        return path
    }
}

struct CustomTabBar: View {
    @Binding var selected: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { selected = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                        Text(tab.title).font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(selected == tab ? Color.green : Color.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .frame(height: 74)
        .background(
            CurvedTabBarShape()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                .overlay(CurvedTabBarShape().stroke(Color.green.opacity(0.15), lineWidth: 1))
        )
        .padding(.horizontal, 12)
    }
}
