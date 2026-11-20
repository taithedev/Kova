import SwiftUI
import AVFoundation
import Combine

/// Native AVFoundation capture (not a system image picker). The capture
/// session runs off the main thread and is stopped when the camera closes.
final class KovaCaptureController: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    @Published private(set) var isReady = false
    @Published private(set) var isRecording = false
    @Published private(set) var capturedURL: URL?
    @Published var errorMessage: String?
    @Published private(set) var isFrontFacing = false
    @Published private(set) var torchOn = false

    let session = AVCaptureSession()
    private let output = AVCaptureMovieFileOutput()
    private let queue = DispatchQueue(label: "app.kova.camera", qos: .userInitiated)
    private var currentDevice: AVCaptureDevice?
    private var didConfigure = false
    private var capturingURL: URL?

    @MainActor
    func prepare() async {
        let cameraAllowed = await AVCaptureDevice.requestAccess(for: .video)
        let micAllowed = await AVCaptureDevice.requestAccess(for: .audio)
        guard cameraAllowed else {
            errorMessage = "Enable camera access in iPhone Settings to record videos."
            return
        }
        guard !didConfigure else { startPreview(); return }
        session.beginConfiguration()
        session.sessionPreset = .high
        do {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video,
                                                      position: .back) else {
                throw CaptureIssue.unavailable
            }
            try session.addInput(AVCaptureDeviceInput(device: device))
            currentDevice = device
            if micAllowed, let audioDevice = AVCaptureDevice.default(for: .audio) {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioInput) { session.addInput(audioInput) }
            }
            guard session.canAddOutput(output) else { throw CaptureIssue.unavailable }
            session.addOutput(output)
            if let connection = output.connection(with: .video),
               connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            output.maxRecordedDuration = CMTime(seconds: 120, preferredTimescale: 600)
            session.commitConfiguration()
            didConfigure = true
            isReady = true
            startPreview()
        } catch {
            session.commitConfiguration()
            errorMessage = "This iPhone camera could not be initialized."
        }
    }

    func startPreview() {
        guard didConfigure else { return }
        let captureSession = session
        queue.async { if !captureSession.isRunning { captureSession.startRunning() } }
    }

    func stopPreview() {
        if output.isRecording { output.stopRecording() }
        if torchOn { toggleTorch() }
        let captureSession = session
        queue.async { if captureSession.isRunning { captureSession.stopRunning() } }
    }

    func startRecording() {
        guard isReady, !output.isRecording else { return }
        capturedURL = nil
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("kova-recording-" + UUID().uuidString)
            .appendingPathExtension("mov")
        capturingURL = file
        output.startRecording(to: file, recordingDelegate: self)
        isRecording = true
    }

    func stopRecording() {
        guard output.isRecording else { return }
        output.stopRecording()
        isRecording = false
    }

    func flipCamera() {
        guard isReady, !output.isRecording else { return }
        let direction: AVCaptureDevice.Position = isFrontFacing ? .back : .front
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                  for: .video, position: direction),
              let newInput = try? AVCaptureDeviceInput(device: device),
              let previous = session.inputs.first(where: { $0 is AVCaptureDeviceInput &&
                  ($0 as? AVCaptureDeviceInput)?.device.hasMediaType(.video) == true }) else { return }
        session.beginConfiguration()
        session.removeInput(previous)
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            currentDevice = device
            isFrontFacing.toggle()
            torchOn = false
        } else {
            session.addInput(previous)
        }
        session.commitConfiguration()
    }

    func toggleTorch() {
        guard let device = currentDevice, device.hasTorch, !isFrontFacing else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = device.torchMode == .on ? .off : .on
            torchOn = device.torchMode == .on
            device.unlockForConfiguration()
        } catch { errorMessage = "Flashlight isn't available." }
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
            if error != nil {
                self.errorMessage = "Recording failed. Check available storage and retry."
                return
            }
            self.capturedURL = outputFileURL
        }
    }

    private enum CaptureIssue: Error { case unavailable }
}

private final class KovaCameraPreviewHost: UIView {
    override static var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }
}
struct KovaCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> UIView {
        let view = KovaCameraPreviewHost()
        view.previewLayer.session = session
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        (uiView as? KovaCameraPreviewHost)?.previewLayer.session = session
    }
}

struct KovaRecorderView: View {
    let onRecorded: (URL, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = KovaCaptureController()
    @State private var filter = "Original"
    @State private var length = 30
    @State private var gridEnabled = false
    @State private var recordingSince: Date?
    @State private var elapsed = 0.0
    @State private var countdown = 0
    private let ticker = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    private let filters = ["Original", "Mono", "Warm", "Cool", "Vivid"]

    var body: some View {
        GeometryReader { bounds in
            ZStack {
                Color.black.ignoresSafeArea()
                KovaCameraPreview(session: camera.session)
                    .ignoresSafeArea()
                    .overlay(alignment: .center) {
                        if gridEnabled { cameraGrid.allowsHitTesting(false) }
                    }
                    .overlay {
                        // Lightweight live preview; the selected color treatment is
                        // actually rendered into the video by the export editor.
                        liveFilter
                            .allowsHitTesting(false)
                            .ignoresSafeArea()
                    }

                VStack(spacing: 13) {
                    HStack(spacing: 12) {
                        Button("Close", systemImage: "xmark") { dismiss() }
                            .labelStyle(.iconOnly)
                            .accessibilityLabel("Close camera")
                        Spacer()
                        if camera.isRecording {
                            Label(String(format: "%02d:%02d", Int(elapsed)/60, Int(elapsed)%60),
                                  systemImage: "record.circle")
                                .foregroundStyle(.red).font(.headline.monospacedDigit())
                        } else {
                            Text("KOVA CAMERA").font(.caption.bold()).tracking(1.5)
                        }
                        Spacer()
                        Button {
                            gridEnabled.toggle()
                        } label: {
                            Image(systemName: "square.grid.3x3")
                        }
                        .accessibilityLabel("Toggle camera guides")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .padding(15)
                    .background(.ultraThinMaterial, in: Capsule())

                    HStack(spacing: 8) {
                        ForEach([15, 30, 60, 120], id: \.self) { seconds in
                            Button("\(seconds)s") { length = seconds }
                                .font(.caption.bold())
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(length == seconds ? .white.opacity(0.3) : .white.opacity(0.08),
                                            in: Capsule())
                                .disabled(camera.isRecording)
                        }
                    }
                    Spacer()
                    if countdown > 0 {
                        Text("\(countdown)")
                            .font(.system(size: 88, weight: .black))
                            .shadow(color: .black.opacity(0.5), radius: 15)
                    }
                    if let message = camera.errorMessage {
                        Text(message)
                            .font(.footnote)
                            .padding(10)
                            .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
                    }
                    Spacer()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(filters, id: \.self) { option in
                                Button(option) { filter = option }
                                    .font(.caption.bold())
                                    .padding(.horizontal, 14).padding(.vertical, 9)
                                    .background(filter == option ? .white.opacity(0.28) : .black.opacity(0.35),
                                                in: Capsule())
                            }
                        }
                    }
                    .disabled(camera.isRecording)
                    HStack {
                        Button {
                            camera.toggleTorch()
                        } label: {
                            Image(systemName: camera.torchOn ? "bolt.fill" : "bolt.slash.fill")
                                .frame(width: 50, height: 50)
                        }
                        .accessibilityLabel("Toggle flashlight")
                        .disabled(camera.isFrontFacing)

                        Spacer()
                        Button {
                            if camera.isRecording {
                                camera.stopRecording()
                            } else {
                                beginCountdown()
                            }
                        } label: {
                            ZStack {
                                Circle().stroke(.white, lineWidth: 5)
                                    .frame(width: 80, height: 80)
                                RoundedRectangle(cornerRadius: camera.isRecording ? 11 : 37)
                                    .fill(.red)
                                    .frame(width: camera.isRecording ? 34 : 61,
                                           height: camera.isRecording ? 34 : 61)
                            }
                        }
                        .disabled(!camera.isReady || countdown > 0)
                        .accessibilityLabel(camera.isRecording ? "Stop recording" : "Start recording")

                        Spacer()
                        Button {
                            camera.flipCamera()
                        } label: {
                            Image(systemName: "camera.rotate")
                                .frame(width: 50, height: 50)
                        }
                        .disabled(camera.isRecording)
                        .accessibilityLabel("Flip camera")
                    }
                    .font(.system(size: 24))
                    .padding(.horizontal, 19)
                    Text("Record • Edit • Post")
                        .font(.footnote.bold())
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.bottom, max(12, bounds.safeAreaInsets.bottom))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
            }
        }
        .task { await camera.prepare() }
        .onDisappear { camera.stopPreview() }
        .onReceive(ticker) { _ in
            guard camera.isRecording, let began = recordingSince else { return }
            elapsed = Date().timeIntervalSince(began)
            if elapsed >= Double(length) { camera.stopRecording() }
        }
        .onChange(of: camera.capturedURL) { _, url in
            if let url {
                onRecorded(url, filter)
                dismiss()
            }
        }
    }

    private var cameraGrid: some View {
        GeometryReader { geometry in
            Path { path in
                for i in 1...2 {
                    let x = geometry.size.width * CGFloat(i) / 3
                    let y = geometry.size.height * CGFloat(i) / 3
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(.white.opacity(0.25), lineWidth: 1)
        }
    }

    @ViewBuilder private var liveFilter: some View {
        switch filter {
        case "Warm": Color.orange.opacity(0.12)
        case "Cool": Color.cyan.opacity(0.09)
        case "Mono": Color.gray.opacity(0.13)
        case "Vivid": Color.pink.opacity(0.07)
        default: Color.clear
        }
    }

    private func beginCountdown() {
        countdown = 3
        Task { @MainActor in
            for time in [3, 2, 1] {
                countdown = time
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { countdown = 0; return }
            }
            countdown = 0
            recordingSince = .now
            elapsed = 0
            camera.startRecording()
        }
    }
}
