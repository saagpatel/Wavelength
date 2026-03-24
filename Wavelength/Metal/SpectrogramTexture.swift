import Metal
import simd
import os

@MainActor
final class SpectrogramTexture {

    static let frequencyBins = 1024
    static let timeColumns = 512

    let texture: MTLTexture
    private(set) var writeIndex: Int = 0

    private let pipelineState: MTLComputePipelineState
    private let amplitudeBuffer: MTLBuffer
    private let columnIndexBuffer: MTLBuffer
    private let colormapBuffer: MTLBuffer
    private let logger = Logger(subsystem: "com.yourname.wavelength", category: "SpectrogramTexture")

    init(device: MTLDevice, pipelineState: MTLComputePipelineState) {
        self.pipelineState = pipelineState

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: Self.timeColumns,
            height: Self.frequencyBins,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.storageMode = .shared
        self.texture = device.makeTexture(descriptor: descriptor)!

        // Pre-allocate persistent buffers to avoid per-frame allocation
        self.amplitudeBuffer = device.makeBuffer(
            length: Self.frequencyBins * MemoryLayout<Float>.stride,
            options: .storageModeShared
        )!
        self.columnIndexBuffer = device.makeBuffer(
            length: MemoryLayout<UInt32>.stride,
            options: .storageModeShared
        )!

        // Colormap LUT buffer: 256 × SIMD4<Float> = 4096 bytes
        self.colormapBuffer = device.makeBuffer(
            length: 256 * MemoryLayout<SIMD4<Float>>.stride,
            options: .storageModeShared
        )!

        // Default to viridis
        updateColormap(ColormapData.viridisLUT)

        logger.info("SpectrogramTexture created: \(Self.timeColumns)x\(Self.frequencyBins), RGBA8Unorm")
    }

    /// Upload a new 256-entry colormap LUT to the GPU buffer.
    func updateColormap(_ lut: [SIMD4<Float>]) {
        guard lut.count == 256 else {
            logger.warning("updateColormap: expected 256 entries, got \(lut.count)")
            return
        }
        lut.withUnsafeBytes { ptr in
            colormapBuffer.contents().copyMemory(from: ptr.baseAddress!, byteCount: ptr.count)
        }
    }

    /// Write one column of amplitude data to the texture at the current write position.
    func advanceColumn(data: [Float], commandBuffer: MTLCommandBuffer) {
        guard data.count == Self.frequencyBins else {
            logger.warning("advanceColumn: expected \(Self.frequencyBins) values, got \(data.count)")
            return
        }

        // Copy amplitude data into persistent buffer
        data.withUnsafeBytes { ptr in
            amplitudeBuffer.contents().copyMemory(from: ptr.baseAddress!, byteCount: ptr.count)
        }

        // Set column index
        let colIndex = UInt32(writeIndex % Self.timeColumns)
        columnIndexBuffer.contents().storeBytes(of: colIndex, as: UInt32.self)

        // Encode compute pass
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        encoder.setComputePipelineState(pipelineState)
        encoder.setBuffer(amplitudeBuffer, offset: 0, index: 0)
        encoder.setBuffer(columnIndexBuffer, offset: 0, index: 1)
        encoder.setBuffer(colormapBuffer, offset: 0, index: 2)
        encoder.setTexture(texture, index: 0)

        let threadgroupSize = MTLSize(width: 64, height: 1, depth: 1)
        let gridSize = MTLSize(width: Self.frequencyBins, height: 1, depth: 1)
        encoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadgroupSize)
        encoder.endEncoding()

        writeIndex += 1
    }
}
