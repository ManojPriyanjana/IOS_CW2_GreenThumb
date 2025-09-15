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

    var body: some View {
        Group {
#if canImport(ARKit)
            if ARWorldTrackingConfiguration.isSupported {
                ZStack(alignment: .bottom) {
                    ARContainerView(selected: $selected)
                        .ignoresSafeArea()
                    ModelPicker(models: models, selected: $selected)
                        .background(.ultraThinMaterial)
                }
            } else {
                UnsupportedView()
            }
#else
            UnsupportedView()
#endif
        }
        .navigationTitle("Place Plants")
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

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        view.session.run(config)

        // Tap to place model
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)

        context.coordinator.view = view
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.selected = selected
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        weak var view: ARView?
        var selected: PlantModel?

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
                model.scale = SIMD3(repeating: selected.scale)
                let anchor = AnchorEntity(world: transform)
                anchor.addChild(model)
                view?.scene.addAnchor(anchor)
                enableGestures(on: model)
            } catch {
                print("[AR] Failed to load: \(error)")
            }
        }

        private func enableGestures(on entity: ModelEntity) {
            entity.generateCollisionShapes(recursive: true)
            view?.installGestures([.translation, .rotation, .scale], for: entity)
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
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(selected == m ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                            )
                            .overlay(Capsule().stroke(selected == m ? Color.accentColor : Color(.separator).opacity(0.4), lineWidth: 1))
                    }
                }
            }
            .padding(12)
        }
    }
}
#endif
