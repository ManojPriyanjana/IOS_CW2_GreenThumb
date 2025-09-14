//  DashboardConceptView.swift
//  Green Thumb
//
//  A self-contained, previewable concept screen inspired by the references.
//  Uses mock data only to avoid touching Core Data or existing flows.

import SwiftUI

struct DashboardConceptView: View {
    @State private var search = ""
    @State private var checklist = [
        GTChecklistRow.Model(title: "Water Monstera", subtitle: "Today", image: Image(systemName: "leaf")),
        GTChecklistRow.Model(title: "Fertilize Basil", subtitle: "In 2 days", image: Image(systemName: "leaf.fill")),
        GTChecklistRow.Model(title: "Repot Snake Plant", subtitle: "Next week", image: Image(systemName: "tray"))
    ]
    @State private var done = [false, false, false]

    var body: some View {
        ScrollView {
            VStack(spacing: GTTokens.Spacing.xl) {
                header
                heroCard
                quickActions
                checklistCard
            }
            .padding(.vertical, GTTokens.Spacing.xl)
            .padding(.horizontal, GTTokens.Spacing.l)
            .background(GTTokens.Colors.background.ignoresSafeArea())
        }
        .navigationTitle("Garden")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Image(systemName: "bell") } }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Good afternoon")
                .font(GTTokens.Typography.caption)
                .foregroundStyle(GTTokens.Colors.textSecondary)
            Text("Welcome to your garden! 😊")
                .font(GTTokens.Typography.title)
                .foregroundStyle(GTTokens.Colors.textPrimary)
            HStack {
                Image(systemName: "leaf.circle.fill").foregroundStyle(GTTokens.Colors.brand)
                Text("4 plants").font(.callout)
                Spacer()
                GTPillButton("Add", systemImage: "plus") {}
            }
        }
    }

    private var heroCard: some View {
        GTCard {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Smart Plant Care")
                        .font(GTTokens.Typography.subtitle)
                    Text("Personalized tasks based on weather, season, and your plant's schedule.")
                        .font(.subheadline)
                        .foregroundStyle(GTTokens.Colors.textSecondary)
                }
                Spacer()
                Image(systemName: "sprinkler.and.droplets.fill")
                    .font(.largeTitle)
                    .foregroundStyle(GTTokens.Colors.brand)
                    .padding(12)
                    .background(GTTokens.Colors.brandSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: GTTokens.Spacing.m) {
            GTCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tasks")
                        .font(.headline)
                    Text("Water Monstera • Today")
                        .font(.subheadline)
                        .foregroundStyle(GTTokens.Colors.textSecondary)
                }
            }
            GTCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weather")
                        .font(.headline)
                    Text("72°F • Sunny")
                        .font(.subheadline)
                        .foregroundStyle(GTTokens.Colors.textSecondary)
                }
            }
        }
    }

    private var checklistCard: some View {
        VStack(spacing: GTTokens.Spacing.m) {
            GTSectionHeader("Today's To‑dos", subtitle: "Tap to check off")
            ForEach(Array(checklist.enumerated()), id: \ .offset) { index, item in
                GTChecklistRow(isDone: $done[index], model: item)
            }
            HStack {
                Spacer()
                GTPillButton("Checkout", style: .filled, systemImage: "checkmark") {}
            }
            .padding(.top, 4)
        }
    }
}

#if DEBUG
struct DashboardConceptView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { DashboardConceptView() }
    }
}
#endif
