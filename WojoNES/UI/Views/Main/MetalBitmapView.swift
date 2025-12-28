

import CoreVideo
import Foundation
import MetalKit
import SwiftUI

// MARK: - MetalBitmapView

/// A SwiftUI view that renders a pixel matrix using Metal for high-performance GPU-accelerated display.
///
/// This view is optimized for rendering a pixel framebuffer at screen refresh rate.
/// It uses Metal's hardware-accelerated rendering pipeline to efficiently display pixel art
/// with nearest-neighbor sampling (no blurring).
///
/// The view is generic over a controller type, allowing for flexible input handling.
/// The controller type must conform to `KeyboardMappableController`.
///
/// - Note: Requires Metal support. Will fatal error if Metal is not available on the device.
struct MetalBitmapView<Controller: KeyboardMappableController>: NSViewRepresentable {
    // MARK: Nested Types

    /// Coordinator that manages Metal rendering state and implements MTKViewDelegate.
    ///
    /// Handles the Metal rendering pipeline including:
    /// - Texture management for pixel data
    /// - Vertex buffer for full-screen quad
    /// - Render pipeline state
    /// - Command buffer encoding and presentation
    class Coordinator: NSObject, MTKViewDelegate {
        // MARK: Properties

        var pixmap: PixelMatrix

        // Metal resources
        private var metalDevice: MTLDevice!
        private var metalCommandQueue: MTLCommandQueue!
        private var renderPipelineState: MTLRenderPipelineState!
        private var texture: MTLTexture!
        private var vertexBuffer: MTLBuffer!

        /// Texture update region (constant for NES resolution)
        private let textureRegion = MTLRegionMake2D(0, 0, 256, 240)

        // MARK: Lifecycle

        init(pixmap: PixelMatrix) {
            self.pixmap = pixmap
        }

        // MARK: Functions

        /// Sets up the Metal rendering pipeline with device, shaders, and buffers.
        ///
        /// - Parameters:
        ///   - device: The Metal device to use for rendering
        ///   - view: The MTKView that will display the rendered content
        func setupMetal(device: MTLDevice, view: MTKView) {
            metalDevice = device

            guard let commandQueue = device.makeCommandQueue() else {
                fatalError("Failed to create Metal command queue")
            }
            metalCommandQueue = commandQueue

            // Create texture for pixel data (256×240 BGRA8)
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .bgra8Unorm,
                width: 256,
                height: 240,
                mipmapped: false
            )
            textureDescriptor.usage = [.shaderRead]

            guard let newTexture = device.makeTexture(descriptor: textureDescriptor) else {
                fatalError("Failed to create Metal texture")
            }
            texture = newTexture

            // Create full-screen quad vertices
            // Triangle strip: bottom-left, bottom-right, top-left, top-right
            let vertices = [
                Vertex(position: [-1, -1], texCoord: [0, 1]), // Bottom-left
                Vertex(position: [1, -1], texCoord: [1, 1]), // Bottom-right
                Vertex(position: [-1, 1], texCoord: [0, 0]), // Top-left
                Vertex(position: [1, 1], texCoord: [1, 0]), // Top-right
            ]

            guard
                let buffer = device.makeBuffer(
                    bytes: vertices,
                    length: vertices.count * MemoryLayout<Vertex>.stride,
                    options: []
                )
            else {
                fatalError("Failed to create vertex buffer")
            }
            vertexBuffer = buffer

            // Load shaders from default library
            guard
                let library = device.makeDefaultLibrary(),
                let vertexFunction = library.makeFunction(name: "vertexShader"),
                let fragmentFunction = library.makeFunction(name: "fragmentShader")
            else {
                fatalError("Failed to load shader functions")
            }

            // Configure vertex descriptor
            let vertexDescriptor = MTLVertexDescriptor()

            // Position attribute (float2)
            vertexDescriptor.attributes[0].format = .float2
            vertexDescriptor.attributes[0].offset = 0
            vertexDescriptor.attributes[0].bufferIndex = 0

            // Texture coordinate attribute (float2)
            vertexDescriptor.attributes[1].format = .float2
            vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
            vertexDescriptor.attributes[1].bufferIndex = 0

            // Buffer layout
            vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
            vertexDescriptor.layouts[0].stepFunction = .perVertex

            // Create render pipeline
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            pipelineDescriptor.vertexDescriptor = vertexDescriptor

            do {
                renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            } catch {
                fatalError("Failed to create render pipeline state: \(error)")
            }
        }

        // MARK: - MTKViewDelegate

        func mtkView(_: MTKView, drawableSizeWillChange _: CGSize) {
            // Handle viewport resizing if needed
        }

        /// Renders the current frame using Metal.
        ///
        /// This method is called automatically at the preferred frame rate (60 FPS).
        /// It updates the texture with the latest pixel data and renders a full-screen
        /// quad with the texture applied.
        ///
        /// - Parameter view: The MTKView requesting the draw
        func draw(in view: MTKView) {
            guard
                let renderPassDescriptor = view.currentRenderPassDescriptor,
                let commandBuffer = metalCommandQueue.makeCommandBuffer(),
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            else {
                return
            }

            // Update texture with latest pixel data
            updateTexture()

            // Encode render commands
            renderEncoder.setRenderPipelineState(renderPipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setFragmentTexture(texture, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder.endEncoding()

            // Present drawable
            if let drawable = view.currentDrawable {
                commandBuffer.present(drawable)
            }
            commandBuffer.commit()
        }

        /// Updates the Metal texture with the latest pixel data from the pixmap.
        ///
        /// This is called automatically during the render loop to ensure the displayed
        /// framebuffer matches the current emulator state.
        private func updateTexture() {
            guard pixmap.pixels.count == 256 * 240 else {
                assertionFailure("Invalid pixmap size: expected 61440 pixels, got \(pixmap.pixels.count)")
                return
            }

            texture.replace(
                region: textureRegion,
                mipmapLevel: 0,
                withBytes: pixmap.pixels.baseAddress!,
                bytesPerRow: 256 * 4
            )
        }
    }

    // MARK: Properties

    /// The pixel matrix to render
    let pixmap: PixelMatrix

    /// Callback invoked when controller input state changes
    var onControllerUpdate: ((Controller) -> Void)?

    // MARK: Functions

    func makeNSView(context: Context) -> MTKView {
        let mtkView = KeyboardPressDetectionMetalView<Controller>()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false

        // Configure Metal device
        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }

        mtkView.device = metalDevice
        context.coordinator.setupMetal(device: metalDevice, view: mtkView)

        // Configure rendering properties
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.framebufferOnly = true
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        mtkView.drawableSize = CGSize(width: pixmap.width, height: pixmap.height)

        // Wire up controller input callback
        mtkView.onControllerUpdate = onControllerUpdate

        // Enable keyboard input
        mtkView.window?.makeFirstResponder(mtkView)

        return mtkView
    }

    func updateNSView(_: MTKView, context: Context) {
        // Update coordinator with latest pixel data
        context.coordinator.pixmap = pixmap
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(pixmap: pixmap)
    }
}

// MARK: - Vertex

/// A vertex structure for the full-screen quad used to display the framebuffer.
///
/// Contains position in normalized device coordinates (-1 to 1) and texture coordinates (0 to 1).
struct Vertex {
    /// Position in normalized device coordinates (NDC)
    let position: SIMD2<Float>

    /// Texture coordinate for sampling
    let texCoord: SIMD2<Float>
}
