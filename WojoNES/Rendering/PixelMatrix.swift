import CoreGraphics
import Foundation
import Metal
import MetalKit

// MARK: - PixelMatrix

/// A 2D pixel buffer for rendering and image manipulation.
///
/// `PixelMatrix` manages a contiguous buffer of 32-bit ARGB pixel data in row-major order (pixels[y * width + x]).
/// It provides convenient access via subscript, concatenation operations, and conversion to `CGImage` or Metal textures.
///
/// Pixel format: 0xAARRGGBB (32-bit ARGB, where A is the alpha channel).
///
/// Example:
/// ```swift
/// let matrix = PixelMatrix(width: 256, height: 240)
/// matrix[0, 0] = 0xFF0000FF  // Set top-left pixel to red
/// if let image = matrix.image {
///     // Use CGImage for display
/// }
/// ```
public class PixelMatrix {
    // MARK: Properties

    /// Raw pixel data buffer (row-major: pixels[y * width + x]).
    /// Format: each element is a 32-bit ARGB integer (0xAARRGGBB).
    public var pixels: UnsafeMutableBufferPointer<Int32>

    /// Width of the pixel matrix (number of columns).
    public var width: Int

    /// Height of the pixel matrix (number of rows).
    public var height: Int

    // MARK: Computed Properties

    /// Converts the pixel matrix to a `CGImage` for rendering or display.
    ///
    /// Converts internal ARGB (0xAARRGGBB) format to RGBA for Core Graphics.
    /// The resulting image uses an RGB color space with premultiplied alpha.
    ///
    /// - Returns: A `CGImage` suitable for display in UIImageView, NSImageView, or Core Graphics contexts.
    ///           Returns nil if image creation fails (e.g., invalid dimensions or allocation errors).
    ///
    /// Performance note: This method allocates temporary RGBA buffer and creates a new CGImage.
    /// Cache the result if used multiple times.
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

            // Create CGImage
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
    ///
    /// Creates a Metal device, allocates an RGBA8Unorm texture, and uploads pixel data from the matrix
    /// (converting from internal ARGB to RGBA format). The texture is configured for both shader read and write.
    ///
    /// - Returns: An `MTLTexture` with RGBA8Unorm format suitable for Metal rendering pipelines.
    ///           Returns nil if Metal device or texture creation fails.
    ///
    /// Performance notes:
    /// - Creates a new Metal device each time; consider caching the device in production code.
    /// - Allocates temporary RGBA buffer during conversion; cache the result if possible.
    /// - Suitable for real-time rendering but not for frequent repeated conversions.
    ///
    /// Example:
    /// ```swift
    /// if let texture = matrix.metalTexture {
    ///     // Pass texture to Metal render pipeline
    /// }
    /// ```
    public var metalTexture: MTLTexture? {
        // Create Metal device
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Failed to create Metal device")
            return nil
        }

        // Create texture descriptor
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite]

        // Create Metal texture
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            print("Failed to create Metal texture")
            return nil
        }

        // Convert pixels to RGBA buffer
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

        // Copy data to texture
        texture.replace(
            region: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0,
            withBytes: &rgbaData,
            bytesPerRow: bytesPerRow
        )

        return texture
    }

    // MARK: Lifecycle

    /// Initializes a new pixel matrix with the given dimensions.
    ///
    /// All pixels are initialized to red (0xFF0000FF in ARGB format).
    ///
    /// - Parameters:
    ///   - width: Number of columns
    ///   - height: Number of rows
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
        pixels = UnsafeMutableBufferPointer<Int32>.allocate(capacity: width * height)
        pixels.initialize(repeating: 0xFF0000)
    }

    // MARK: Functions

    /// Accesses or sets a pixel at (x, y) coordinates.
    ///
    /// - Parameters:
    ///   - x: Horizontal coordinate (0 to width-1)
    ///   - y: Vertical coordinate (0 to height-1)
    /// - Returns: 32-bit ARGB pixel value (0xAARRGGBB)
    ///
    /// Example: `let color = matrix[10, 20]`
    public subscript(x: Int, y: Int) -> Int32 {
        get {
            pixels[y * width + x]
        }
        set {
            pixels[y * width + x] = newValue
        }
    }

    /// Concatenates two matrices horizontally (side-by-side).
    ///
    /// Creates a new matrix with width = self.width + other.width and height = self.height.
    /// Both matrices must have the same height. Left matrix is copied first, then right matrix.
    ///
    /// - Parameter other: The matrix to append on the right
    /// - Returns: A new matrix with both matrices combined horizontally
    ///
    /// Example: `let wide = narrow1.horzCat(narrow2)  // 256x240 + 256x240 = 512x240`
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

    /// Concatenates two matrices vertically (stacked).
    ///
    /// Creates a new matrix with width = self.width and height = self.height + other.height.
    /// Both matrices must have the same width. Top matrix is copied first, then bottom matrix.
    /// Uses `fastCopySubrange` for efficient memory copying.
    ///
    /// - Parameter other: The matrix to append below
    /// - Returns: A new matrix with both matrices combined vertically
    ///
    /// Example: `let tall = short1.vertCat(short2)  // 256x120 + 256x120 = 256x240`
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

    /// Efficiently copies a contiguous range of elements between buffers using `memmove`.
    ///
    /// This inline helper method bypasses Swift array bounds checking for performance.
    /// Used internally by `vertCat` to copy pixel rows.
    ///
    /// - Parameters:
    ///   - source: Source buffer (generic type `T`)
    ///   - sourceRange: Range [lowerBound, upperBound) in the source buffer
    ///   - destination: Destination buffer (same type `T`)
    ///   - destinationStart: Starting index in the destination buffer
    ///
    /// - Precondition: sourceRange must be within source bounds; destination must have space for the range
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

// MARK: - PNG File Loading

/// Extension to read PNG files into a PixelMatrix
public extension PixelMatrix {
    /// Creates a PixelMatrix from a PNG file on disk.
    ///
    /// Loads PNG image data using Core Graphics and converts to the internal ARGB format (0xAARRGGBB).
    /// The PNG is decoded into RGBA format first, then rearranged to match the matrix's ARGB layout.
    ///
    /// - Parameter filePath: Full file path to the PNG image
    /// - Returns: A new PixelMatrix with pixel data loaded from the PNG file, or nil if loading fails
    ///
    /// Failure reasons include:
    /// - File not found or unreadable
    /// - Invalid PNG format
    /// - Image dimensions exceed memory capacity
    /// - Core Graphics context creation fails
    ///
    /// Example:
    /// ```swift
    /// if let matrix = PixelMatrix.fromPNG(filePath: "/path/to/image.png") {
    ///     print("Loaded \(matrix.width)x\(matrix.height) image")
    /// }
    /// ```
    ///
    /// Performance note: This method allocates a temporary CGContext and buffer for format conversion.
    /// For large images or frequent loads, consider caching results.
    static func fromPNG(filePath: String) -> PixelMatrix? {
        // Load PNG data
        let url = URL(fileURLWithPath: filePath)

        guard
            let data = try? Data(contentsOf: url, options: .mappedIfSafe),
            let provider = CGDataProvider(data: data as CFData),
            let cgImage = CGImage(pngDataProviderSource: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        else {
            print("Failed to load PNG from \(filePath)")
            return nil
        }

        // Get image dimensions
        let width = cgImage.width
        let height = cgImage.height

        // Ensure RGBA format (32 bits per pixel)
        let bitsPerComponent = 8
        let bytesPerRow = width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: CGBitmapInfo = [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)]

        // Create a context to draw the image
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

        // Draw the image into the context
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Access raw pixel data
        guard let pixelData = context.data else {
            print("Failed to access pixel data")
            return nil
        }

        // Create PixelMatrix instance
        let pixmap = PixelMatrix(width: width, height: height)

        // Convert pixel data to ARGB (0xAARRGGBB)
        // Input data is RGBA in big-endian format
        let pixelBuffer = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)
        for y in 0 ..< height {
            for x in 0 ..< width {
                let offset = (y * width + x) * 4
                let r = Int32(pixelBuffer[offset])
                let g = Int32(pixelBuffer[offset + 1])
                let b = Int32(pixelBuffer[offset + 2])
                let a = Int32(pixelBuffer[offset + 3])
                pixmap[x, y] = (a << 24) | (r << 16) | (g << 8) | b
            }
        }

        return pixmap
    }
}
