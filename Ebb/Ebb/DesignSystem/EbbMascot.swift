import SwiftUI

/// Clean dusty-rose droplet mascot — **Ebb** (no mid-body S-mark).
/// Vector paths from `docs/symptom-tracker-soft-paper-tide-dusty-rose.html`.
enum EbbMascotVariant {
    case `default`
    case happy
    case rest
    case listen
}

struct EbbMascot: View {
    var variant: EbbMascotVariant = .default
    var size: CGFloat = 84

    @Environment(\.theme) private var theme

    var body: some View {
        Canvas { context, canvasSize in
            let scale = min(canvasSize.width, canvasSize.height) / viewBox
            let transform = CGAffineTransform(scaleX: scale, y: scale)

            switch variant {
            case .default:
                drawDefault(in: &context, transform: transform)
            case .happy:
                drawHappy(in: &context, transform: transform)
            case .rest:
                drawRest(in: &context, transform: transform)
            case .listen:
                drawListen(in: &context, transform: transform)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Ebb")
    }

    private var viewBox: CGFloat {
        variant == .rest ? 64 : 120
    }

    private var bodyGradient: Gradient {
        Gradient(colors: [theme.painDim, theme.pain])
    }

    private func drawDefault(in context: inout GraphicsContext, transform: CGAffineTransform) {
        drawShadow(in: &context, transform: transform, at: CGPoint(x: 60, y: 100), rx: 30, ry: 5)
        fillDroplet(
            in: &context,
            transform: transform,
            path: "M60 20C60 20 30 52 30 72c0 17.673 13.431 32 30 32s30-14.327 30-32C90 52 60 20 60 20Z"
        )
        drawEyes(in: &context, transform: transform, left: CGPoint(x: 50, y: 62), right: CGPoint(x: 70, y: 62), radius: 3.4)
        strokePath(
            in: &context,
            transform: transform,
            path: "M54 73c3.2 3.2 8.8 3.2 12 0",
            color: .black.opacity(0.38),
            lineWidth: 2.2
        )
        drawCheeks(in: &context, transform: transform)
    }

    private func drawHappy(in context: inout GraphicsContext, transform: CGAffineTransform) {
        drawShadow(in: &context, transform: transform, at: CGPoint(x: 60, y: 102), rx: 30, ry: 5)
        fillDroplet(
            in: &context,
            transform: transform,
            path: "M60 16C60 16 28 50 28 72c0 18.778 14.327 34 32 34s32-15.222 32-34C92 50 60 16 60 16Z"
        )
        drawEyes(in: &context, transform: transform, left: CGPoint(x: 50, y: 60), right: CGPoint(x: 70, y: 60), radius: 3.3)
        strokePath(
            in: &context,
            transform: transform,
            path: "M52 72c3.5 4.2 12.5 4.2 16 0",
            color: .black.opacity(0.4),
            lineWidth: 2.2
        )
        drawCheeks(in: &context, transform: transform)
        fillCircle(in: &context, transform: transform, center: CGPoint(x: 28, y: 34), radius: 2.4, color: theme.pain.opacity(0.5))
        fillCircle(in: &context, transform: transform, center: CGPoint(x: 90, y: 30), radius: 2, color: theme.pain.opacity(0.65))
    }

    private func drawRest(in context: inout GraphicsContext, transform: CGAffineTransform) {
        fillDroplet(
            in: &context,
            transform: transform,
            path: "M32 10C32 10 16 28 16 39c0 9.4 7.2 17 16 17s16-7.6 16-17C48 28 32 10 32 10Z",
            solid: theme.pain.opacity(0.82)
        )
        strokePath(
            in: &context,
            transform: transform,
            path: "M24 33c2.4-.9 4.8-.1 5.8 2M34.2 35c1.2-2.1 3.6-2.9 5.6-1.7",
            color: .black.opacity(0.42),
            lineWidth: 2.1
        )
        strokePath(
            in: &context,
            transform: transform,
            path: "M28 42c2.4 1.6 5.6 1.6 8 0",
            color: .black.opacity(0.3),
            lineWidth: 1.7
        )
        fillEllipse(
            in: &context,
            transform: transform,
            center: CGPoint(x: 32, y: 22),
            rx: 8,
            ry: 3,
            color: theme.onPain.opacity(0.22)
        )
    }

    private func drawListen(in context: inout GraphicsContext, transform: CGAffineTransform) {
        drawShadow(in: &context, transform: transform, at: CGPoint(x: 60, y: 100), rx: 30, ry: 5)
        fillDroplet(
            in: &context,
            transform: transform,
            path: "M60 20C60 20 30 52 30 72c0 17.673 13.431 32 30 32s30-14.327 30-32C90 52 60 20 60 20Z"
        )
        fillPath(
            in: &context,
            transform: transform,
            path: "M60 30c0 0-20 24-20 40C40 84 48.5 96 60 96c6 0 11.4-2.8 15.2-7.2C68 78 62 56 60 30Z",
            color: theme.painDim.opacity(0.4)
        )
        drawEyes(in: &context, transform: transform, left: CGPoint(x: 50, y: 60), right: CGPoint(x: 70, y: 60), radius: 3.3)
        fillEllipse(
            in: &context,
            transform: transform,
            center: CGPoint(x: 60, y: 74),
            rx: 6,
            ry: 4.2,
            color: .black.opacity(0.26)
        )
        strokePath(
            in: &context,
            transform: transform,
            path: "M82 46c7-2 12 3.5 10 10",
            color: theme.painDim,
            lineWidth: 3
        )
        fillCircle(in: &context, transform: transform, center: CGPoint(x: 94, y: 60), radius: 2.2, color: theme.painDim.opacity(0.5))
    }

    // MARK: - Drawing helpers

    private func fillDroplet(
        in context: inout GraphicsContext,
        transform: CGAffineTransform,
        path d: String,
        solid: Color? = nil
    ) {
        var path = svgPath(d).applying(transform)
        if let solid {
            context.fill(path, with: .color(solid))
        } else {
            context.fill(
                path,
                with: .linearGradient(
                    bodyGradient,
                    startPoint: CGPoint(x: 34, y: 22).applying(transform),
                    endPoint: CGPoint(x: 86, y: 100).applying(transform)
                )
            )
        }
    }

    private func drawShadow(
        in context: inout GraphicsContext,
        transform: CGAffineTransform,
        at center: CGPoint,
        rx: CGFloat,
        ry: CGFloat
    ) {
        var ellipse = Path(
            ellipseIn: CGRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2)
        )
        ellipse = ellipse.applying(transform)
        context.fill(ellipse, with: .color(.black.opacity(0.05)))
    }

    private func drawEyes(
        in context: inout GraphicsContext,
        transform: CGAffineTransform,
        left: CGPoint,
        right: CGPoint,
        radius: CGFloat
    ) {
        fillCircle(in: &context, transform: transform, center: left, radius: radius, color: .black.opacity(0.52))
        fillCircle(in: &context, transform: transform, center: right, radius: radius, color: .black.opacity(0.52))
    }

    private func drawCheeks(in context: inout GraphicsContext, transform: CGAffineTransform) {
        fillEllipse(
            in: &context,
            transform: transform,
            center: CGPoint(x: 44, y: 68),
            rx: 3.6,
            ry: 2.2,
            color: theme.pain.opacity(0.28)
        )
        fillEllipse(
            in: &context,
            transform: transform,
            center: CGPoint(x: 76, y: 68),
            rx: 3.6,
            ry: 2.2,
            color: theme.pain.opacity(0.28)
        )
    }

    private func fillCircle(
        in context: inout GraphicsContext,
        transform: CGAffineTransform,
        center: CGPoint,
        radius: CGFloat,
        color: Color
    ) {
        var circle = Path(
            ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
        )
        circle = circle.applying(transform)
        context.fill(circle, with: .color(color))
    }

    private func fillEllipse(
        in context: inout GraphicsContext,
        transform: CGAffineTransform,
        center: CGPoint,
        rx: CGFloat,
        ry: CGFloat,
        color: Color
    ) {
        var ellipse = Path(
            ellipseIn: CGRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2)
        )
        ellipse = ellipse.applying(transform)
        context.fill(ellipse, with: .color(color))
    }

    private func fillPath(
        in context: inout GraphicsContext,
        transform: CGAffineTransform,
        path d: String,
        color: Color
    ) {
        var path = svgPath(d).applying(transform)
        context.fill(path, with: .color(color))
    }

    private func strokePath(
        in context: inout GraphicsContext,
        transform: CGAffineTransform,
        path d: String,
        color: Color,
        lineWidth: CGFloat
    ) {
        var path = svgPath(d).applying(transform)
        context.stroke(path, with: .color(color), lineWidth: lineWidth * transform.a)
    }

    /// Minimal SVG path parser for the fixed mascot paths above.
    private func svgPath(_ d: String) -> Path {
        var path = Path()
        let tokens = tokenize(d)
        var index = 0
        var current = CGPoint.zero
        var start = CGPoint.zero
        var lastControl = CGPoint.zero

        func readNumber() -> CGFloat {
            let value = tokens[index]
            index += 1
            return CGFloat(Double(value) ?? 0)
        }

        while index < tokens.count {
            let command = tokens[index]
            index += 1

            switch command {
            case "M":
                let x = readNumber(), y = readNumber()
                current = CGPoint(x: x, y: y)
                start = current
                path.move(to: current)
            case "C":
                let x1 = readNumber(), y1 = readNumber()
                let x2 = readNumber(), y2 = readNumber()
                let x = readNumber(), y = readNumber()
                let c1 = CGPoint(x: x1, y: y1)
                let c2 = CGPoint(x: x2, y: y2)
                current = CGPoint(x: x, y: y)
                lastControl = c2
                path.addCurve(to: current, control1: c1, control2: c2)
            case "c":
                let x1 = readNumber(), y1 = readNumber()
                let x2 = readNumber(), y2 = readNumber()
                let x = readNumber(), y = readNumber()
                let c1 = CGPoint(x: current.x + x1, y: current.y + y1)
                let c2 = CGPoint(x: current.x + x2, y: current.y + y2)
                current = CGPoint(x: current.x + x, y: current.y + y)
                lastControl = c2
                path.addCurve(to: current, control1: c1, control2: c2)
            case "s":
                let x2 = readNumber(), y2 = readNumber()
                let x = readNumber(), y = readNumber()
                let c1 = CGPoint(x: current.x + (current.x - lastControl.x), y: current.y + (current.y - lastControl.y))
                let c2 = CGPoint(x: current.x + x2, y: current.y + y2)
                current = CGPoint(x: current.x + x, y: current.y + y)
                lastControl = c2
                path.addCurve(to: current, control1: c1, control2: c2)
            case "Z", "z":
                path.closeSubpath()
                current = start
            default:
                break
            }
        }

        return path
    }

    private func tokenize(_ d: String) -> [String] {
        var result: [String] = []
        var current = ""
        for char in d {
            if char.isLetter {
                if !current.isEmpty {
                    result.append(current)
                    current = ""
                }
                result.append(String(char))
            } else if char == "," || char == " " {
                if !current.isEmpty {
                    result.append(current)
                    current = ""
                }
            } else if char == "-" && !current.isEmpty {
                result.append(current)
                current = String(char)
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }
}

/// Circular well for composed Ebb moments (empty states, welcome hero).
struct EbbIllustrationWell: View {
    var variant: EbbMascotVariant
    var diameter: CGFloat
    var mascotSize: CGFloat

    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [theme.surface, theme.painDim.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: theme.cardShadowColor, radius: theme.cardShadowRadius, y: theme.cardShadowY)

            EbbMascot(variant: variant, size: mascotSize)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ebb")
    }
}

#Preview("Variants") {
    HStack(spacing: 20) {
        EbbMascot(variant: .default, size: 72)
        EbbMascot(variant: .happy, size: 72)
        EbbMascot(variant: .rest, size: 56)
        EbbMascot(variant: .listen, size: 72)
    }
    .padding()
    .background(Theme.softPaper.base)
    .environment(\.theme, .softPaper)
}
