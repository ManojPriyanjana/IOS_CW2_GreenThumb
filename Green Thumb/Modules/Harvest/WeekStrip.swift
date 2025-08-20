import SwiftUI

struct WeekStrip: View {
    @Binding var selected: Date
    private let days: [Date] = (0..<7).map {
        Calendar.current.date(byAdding: .day, value: $0, to: Date().startOfWeek)!
    }

    var body: some View {
        HStack(spacing: 18) {
            ForEach(days, id: \.self) { d in
                VStack(spacing: 4) {
                    Text(d, format: .dateTime.weekday(.abbreviated)).font(.caption2)
                    Text("\(Calendar.current.component(.day, from: d))")
                        .font(.headline)
                        .padding(8)
                        .background(
                            Circle().fill(Calendar.current.isDate(d, inSameDayAs: selected) ? Color.green : .clear)
                        )
                        .foregroundColor(Calendar.current.isDate(d, inSameDayAs: selected) ? .white : .primary)
                }
                .onTapGesture { selected = d }
                .frame(minWidth: 36, minHeight: 44)
            }
        }
        .padding(.horizontal)
    }
}

fileprivate extension Date {
    var startOfWeek: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
    }
}
