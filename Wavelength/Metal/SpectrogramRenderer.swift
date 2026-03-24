import MetalKit
import os

@MainActor
final class SpectrogramRenderer: NSObject, MTKViewDelegate {

    let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let spectrogramTexture: SpectrogramTexture
    private let signalRegistry: SignalRegistry
    private let settingsManager: SettingsManager
    private let computePipeline: MTLComputePipelineState
    private let renderPipeline: MTLRenderPipelineState
    private let writeIndexBuffer: MTLBuffer
    private let logger = Logger(subsystem: "com.yourname.wavelength", category: "SpectrogramRenderer")

    private var lastColumnTime: ContinuousClock.Instant = .now
    private let columnInterval: Duration = .seconds(2)
    private var currentColormap: Colormap

    init(signalRegistry: SignalRegistry, settingsManager: SettingsManager) throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw RendererError.noDevice
        }
        guard let commandQueue = device.makeCommandQueue() else {
            throw RendererError.noCommandQueue
        }
        guard let library = device.makeDefaultLibrary() else {
            throw RendererError.noLibrary
        }

        self.device = device
        self.commandQueue = commandQueue
        self.signalRegistry = signalRegistry
        self.settingsManager = settingsManager
        self.currentColormap = settingsManager.colormap

        // Compute pipeline for writing spectrogram columns
        guard let computeFunction = library.makeFunction(name: "writeSpectrogramColumn") else {
            throw RendererError.shaderNotFound("writeSpectrogramColumn")
        }
        self.computePipeline = try device.makeComputePipelineState(function: computeFunction)

        // Render pipeline for displaying the spectrogram
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexFunction = library.makeFunction(name: "spectrogramVertex")
        renderDescriptor.fragmentFunction = library.makeFunction(name: "spectrogramFragment")
        renderDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        self.renderPipeline = try device.makeRenderPipelineState(descriptor: renderDescriptor)

        self.spectrogramTexture = SpectrogramTexture(
            device: device, pipelineState: computePipeline
        )

        self.writeIndexBuffer = device.makeBuffer(
            length: MemoryLayout<UInt32>.stride,
            options: .storageModeShared
        )!

        super.init()

        // Apply initial colormap from settings
        spectrogramTexture.updateColormap(currentColormap.lutData)

        logger.info("SpectrogramRenderer initialized")
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        // Check for colormap change (single enum comparison per frame)
        if settingsManager.colormap != currentColormap {
            currentColormap = settingsManager.colormap
            spectrogramTexture.updateColormap(currentColormap.lutData)
        }

        // Check if it's time to write a new column
        let now = ContinuousClock.now
        if now - lastColumnTime >= columnInterval {
            let amplitudes = Self.buildAmplitudeArray(
                from: signalRegistry.visibleSignals,
                frequencyRange: settingsManager.frequencyRange
            )
            spectrogramTexture.advanceColumn(data: amplitudes, commandBuffer: commandBuffer)
            lastColumnTime = now
        }

        // Update write index buffer for fragment shader
        let writeIdx = UInt32(spectrogramTexture.writeIndex % SpectrogramTexture.timeColumns)
        writeIndexBuffer.contents().storeBytes(of: writeIdx, as: UInt32.self)

        // Render pass: draw full-screen quad sampling the spectrogram texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setFragmentTexture(spectrogramTexture.texture, index: 0)
        renderEncoder.setFragmentBuffer(writeIndexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // No dynamic resizing needed — texture is fixed 512x1024
    }

    // MARK: - Amplitude Array Builder

    /// Convert a list of signals into a 1024-element amplitude array for the GPU.
    /// Each bin maps to a log-scale frequency in the given frequency range.
    nonisolated static func buildAmplitudeArray(
        from signals: [Signal],
        frequencyRange: ClosedRange<Double> = 70.0...6000.0,
        binCount: Int = 1024
    ) -> [Float] {
        var amplitudes = [Float](repeating: 0.0, count: binCount)

        let logLow = log10(frequencyRange.lowerBound)
        let logHigh = log10(frequencyRange.upperBound)
        let logSpan = logHigh - logLow

        guard logSpan > 0 else { return amplitudes }

        for signal in signals where signal.isActive {
            let logFreq = log10(max(signal.frequencyMHz, frequencyRange.lowerBound))
            let normalizedPosition = (logFreq - logLow) / logSpan
            let centerBin = Int(normalizedPosition * Double(binCount - 1))

            guard centerBin >= 0 && centerBin < binCount else { continue }

            // Normalize dBm to [0, 1]: -100 dBm → 0.0, -30 dBm → 1.0
            let dbm = signal.signalDBM ?? -60.0
            let amplitude = Float(max(0, min(1, (dbm + 100) / 70.0)))

            // Provenance attenuation
            let provenanceFactor: Float = switch signal.provenance {
            case .live: 1.0
            case .nearby: 0.5
            case .probable: 0.25
            }

            let finalAmplitude = amplitude * provenanceFactor

            if let bw = signal.bandwidthMHz, bw > 0 {
                // Spread across bandwidth
                let logLowBand = log10(max(signal.frequencyMHz - bw / 2, frequencyRange.lowerBound))
                let logHighBand = log10(min(signal.frequencyMHz + bw / 2, frequencyRange.upperBound))
                let binLow = max(0, Int(((logLowBand - logLow) / logSpan) * Double(binCount - 1)))
                let binHigh = min(binCount - 1, Int(((logHighBand - logLow) / logSpan) * Double(binCount - 1)))
                for bin in binLow...binHigh {
                    amplitudes[bin] = max(amplitudes[bin], finalAmplitude)
                }
            } else {
                // Point source: center + 1 neighbor each side
                for offset in -1...1 {
                    let bin = centerBin + offset
                    if bin >= 0 && bin < binCount {
                        amplitudes[bin] = max(amplitudes[bin], finalAmplitude)
                    }
                }
            }
        }

        return amplitudes
    }
}

enum RendererError: Error {
    case noDevice
    case noCommandQueue
    case noLibrary
    case shaderNotFound(String)
}
