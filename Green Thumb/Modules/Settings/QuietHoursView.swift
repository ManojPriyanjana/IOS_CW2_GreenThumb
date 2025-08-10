import SwiftUI

struct QuietHoursView: View {
    @State private var start: Date
    @State private var end: Date
    let onSave: (Int, Int) -> Void

    init(start: Int, end: Int, onSave: @escaping (Int, Int) -> Void) {
        let cal = Calendar.current, today = Date()
        _start = State(initialValue: cal.date(bySettingHour: start/3600, minute: (start%3600)/60, second: 0, of: today)!)
        _end   = State(initialValue: cal.date(bySettingHour: end/3600,   minute: (end%3600)/60,   second: 0, of: today)!)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            DatePicker("Start", selection: $start, displayedComponents: .hourAndMinute)
            DatePicker("End",   selection: $end,   displayedComponents: .hourAndMinute)
            Section { Button("Save") { onSave(sec(start), sec(end)) } }
        }
        .navigationTitle("Quiet Hours")
    }

    private func sec(_ d: Date) -> Int {
        let c = Calendar.current
        return c.component(.hour, from: d)*3600 + c.component(.minute, from: d)*60
    }
}
