import SwiftUI

// MARK: - Modern Component Showcase
/// A showcase view demonstrating the new modern theme components
struct ModernThemeShowcase: View {
    @State private var toggleValue = false
    @State private var textInput = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Header
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Modern Green Thumb")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundColor(AppTheme.Colors.primaryGreen)
                    Text("Updated with modern, elegant design")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.top, AppTheme.Spacing.xl)
                
                // Modern Cards Showcase
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Info Card
                    HStack(spacing: AppTheme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.primaryGradient.opacity(0.15))
                                .frame(width: 50, height: 50)
                            Image(systemName: "info.circle.fill")
                                .font(.title2)
                                .foregroundColor(AppTheme.Colors.primaryGreen)
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("Modern Design")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Text("Elegant cards with subtle shadows and rounded corners")
                                .font(AppTheme.Typography.callout)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(AppTheme.Spacing.lg)
                    .modernCard()
                    
                    // Success Card
                    HStack(spacing: AppTheme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.success.opacity(0.15))
                                .frame(width: 50, height: 50)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(AppTheme.Colors.success)
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("Enhanced Experience")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Text("Consistent spacing, modern typography, and smooth animations")
                                .font(AppTheme.Typography.callout)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(AppTheme.Spacing.lg)
                    .modernCard()
                }
                
                // Button Showcase
                VStack(spacing: AppTheme.Spacing.md) {
                    Text("Modern Buttons")
                        .font(AppTheme.Typography.title3)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: AppTheme.Spacing.md) {
                        Button("Primary Button") { }
                            .primaryButton()
                        
                        Button("Secondary Button") { }
                            .secondaryButton()
                        
                        Button("Tertiary Button") { }
                            .tertiaryButton()
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .modernCard()
                
                // Form Elements Showcase
                VStack(spacing: AppTheme.Spacing.md) {
                    Text("Modern Form Elements")
                        .font(AppTheme.Typography.title3)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: AppTheme.Spacing.lg) {
                        HStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(AppTheme.Colors.primaryGreen)
                                .frame(width: 24)
                            TextField("Modern text field", text: $textInput)
                                .font(AppTheme.Typography.body)
                        }
                        .padding(AppTheme.Spacing.lg)
                        .modernCard()
                        
                        HStack {
                            Text("Modern Toggle")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Spacer()
                            Toggle("", isOn: $toggleValue)
                                .tint(AppTheme.Colors.primaryGreen)
                        }
                        .padding(AppTheme.Spacing.lg)
                        .modernCard()
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .modernCard()
                
                Spacer(minLength: AppTheme.Spacing.xxl)
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(
            AppTheme.Colors.primaryGradient
                .opacity(0.03)
                .ignoresSafeArea()
        )
        .navigationTitle("Modern Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}
