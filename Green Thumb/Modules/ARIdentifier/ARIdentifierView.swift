import SwiftUI
import AVFoundation
#if canImport(ARKit)
import ARKit
#endif

// Lightweight stub for the AR Plant Identifier module.
// Safe to compile on all devices; shows availability and permissions status.
struct ARIdentifierView: View {
    @State private var sessionSupported: Bool = {
#if canImport(ARKit)
    ARWorldTrackingConfiguration.isSupported
#else
    false
#endif
    }()
    @State private var cameraAuthorized: Bool = false

    var body: some View {
        Group {
#if canImport(ARKit)
            if sessionSupported && cameraAuthorized {
                ARPlantPlacementView(models: ARModelLibrary.all)
            } else {
                List {
                    Section("Status") {
                        Label(sessionSupported ? "ARKit supported" : "ARKit not supported", systemImage: sessionSupported ? "checkmark.circle" : "xmark.circle")
                        Label(cameraAuthorized ? "Camera authorized" : "Camera not authorized", systemImage: cameraAuthorized ? "checkmark.circle" : "exclamationmark.triangle")
                    }
                    Section("How to proceed") {
                        if !cameraAuthorized { Text("Please grant camera access when prompted.") }
                        if !sessionSupported { Text("Use a device that supports ARKit.") }
                    }
                }
            }
#else
            UnsupportedView()
#endif
        }
        .navigationTitle("AR Plant Identifier")
        .task { cameraAuthorized = await CameraAccess.check() }
    }
}

// Simple camera permission helper.
enum CameraAccess {
    static func check() async -> Bool {
        switch await AVCaptureDevice.requestAccess(for: .video) {
        case true: return true
        case false: return false
        }
    }
}
