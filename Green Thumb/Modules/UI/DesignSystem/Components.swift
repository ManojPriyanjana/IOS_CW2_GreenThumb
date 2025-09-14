//  Components.swift
//  Green Thumb
//
//  Reusable, self-contained SwiftUI components inspired by the references.

import SwiftUI

// MARK: - Card
public struct GTCard<Content: View>: View {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        VStack(alignment: .leading, spacing: GTTokens.Spacing.s) {
            content
        }
        .padding(GTTokens.Spacing.l)
        .background(GTTokens.Colors.surface)
        .cornerRadius(GTTokens.Radius.large)
        .overlay(
            RoundedRectangle(cornerRadius: GTTokens.Radius.large)
                .stroke(GTTokens.Colors.stroke, lineWidth: 1)
        )
        .gtCardShadow()
    }
}

// MARK: - Pill Button
public struct GTPillButton: View {
    public enum Style { case filled, outline, soft }
    let title: String
    let style: Style
    let systemImage: String?
    let action: () -> Void

    public init(_ title: String, style: Style = .filled, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title; self.style = style; self.systemImage = systemImage; self.action = action
    }
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(background)
            .foregroundStyle(foreground)
            .overlay(
                Capsule().stroke(GTTokens.Colors.stroke, lineWidth: style == .outline ? 1 : 0)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    private var background: some ShapeStyle {
        switch style {
        case .filled: return GTTokens.Colors.brand
        case .outline: return Color.clear
        case .soft: return GTTokens.Colors.brandSoft
        }
    }
    private var foreground: some ShapeStyle {
        switch style {
        case .filled: return Color.white
        case .outline: return GTTokens.Colors.textPrimary
        case .soft: return GTTokens.Colors.brand
        }
    }
}

// MARK: - Checklist Row
public struct GTChecklistRow: View {
    public struct Model: Identifiable {
        public var id = UUID()
        public var title: String
        public var subtitle: String?
        public var image: Image?
        public init(title: String, subtitle: String? = nil, image: Image? = nil) { self.title = title; self.subtitle = subtitle; self.image = image }
    }

    @Binding var isDone: Bool
    let model: Model

    public init(isDone: Binding<Bool>, model: Model) { self._isDone = isDone; self.model = model }

    public var body: some View {
        HStack(spacing: GTTokens.Spacing.m) {
            Button { withAnimation(.spring(response: 0.25)) { isDone.toggle() } } label: {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isDone ? GTTokens.Colors.brand : GTTokens.Colors.textTertiary)
            }
            .buttonStyle(.plain)

            if let img = model.image {
                img.resizable().scaledToFill().frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(model.title).font(.headline)
                if let subtitle = model.subtitle { Text(subtitle).font(.subheadline).foregroundStyle(GTTokens.Colors.textSecondary) }
            }
            Spacer()
            Image(systemName: "scope").foregroundStyle(GTTokens.Colors.brand)
                .padding(10).background(GTTokens.Colors.brandSoft).clipShape(Circle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(GTTokens.Colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: GTTokens.Radius.medium))
    }
}

// MARK: - Section Header
public struct GTSectionHeader: View {
    let title: String
    let subtitle: String?
    public init(_ title: String, subtitle: String? = nil) { self.title = title; self.subtitle = subtitle }
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(GTTokens.Typography.subtitle)
            if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(GTTokens.Colors.textSecondary) }
        }
        .padding(.horizontal, GTTokens.Spacing.l)
    }
}
