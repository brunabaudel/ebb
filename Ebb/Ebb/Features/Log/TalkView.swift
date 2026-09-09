import SwiftUI

/// Voice capture surface — dim, near-empty, breathing orb, live transcript.
/// Transcription only; classification runs on the Confirm screen (Phase 6).
struct TalkView: View {
    let schema: SchemaConfig
    var onFinish: (String) -> Void

    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(SpeechCapture.self) private var speechCapture

    @State private var permissionPhase: PermissionPhase = .checking

    private enum PermissionPhase {
        case checking
        case denied
        case ready
    }

    var body: some View {
        NavigationStack {
            Group {
                switch permissionPhase {
                case .checking:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .denied:
                    permissionDeniedContent
                case .ready:
                    listeningContent
                }
            }
            .background(theme.base)
            .foregroundStyle(theme.text)
            .navigationTitle("Talk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { close() }
                }
                if permissionPhase == .ready {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { finish() }
                            .disabled(speechCapture.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .task {
                await preparePermissions()
            }
            .onDisappear {
                speechCapture.stopListening()
            }
        }
    }

    private var listeningContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            Text("Tell me how you feel.")
                .font(.system(.title2, design: .serif))
                .multilineTextAlignment(.center)

            Text("However it comes out — I'll sort it into the chart.")
                .font(.footnote)
                .foregroundStyle(theme.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 24)

            Spacer(minLength: 28)

            TalkListeningScene(isAnimating: speechCapture.isListening, reduceMotion: reduceMotion)
                .padding(.bottom, 32)

            LiveTranscriptCard(
                transcript: speechCapture.transcript,
                isListening: speechCapture.isListening,
                errorMessage: speechCapture.listeningError
            )
            .padding(.horizontal, 20)

            if speechCapture.listeningError != nil {
                Button("Try again") {
                    speechCapture.startListening()
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.pain)
                .padding(.top, 16)
            }

            Spacer(minLength: 24)
        }
    }

    private var permissionDeniedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()

            Label("Microphone access is off", systemImage: "mic.slash.fill")
                .font(.headline)
                .foregroundStyle(theme.pain)

            Text("Ebb needs the microphone so you can say how you feel. Recognition stays on this device — nothing is sent to a server.")
                .font(.subheadline)
                .foregroundStyle(theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            Text("You can still log with Tap on Today.")
                .font(.subheadline)
                .foregroundStyle(theme.text)

            Button("Use Tap instead") { close() }
                .buttonStyle(.borderedProminent)
                .tint(theme.pain)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            Spacer()
        }
        .padding(24)
    }

    private func preparePermissions() async {
        speechCapture.refreshAuthorizationStatus()

        switch speechCapture.authorizationStatus {
        case .authorized:
            permissionPhase = .ready
            speechCapture.startListening()
        case .notDetermined:
            await speechCapture.requestAuthorization()
            speechCapture.refreshAuthorizationStatus()
            if speechCapture.authorizationStatus == .authorized {
                permissionPhase = .ready
                speechCapture.startListening()
            } else {
                permissionPhase = .denied
            }
        case .denied, .unavailable:
            permissionPhase = .denied
        }
    }

    private func finish() {
        let text = speechCapture.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        speechCapture.stopListening()
        dismiss()
        onFinish(text)
    }

    private func close() {
        speechCapture.stopListening()
        dismiss()
    }
}

// MARK: - Listening scene

private struct TalkListeningScene: View {
    let isAnimating: Bool
    let reduceMotion: Bool

    @Environment(\.theme) private var theme
    @State private var breathe = false

    var body: some View {
        ZStack {
            if isAnimating && !reduceMotion {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.pain.opacity(0.22), theme.cycleDim.opacity(0.14), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(breathe ? 1.06 : 0.94)
                    .opacity(breathe ? 0.85 : 1)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: breathe)
            }

            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.surface, theme.painDim.opacity(0.65)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: theme.pain.opacity(theme.fabShadowOpacity), radius: 18, y: 6)

                    EbbMascot(variant: .listen, size: 88)
                }
                .frame(width: 108, height: 108)

                Image(systemName: "mic.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.onPain)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(
                            colors: [theme.pain, theme.pain.opacity(0.88)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
                    .shadow(color: theme.pain.opacity(theme.fabShadowOpacity), radius: 8, y: 3)
                    .offset(x: 8, y: 8)
                    .accessibilityHidden(true)
            }
            .accessibilityLabel(isAnimating ? "Ebb is listening" : "Ebb ready to listen")
        }
        .frame(width: 200, height: 200)
        .onAppear {
            if isAnimating && !reduceMotion {
                breathe = true
            }
        }
        .onChange(of: isAnimating) { _, listening in
            breathe = listening && !reduceMotion
        }
    }
}

// MARK: - Live transcript

private struct LiveTranscriptCard: View {
    let transcript: String
    let isListening: Bool
    var errorMessage: String?

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var statusLabel: String {
        if errorMessage != nil {
            return "Couldn't listen"
        }
        return isListening ? "Listening" : "Paused"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(statusLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(errorMessage == nil ? theme.pain : theme.muted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(theme.painDim, in: Capsule())

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    HStack(alignment: .lastTextBaseline, spacing: 0) {
                        Text(displayText)
                            .font(theme.isLight ? .system(.body, design: .serif).italic() : .body.monospaced())
                            .foregroundStyle(theme.text)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .id("transcript-body")

                        if isListening && !reduceMotion {
                            BlinkingCursor()
                                .foregroundStyle(theme.pain)
                        }
                    }
                }
                .frame(maxHeight: 200)
                .onChange(of: transcript) { _, _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("transcript-body", anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .themeCard(padding: 14, cornerRadius: theme.isLight ? 16 : 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Live transcript. \(transcript)")
    }

    private var displayText: String {
        if transcript.isEmpty {
            return "Start speaking when you're ready…"
        }
        return TranscriptFormatting.forDisplay(transcript)
    }
}

private struct BlinkingCursor: View {
    @State private var visible = true

    var body: some View {
        Text("|")
            .font(.body.monospaced())
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    visible.toggle()
                }
            }
    }
}

#Preview("Listening") {
    let capture = SpeechCapture(provider: MockSpeechRecognizer(
        transcript: "dull one on the right, barely there"
    ))
    capture.startListening()
    return TalkView(schema: try! SchemaConfig.load()) { _ in }
        .environment(\.theme, .plumEmber)
        .environment(capture)
}

#Preview("Denied") {
    TalkView(schema: try! SchemaConfig.load()) { _ in }
        .environment(\.theme, .plumEmber)
        .environment(SpeechCapture(provider: MockSpeechRecognizer(status: .denied, transcript: "")))
}
