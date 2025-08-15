import SwiftUI

extension Binding where Value == Date? {
    func or(_ defaultValue: @autoclosure @escaping () -> Date) -> Binding<Date> {
        Binding<Date>(
            get: { self.wrappedValue ?? defaultValue() },
            set: { self.wrappedValue = $0 }
        )
    }
}
