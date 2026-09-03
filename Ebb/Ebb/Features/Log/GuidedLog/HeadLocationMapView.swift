import SwiftUI

/// Head diagram for `location` multi_enum — replaces the pill grid (mockup K).
struct HeadLocationMapView: View {
    @Binding var selectedKeys: Set<String>

    @Environment(\.theme) private var theme

    private struct Zone: Identifiable {
        let id: String
        let key: String
        let rect: CGRect
    }

    private let zones: [Zone] = [
        Zone(id: "forehead", key: "forehead", rect: CGRect(x: 0.28, y: 0.08, width: 0.44, height: 0.18)),
        Zone(id: "left", key: "left", rect: CGRect(x: 0.06, y: 0.28, width: 0.28, height: 0.34)),
        Zone(id: "right", key: "right", rect: CGRect(x: 0.66, y: 0.28, width: 0.28, height: 0.34)),
        Zone(id: "left_eye", key: "behind_eye", rect: CGRect(x: 0.22, y: 0.36, width: 0.16, height: 0.14)),
        Zone(id: "right_eye", key: "behind_eye", rect: CGRect(x: 0.62, y: 0.36, width: 0.16, height: 0.14)),
        Zone(id: "jaw", key: "jaw", rect: CGRect(x: 0.28, y: 0.68, width: 0.44, height: 0.16)),
        Zone(id: "neck", key: "neck", rect: CGRect(x: 0.36, y: 0.84, width: 0.28, height: 0.12))
    ]

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                headSilhouette(in: size)

                ForEach(zones) { zone in
                    let frame = CGRect(
                        x: zone.rect.origin.x * size.width,
                        y: zone.rect.origin.y * size.height,
                        width: zone.rect.width * size.width,
                        height: zone.rect.height * size.height
                    )
                    Button {
                        toggle(zone.key)
                    } label: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(fillColor(for: zone.key))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(
                                        selectedKeys.contains(zone.key) ? theme.pain : theme.line,
                                        lineWidth: selectedKeys.contains(zone.key) ? 2 : 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
                    .accessibilityLabel(accessibilityLabel(for: zone.key))
                    .accessibilityAddTraits(selectedKeys.contains(zone.key) ? .isSelected : [])
                }
            }
        }
        .frame(height: 180)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Head location map")
    }

    private func headSilhouette(in size: CGSize) -> some View {
        Ellipse()
            .fill(theme.surface)
            .overlay {
                Ellipse()
                    .strokeBorder(theme.line, lineWidth: 1.5)
            }
            .frame(width: size.width * 0.78, height: size.height * 0.72)
            .position(x: size.width * 0.5, y: size.height * 0.46)
    }

    private func fillColor(for key: String) -> Color {
        selectedKeys.contains(key) ? theme.painDim : Color.clear
    }

    private func toggle(_ key: String) {
        if key == "left" || key == "right" {
            if selectedKeys.contains("bilateral") {
                selectedKeys.remove("bilateral")
            }
        }
        if key == "left", selectedKeys.contains("right") {
            selectedKeys = ["bilateral"]
            return
        }
        if key == "right", selectedKeys.contains("left") {
            selectedKeys = ["bilateral"]
            return
        }
        if selectedKeys.contains(key) {
            selectedKeys.remove(key)
        } else {
            selectedKeys.insert(key)
        }
        if selectedKeys.contains("left"), selectedKeys.contains("right") {
            selectedKeys.remove("left")
            selectedKeys.remove("right")
            selectedKeys.insert("bilateral")
        }
    }

    private func accessibilityLabel(for key: String) -> String {
        switch key {
        case "right": "Right side"
        case "left": "Left side"
        case "forehead": "Forehead"
        case "behind_eye": "Behind the eye"
        case "jaw": "Jaw or teeth"
        case "neck": "Neck"
        default: key
        }
    }
}

#Preview {
    @Previewable @State var keys: Set<String> = ["right"]
    HeadLocationMapView(selectedKeys: $keys)
        .padding()
        .background(Theme.plumEmber.base)
        .environment(\.theme, .plumEmber)
}
