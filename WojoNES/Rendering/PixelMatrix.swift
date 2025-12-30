import CoreGraphics
import Foundation
import Metal
import MetalKit
import UniformTypeIdentifiers

/// Type alias for a mutable pointer to Int32 pixel data.
/// Used throughout the rendering pipeline for efficient pixel manipulation.
typealias PixelBuffer = UnsafeMutablePointer<Int32>

extension PixelBuffer {
    /// Allocates a new pixel buffer with the specified capacity.
    /// - Parameter pixels: The number of Int32 pixels to allocate space for.
    /// - Returns: A newly allocated mutable pointer to Int32 pixel data.
    static func with(pixels: Int) -> Self {
        allocate(capacity: pixels)
    }
}

// MARK: - PixelMatrix

/// Represents a 2D grid of 32-bit ARGB colour pixels.
/// Provides efficient pixel access, Metal texture conversion, and image I/O operations.
/// Primarily used for the NES frame buffer (256×240 pixels) and palette rendering.
public class PixelMatrix {
    // MARK: Properties

    /// Mutable buffer pointer to the raw pixel data (32-bit ARGB values per pixel)
    public var pixels: UnsafeMutableBufferPointer<Int32>

    /// Width of the pixel matrix in pixels
    public var width: Int

    /// Height of the pixel matrix in pixels
    public var height: Int

    // MARK: Computed Properties

    /// Converts the pixel matrix to a Core Graphics image (CGImage).
    /// Transforms from internal ARGB format to standard RGBA format for display.
    /// - Returns: A CGImage suitable for rendering, or nil if conversion fails.
    public var image: CGImage? {
        get {
            // Create a buffer for RGBA data (convert from ARGB)
            let bytesPerPixel = 4
            let bytesPerRow = bytesPerPixel * width
            let totalBytes = bytesPerRow * height
            var rgbaData = [UInt8](repeating: 0, count: totalBytes)

            for y in 0 ..< height {
                for x in 0 ..< width {
                    let pixel = pixels[y * width + x]
                    let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                    // Extract ARGB components and convert to RGBA for CGImage compatibility
                    let a = UInt8((pixel >> 24) & 0xFF)
                    let r = UInt8((pixel >> 16) & 0xFF)
                    let g = UInt8((pixel >> 8) & 0xFF)
                    let b = UInt8(pixel & 0xFF)
                    rgbaData[offset] = r
                    rgbaData[offset + 1] = g
                    rgbaData[offset + 2] = b
                    rgbaData[offset + 3] = a
                }
            }

            // Create CGImage from the RGBA data
            guard
                let provider = CGDataProvider(data: NSData(bytes: &rgbaData, length: totalBytes)),
                let cgImage = CGImage(
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bitsPerPixel: 32,
                    bytesPerRow: bytesPerRow,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                    provider: provider,
                    decode: nil,
                    shouldInterpolate: false,
                    intent: .defaultIntent
                )
            else {
                return nil
            }

            return cgImage
        }
        set {
            fatalError("This should not be called")
        }
    }

    /// Converts the pixel matrix to a Metal texture for GPU rendering.
    /// Allocates a Metal device and texture, then copies pixel data with format conversion (ARGB to RGBA).
    /// - Returns: An MTLTexture ready for shader operations, or nil if creation fails.
    public var metalTexture: MTLTexture? {
        // Create Metal device (required for texture allocation)
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Failed to create Metal device")
            return nil
        }

        // Create texture descriptor with RGBA format and shader read/write usage
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite]

        // Allocate Metal texture from the descriptor
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            print("Failed to create Metal texture")
            return nil
        }

        // Convert pixels to RGBA buffer (from internal ARGB format)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = bytesPerRow * height
        var rgbaData = [UInt8](repeating: 0, count: totalBytes)

        for y in 0 ..< height {
            for x in 0 ..< width {
                let pixel = pixels[y * width + x]
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                // Extract ARGB components and convert to RGBA
                let a = UInt8((pixel >> 24) & 0xFF)
                let r = UInt8((pixel >> 16) & 0xFF)
                let g = UInt8((pixel >> 8) & 0xFF)
                let b = UInt8(pixel & 0xFF)
                rgbaData[offset] = r
                rgbaData[offset + 1] = g
                rgbaData[offset + 2] = b
                rgbaData[offset + 3] = a
            }
        }
        print(height, width)

        // Copy RGBA data into the Metal texture
        texture.replace(
            region: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0,
            withBytes: &rgbaData,
            bytesPerRow: bytesPerRow
        )

        return texture
    }

    // MARK: Lifecycle

    /// Initialises a new pixel matrix with specified dimensions.
    /// Allocates raw pixel memory and initialises all pixels to a default red colour.
    /// - Parameters:
    ///   - width: The width of the matrix in pixels.
    ///   - height: The height of the matrix in pixels.
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
        pixels = UnsafeMutableBufferPointer<Int32>.allocate(capacity: width * height)
        pixels.initialize(repeating: 0xFF0000)
    }

    // MARK: Functions

    /// Subscript for direct pixel access using (x, y) coordinates.
    /// Performs 2D-to-1D indexing conversion based on row-major storage.
    /// - Parameters:
    ///   - x: The X coordinate of the pixel.
    ///   - y: The Y coordinate of the pixel.
    /// - Returns: The 32-bit ARGB colour value at the specified coordinate.
    public subscript(x: Int, y: Int) -> Int32 {
        get {
            pixels[y * width + x]
        }
        set {
            pixels[y * width + x] = newValue
        }
    }

    /// Concatenates another pixel matrix horizontally (side-by-side).
    /// Creates a new matrix with combined width and identical height.
    /// - Parameter other: The pixel matrix to append on the right.
    /// - Returns: A new PixelMatrix with pixels from both matrices arranged horizontally.
    public func horzCat(_ other: PixelMatrix) -> PixelMatrix {
        let result = PixelMatrix(width: width + other.width, height: height)
        for row in 0 ..< result.height {
            let destOffset = row * result.width
            let srcOffset1 = row * width
            let srcOffset2 = row * other.width
            result.pixels[destOffset ..< destOffset + width] = pixels[srcOffset1 ..< srcOffset1 + width]
            result.pixels[destOffset + width ..< destOffset + width + other.width] = other.pixels[srcOffset2 ..< srcOffset2 + other.width]
        }
        return result
    }

    /// Concatenates another pixel matrix vertically (top-to-bottom).
    /// Creates a new matrix with identical width and combined height.
    /// - Parameter other: The pixel matrix to append below.
    /// - Returns: A new PixelMatrix with pixels from both matrices arranged vertically.
    public func vertCat(_ other: PixelMatrix) -> PixelMatrix {
        let result = PixelMatrix(width: width, height: height + other.height)
        fastCopySubrange(
            from: pixels,
            sourceRange: 0 ..< pixels.count,
            to: result.pixels,
            destinationStart: 0
        )
        fastCopySubrange(
            from: other.pixels,
            sourceRange: 0 ..< other.pixels.count,
            to: result.pixels,
            destinationStart: pixels.count
        )
        return result
    }

    /// Efficiently copies a range of typed memory from one buffer to another.
    /// Uses memmove for optimal performance with arbitrary data types.
    /// - Parameters:
    ///   - source: The source buffer to copy from.
    ///   - sourceRange: The range within the source buffer to copy.
    ///   - destination: The destination buffer to copy to.
    ///   - destinationStart: The starting index in the destination buffer.
    @inline(__always)
    func fastCopySubrange<T>(
        from source: UnsafeMutableBufferPointer<T>,
        sourceRange: Range<Int>,
        to destination: UnsafeMutableBufferPointer<T>,
        destinationStart: Int
    ) {
        precondition(sourceRange.upperBound <= source.count, "Source range out of bounds")
        precondition(destinationStart + sourceRange.count <= destination.count, "Destination would overflow")

        let byteCount = sourceRange.count * MemoryLayout<T>.stride

        memmove(
            destination.baseAddress!.advanced(by: destinationStart),
            source.baseAddress!.advanced(by: sourceRange.lowerBound),
            byteCount
        )
    }
}

/// Extension to PixelMatrix for PNG file I/O operations.
public extension PixelMatrix {
    /// Creates a PixelMatrix from a PNG file on disk.
    /// Reads the PNG, converts it to RGBA, and stores the pixel data in the matrix.
    /// - Parameter filePath: The file system path to the PNG file.
    /// - Returns: A new PixelMatrix with the PNG's pixel data, or nil if loading or conversion fails.
    static func fromPNG(filePath: String) -> PixelMatrix? {
        // Load PNG data from the specified file path
        let url = URL(fileURLWithPath: filePath)

        guard
            let data = try? Data(contentsOf: url, options: .mappedIfSafe),
            let provider = CGDataProvider(data: data as CFData),
            let cgImage = CGImage(pngDataProviderSource: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        else {
            print("Failed to load PNG from \(filePath)")
            return nil
        }

        // Extract image dimensions from the Core Graphics image
        let width = cgImage.width
        let height = cgImage.height

        // Ensure RGBA format (32 bits per pixel, 8 bits per component)
        let bitsPerComponent = 8
        let bytesPerRow = width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: CGBitmapInfo = [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)]

        // Create a Core Graphics context for pixel data extraction
        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            )
        else {
            print("Failed to create CGContext")
            return nil
        }

        // Render the PNG image into the context to obtain pixel data
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Access the raw pixel data from the Core Graphics context
        guard let pixelData = context.data else {
            print("Failed to access pixel data")
            return nil
        }

        // Create a new PixelMatrix instance to store the pixel data
        let pixmap = PixelMatrix(width: width, height: height)

        // Convert pixel data from RGBA to our internal ARGB format (0xAARRGGBB)
        let pixelBuffer = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)
        for y in 0 ..< height {
            for x in 0 ..< width {
                let offset = (y * width + x) * 4
                let r = Int32(pixelBuffer[offset])
                let g = Int32(pixelBuffer[offset + 1])
                let b = Int32(pixelBuffer[offset + 2])
                let a = Int32(pixelBuffer[offset + 3])
                // Store as ARGB (0xAARRGGBB)
                pixmap[x, y] = (a << 24) | (r << 16) | (g << 8) | b
            }
        }

        return pixmap
    }

    /// Copies a block of pixels from a pixel buffer into this matrix.
    /// Efficiently copies a contiguous run of pixels using memcpy.
    /// - Parameters:
    ///   - pixelLine: The source pixel buffer to copy from.
    ///   - start: The destination index (in the pixel matrix) where copying begins.
    ///   - bytes: The number of 32-bit pixels to copy.
    internal func copyPixels(from pixelLine: PixelBuffer, start: Int, bytes: Int) {
        let dest = pixels.baseAddress!.advanced(by: start)
        let bytes = bytes * MemoryLayout<Int32>.stride
        memcpy(dest, pixelLine, bytes)
    }

    /// Saves the pixel matrix as a PNG file to the specified file path.
    /// Uses the CGImage property to convert pixels and writes them to disk.
    /// - Parameter filePath: The destination file path (including filename and .png extension).
    /// - Returns: true if the save was successful, false otherwise.
    func saveToPNG(filePath: String) -> Bool {
        #if DEBUG
            print("[PixelMatrix] saveToPNG called with path: \(filePath)")
            print("[PixelMatrix] Pixel matrix dimensions: \(width)x\(height)")
            print("[PixelMatrix] Pixel count: \(pixels.count)")
        #endif

        guard let cgImage = image else {
            #if DEBUG
                print("[PixelMatrix] Failed to create CGImage for screenshot")
            #endif
            return false
        }

        #if DEBUG
            print("[PixelMatrix] CGImage created successfully: \(cgImage.width)x\(cgImage.height)")
        #endif

        let fileURL = URL(fileURLWithPath: filePath)
        #if DEBUG
            print("[PixelMatrix] File URL: \(fileURL)")
            print("[PixelMatrix] Parent directory exists: \(FileManager.default.fileExists(atPath: fileURL.deletingLastPathComponent().path))")
        #endif

        guard
            let destination = CGImageDestinationCreateWithURL(
                fileURL as CFURL,
                kUTTypePNG,
                1,
                nil
            )
        else {
            #if DEBUG
                print("[PixelMatrix] Failed to create image destination")
            #endif
            return false
        }

        #if DEBUG
            print("[PixelMatrix] Image destination created successfully")
        #endif

        CGImageDestinationAddImage(destination, cgImage, nil)

        #if DEBUG
            print("[PixelMatrix] Image added to destination, finalizing...")
        #endif

        guard CGImageDestinationFinalize(destination) else {
            #if DEBUG
                print("[PixelMatrix] Failed to finalize image destination")
            #endif
            return false
        }

        #if DEBUG
            print("[PixelMatrix] Screenshot saved successfully!")
        #endif

        return true
    }
}
