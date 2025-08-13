// Shared/UI/Styles/CheckboxToggleStyle.swift
import SwiftUI

/// Works on iOS 15+. Replaces .toggleStyle(.checkbox)
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .imageScale(.large)
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

