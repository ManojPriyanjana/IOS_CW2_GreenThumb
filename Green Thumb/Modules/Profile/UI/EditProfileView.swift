import SwiftUI
import PhotosUI

public struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var workingCopy: AppUserProfile
    @State private var pickerItem: PhotosPickerItem?

    public var onSave: (AppUserProfile) -> Void

    public init(profile: AppUserProfile, onSave: @escaping (AppUserProfile) -> Void) {
        _workingCopy = State(initialValue: profile)
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Avatar") {
                    HStack(spacing: 16) {
                        avatar
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Text("Choose Photo")
                        }
                        .onChange(of: pickerItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    workingCopy.avatarImageData = data
                                }
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Change profile picture")
                }

                Section("Basic Info") {
                    TextField("Full Name", text: $workingCopy.fullName)
                        .textContentType(.name)
                    TextField("Email", text: $workingCopy.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                    TextField("Location", text: $workingCopy.location)
                        .textContentType(.addressCity)
                }

                Section("Gardening Style") {
                    Picker("Preferred", selection: $workingCopy.gardeningStyle) {
                        ForEach(AppUserProfile.GardeningStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                }

                Section("Stats (optional / demo)") {
                    Stepper("Plants: \(workingCopy.plantsCount)", value: $workingCopy.plantsCount, in: 0...999)
                    Stepper("Tasks this week: \(workingCopy.tasksCompletedThisWeek)", value: $workingCopy.tasksCompletedThisWeek, in: 0...999)
                    Stepper("Harvests: \(workingCopy.harvestCount)", value: $workingCopy.harvestCount, in: 0...999)
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(workingCopy)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }

    private var avatar: some View {
        Group {
            if let data = workingCopy.avatarImageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.green)
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(Circle())
        .overlay(Circle().stroke(.quaternary, lineWidth: 1))
    }
}
