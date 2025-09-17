import SwiftUI
import AVFoundation
#if canImport(ARKit)
import ARKit
import RealityKit
#endif

/// An AR view that lets users place plant models onto detected horizontal planes.
/// - Safe on simulators and devices without ARKit: shows a fallback message.
struct ARPlantPlacementView: View {
    let models: [PlantModel]
    @State private var selected: PlantModel?
    @State private var hasPlaced = false
    // User-adjustable scale multiplier (1.0 = default). Base scale is computed per model at placement.
    @State private var userScale: Float = 1.0
    @State private var baseScale: Float = 0.1

    var body: some View {
        Group {
#if canImport(ARKit)
            if ARWorldTrackingConfiguration.isSupported {
                ZStack(alignment: .bottom) {
                    ARContainerView(selected: $selected, placed: $hasPlaced, userScale: $userScale, baseScale: $baseScale)
                        .ignoresSafeArea()

                    // Subtle hint until a model is placed
                    if !hasPlaced {
                        VStack {
                            Text("Move iPhone to detect a surface\nTap to place a plant")
                                .font(.callout)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .padding(.top, 20)
                                .accessibilityLabel("Move device to find a surface. Tap to place the plant.")
                            Spacer()
                        }
                        .transition(.opacity)
                    }
                }
                // Keep the picker above any TabBar using a safe area inset
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 8) {
                        if hasPlaced {
                            ScaleControl(userScale: $userScale, onReset: { userScale = 1.0 })
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        ModelPicker(models: models, selected: $selected)
                    }
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            } else {
                UnsupportedView()
            }
#else
            UnsupportedView()
#endif
        }
    .navigationTitle("Place Plants")
    .navigationBarTitleDisplayMode(.inline)
    .tabBarHidden(true)
        .onAppear { if selected == nil { selected = models.first } }
    }
}

private struct UnsupportedView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arkit")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("AR is not supported on this device.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#if canImport(ARKit)
// AR container bridging into SwiftUI
private struct ARContainerView: UIViewRepresentable {
    @Binding var selected: PlantModel?
    var placed: Binding<Bool>
    @Binding var userScale: Float
    @Binding var baseScale: Float

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        view.session.run(config)

        // Tap to place model
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)

        // Coaching overlay to help find planes
        let coaching = ARCoachingOverlayView()
        coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coaching.session = view.session
        coaching.goal = .horizontalPlane
        view.addSubview(coaching)

        context.coordinator.view = view
        context.coordinator.placed = placed
        context.coordinator.baseScaleBinding = $baseScale
        context.coordinator.userScaleBinding = $userScale
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.selected = selected
        // Push latest slider value through to the entity scale safely, but only apply when it actually changed
        if context.coordinator.latestUserScaleValue != userScale {
            context.coordinator.latestUserScaleValue = userScale
            context.coordinator.applyScaleIfNeeded()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        weak var view: ARView?
        var selected: PlantModel?
        var placed: Binding<Bool>?
        var baseScaleBinding: Binding<Float>?
        var userScaleBinding: Binding<Float>?
    var latestUserScaleValue: Float = 1.0
    private var lastAppliedUserScale: Float = 1.0
        private var currentModel: ModelEntity?

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let view = view else { return }
            let location = sender.location(in: view)
            if let result = view.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .horizontal).first {
                place(at: result.worldTransform)
            }
        }

        private func place(at transform: simd_float4x4) {
            guard let selected else { return }
            guard let url = Bundle.main.url(forResource: selected.usdzName.replacingOccurrences(of: ".usdz", with: ""), withExtension: "usdz") else {
                print("[AR] Missing model: \(selected.usdzName)")
                return
            }
            do {
                // Load model and cast to ModelEntity for gesture support
                let entity = try Entity.loadModel(contentsOf: url)
                guard let model = entity as? ModelEntity else {
                    print("[AR] Loaded entity is not a ModelEntity")
                    return
                }
                // Set a smaller, consistent initial footprint ~12cm on the largest axis
                let bounds = model.visualBounds(relativeTo: nil)
                let size = bounds.extents
                let target: Float = 0.12 // 12cm to start smaller
                let maxDim = max(size.x, max(size.y, size.z))
                let base = maxDim > 0 ? target / maxDim : selected.scale
                let clampedBase = clamp(base, min: 0.02, max: 1.0)
                // Reset user scale to 1 for new placement
                userScaleBinding?.wrappedValue = 1.0
                latestUserScaleValue = 1.0
                lastAppliedUserScale = 1.0
                baseScaleBinding?.wrappedValue = clampedBase
                model.scale = SIMD3(repeating: clampedBase)
                let anchor = AnchorEntity(world: transform)
                anchor.addChild(model)
                view?.scene.addAnchor(anchor)
                enableGestures(on: model)
                currentModel = model
                placed?.wrappedValue = true
            } catch {
                print("[AR] Failed to load: \(error)")
            }
        }

        private func enableGestures(on entity: ModelEntity) {
            entity.generateCollisionShapes(recursive: true)
            view?.installGestures([.translation, .rotation, .scale], for: entity)
        }

        func applyScaleIfNeeded() {
            guard let current = currentModel else { return }
            guard lastAppliedUserScale != latestUserScaleValue else { return }
            let base = baseScaleBinding?.wrappedValue ?? 0.1
            let combined = clamp(base * latestUserScaleValue, min: 0.02, max: 3.0)
            current.scale = SIMD3(repeating: combined)
            lastAppliedUserScale = latestUserScaleValue
        }

        private func clamp(_ value: Float, min: Float, max: Float) -> Float {
            Swift.max(min, Swift.min(max, value))
        }
    }
}

// Model picker
private struct ModelPicker: View {
    let models: [PlantModel]
    @Binding var selected: PlantModel?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(models) { m in
                    Button {
                        selected = m
                    } label: {
                        Text(m.displayName)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(selected == m ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground))
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(selected == m ? Color.accentColor : Color(.separator).opacity(0.4), lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(m.displayName + (selected == m ? ", selected" : "")))
                }
            }
            .padding(12)
        }
    }
}
#endif

// MARK: - Small Scale Control UI
private struct ScaleControl: View {
    @Binding var userScale: Float
    var onReset: () -> Void

    private let range: ClosedRange<Float> = 0.5...2.0 // 50% - 200% of base

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Adjust Size", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(role: .none) { onReset() } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.borderless)
                .font(.subheadline)
                .accessibilityLabel("Reset size to default")
            }
            HStack(spacing: 12) {
                Image(systemName: "minus")
                    .foregroundStyle(.secondary)
                Slider(value: Binding(
                    get: { Double(userScale) },
                    set: { userScale = Float($0) }
                ), in: Double(range.lowerBound)...Double(range.upperBound))
                .accessibilityLabel("Size slider")
                .accessibilityValue("\(Int(userScale * 100)) percent")
                Image(systemName: "plus")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
