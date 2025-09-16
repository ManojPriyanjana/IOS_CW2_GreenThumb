import SwiftUI
import EventKit
import AVFoundation
import UserNotifications

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0
    private let totalPages = 4
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.green.opacity(0.3), Color.mint.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                WelcomePage().tag(0)
                FeaturesPage().tag(1)
                PermissionsPage().tag(2)
                GetStartedPage(isOnboardingComplete: $isOnboardingComplete).tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            VStack {
                Spacer()
                HStack {
                    // Skip button
                    Button("Skip") {
                        withAnimation {
                            isOnboardingComplete = true
                        }
                    }
                    .foregroundColor(.primary)
                    .opacity(currentPage < totalPages - 1 ? 1 : 0)
                    
                    Spacer()
                    
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.green : Color.gray.opacity(0.5))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    
                    Spacer()
                    
                    // Next button
                    Button(currentPage < totalPages - 1 ? "Next" : "") {
                        withAnimation {
                            if currentPage < totalPages - 1 {
                                currentPage += 1
                            }
                        }
                    }
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                    .opacity(currentPage < totalPages - 1 ? 1 : 0)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Welcome Page
struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Icon/Logo
            Image(systemName: "leaf.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: UUID())
            
            VStack(spacing: 16) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Green Thumb")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Your personal plant care companion")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Features Page
struct FeaturesPage: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("What You Can Do")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 60)
            
            VStack(spacing: 30) {
                FeatureRow(
                    icon: "camera.fill",
                    title: "Plant Disease Detection",
                    description: "Take photos to identify plant diseases and get treatment recommendations",
                    color: .blue
                )
                
                FeatureRow(
                    icon: "calendar.badge.plus",
                    title: "Smart Scheduling",
                    description: "Track watering, fertilizing, and care tasks with calendar integration",
                    color: .green
                )
                
                FeatureRow(
                    icon: "heart.text.square",
                    title: "Health Monitoring",
                    description: "Log plant health issues and get personalized care insights",
                    color: .red
                )
                
                FeatureRow(
                    icon: "basket.fill",
                    title: "Harvest Tracking",
                    description: "Monitor growth progress and track harvest schedules",
                    color: .orange
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Permissions Page
struct PermissionsPage: View {
    @State private var cameraStatus: String = "Not Requested"
    @State private var calendarStatus: String = "Not Requested"
    @State private var remindersStatus: String = "Not Requested"
    @State private var notificationsStatus: String = "Not Requested"
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Permissions Needed")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 60)
            
            Text("To provide the best experience, Green Thumb needs access to:")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            VStack(spacing: 20) {
                PermissionRow(
                    icon: "camera.fill",
                    title: "Camera",
                    description: "For plant disease detection",
                    status: cameraStatus,
                    action: requestCameraPermission
                )
                
                PermissionRow(
                    icon: "calendar",
                    title: "Calendar",
                    description: "To schedule care tasks",
                    status: calendarStatus,
                    action: requestCalendarPermission
                )
                
                PermissionRow(
                    icon: "bell.fill",
                    title: "Reminders",
                    description: "For task notifications",
                    status: remindersStatus,
                    action: requestRemindersPermission
                )
                
                PermissionRow(
                    icon: "bell.badge.fill",
                    title: "Notifications",
                    description: "For care reminders",
                    status: notificationsStatus,
                    action: requestNotificationPermission
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
        .onAppear {
            checkCurrentPermissions()
        }
    }
    
    private func checkCurrentPermissions() {
        // Check camera
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: cameraStatus = "Granted"
        case .denied, .restricted: cameraStatus = "Denied"
        case .notDetermined: cameraStatus = "Not Requested"
        @unknown default: cameraStatus = "Unknown"
        }
        
        // Check calendar
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .authorized: calendarStatus = "Granted"
        case .denied, .restricted: calendarStatus = "Denied"
        case .notDetermined: calendarStatus = "Not Requested"
        case .writeOnly: calendarStatus = "Limited"
        @unknown default: calendarStatus = "Unknown"
        }
        
        // Check reminders
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .fullAccess, .authorized: remindersStatus = "Granted"
        case .denied, .restricted: remindersStatus = "Denied"
        case .notDetermined: remindersStatus = "Not Requested"
        case .writeOnly: remindersStatus = "Limited"
        @unknown default: remindersStatus = "Unknown"
        }
        
        // Check notifications
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional: notificationsStatus = "Granted"
                case .denied: notificationsStatus = "Denied"
                case .notDetermined: notificationsStatus = "Not Requested"
                @unknown default: notificationsStatus = "Unknown"
                }
            }
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraStatus = granted ? "Granted" : "Denied"
            }
        }
    }
    
    private func requestCalendarPermission() {
        let eventStore = EKEventStore()
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    calendarStatus = granted ? "Granted" : "Denied"
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    calendarStatus = granted ? "Granted" : "Denied"
                }
            }
        }
    }
    
    private func requestRemindersPermission() {
        let eventStore = EKEventStore()
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToReminders { granted, error in
                DispatchQueue.main.async {
                    remindersStatus = granted ? "Granted" : "Denied"
                }
            }
        } else {
            eventStore.requestAccess(to: .reminder) { granted, error in
                DispatchQueue.main.async {
                    remindersStatus = granted ? "Granted" : "Denied"
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                notificationsStatus = granted ? "Granted" : "Denied"
            }
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let status: String
    let action: () -> Void
    
    private var statusColor: Color {
        switch status {
        case "Granted": return .green
        case "Denied": return .red
        case "Limited": return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 25)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(status)
                    .font(.caption2)
                    .foregroundColor(statusColor)
                    .fontWeight(.semibold)
                
                if status == "Not Requested" || status == "Denied" {
                    Button("Allow") {
                        action()
                    }
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Get Started Page
struct GetStartedPage: View {
    @Binding var isOnboardingComplete: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Start your plant care journey with Green Thumb")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                withAnimation {
                    isOnboardingComplete = true
                }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
