//
//  NESPPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

import Foundation

class NESPPU: PPU {
    // MARK: Nested Types

    enum MemoryRegion {
        static let chrRomEnd = 0x2000
        static let nameTableEnd = 0x3F00
        static let addressMask = 0x3FFF
        static let nameTableMask = 0x0FFF
    }

    // MARK: Properties

    // MARK: - Bus & Configuration

    var bus: Bus!
    var cartridge: Cartridge
    var model: NESModel

    // MARK: - Timing & Synchronisation

    var x: Int = 0
    var y: Int = -1 // Set to -1 to force pre-render tile fetch - see frameStep()
    var scanline: Int?
    var cycle: Int?
    var preventVBL: Bool = false
    var oddFrame: Bool = false
    var frameComplete: Bool = false

    // MARK: - Rendering State

    var frame: PixelMatrix = .init(width: 256, height: 240)
    var frameScroll: Point = .init(x: 0, y: 0)
    var frameBuffer: [UInt32] = []
    var maxX: Int = 256
    var maxY: Int = 260

    // MARK: - VRAM & Memory Access

    var currentRenderingVramRegister: VramRegister = .init()
    var nextRenderingVramRegister: VramRegister = .init()
    /// PPU's internal 2KB VRAM for nametables
    var nameTables: BankMemory = .init()
    var lastBusData: UInt8 = 0 // Also called open bus
    var openBus: UInt8 = 0

    // MARK: - Sprite & Object Attribute Memory (OAM)

    var oam: [UInt8] = .init(repeating: 0, count: 256)
    var oamAddr: UInt8 = 0
    var oamDmaAddr: UInt8 = 0
    var spriteLines: [[PixelRow]]?
    var spriteScanline: [PixelRow?] = .init(repeating: nil, count: 256)

    // MARK: - Tile Rendering Pipeline

    var tileLine = PixelBuffer.with(pixels: 8)
    var prevTile: PixelRow = .init()
    var actTile: PixelRow = .init()
    var nextTile: PixelRow = .init()
    var bufferTile: PixelRow = .init()

    // MARK: - Palette & Colour Data

    var paletteIndices: [Int] = .init(repeating: 0, count: 32)
    var palette: [Int32] = .init(repeating: 0, count: 64)

    // MARK: - PPU Registers

    var controlRegister: ControlRegister = .init()
    var mask: MaskRegister = .init()
    var statusRegister: PPUStatusRegister = .init()

    // MARK: Computed Properties

    var vramData: UInt8 {
        get {
            let addr = currentRenderingVramRegister.address & MemoryRegion.addressMask
            defer {
                currentRenderingVramRegister.address += controlRegister.increment
            }

            // Palette memory (0x3F00-0x3FFF)
            if addr >= MemoryRegion.nameTableEnd {
                return readPaletteMemory(at: addr)
            }

            // CHR-ROM or Nametables (0x0000-0x3EFF) - uses buffered read
            let bufferedValue = controlRegister.dataLatch
            loadNextDataLatch(at: addr)
            return bufferedValue
        }

        set {
            let addr = currentRenderingVramRegister.address & MemoryRegion.addressMask
            defer {
                currentRenderingVramRegister.address += controlRegister.increment
            }

            switch addr {
                case 0 ..< MemoryRegion.chrRomEnd:
                    // CHR-RAM (only writable if CHR-RAM is enabled)
                    writeChrRam(at: addr, value: newValue)

                case MemoryRegion.chrRomEnd ..< MemoryRegion.nameTableEnd:
                    // Nametables and Attribute Tables
                    nameTables[addr & MemoryRegion.nameTableMask] = newValue

                default:
                    // Palette RAM (0x3F00-0x3FFF)
                    writePaletteMemory(at: addr, value: newValue)
            }
        }
    }

    // MARK: Lifecycle

    init(cartridge: Cartridge) {
        self.cartridge = cartridge
        model = cartridge.getModel()

        maxX = model.ppuMaxX
        maxY = model.ppuMaxY

        for i in 0 ..< 32 {
            paletteIndices[i] = 0
        }

        for i in 0 ..< 64 {
            palette[i] = 0
        }

        loadPalette() // Placeholder palette
        spriteLines = [[PixelRow]](repeating: [], count: frame.height)

        // Initialize nametables (2KB VRAM with 1KB banks)
        nameTables.banks.append(Array(repeating: 0, count: 0x1000))
        nameTables.swapBanks.append(Array(repeating: 0, count: 0x1000))
        nameTables.bankSizeValue = 0x400
    }

    // MARK: Static Functions

    static func flipByte(_ b: Int) -> Int {
        var byte = UInt8(truncatingIfNeeded: b)
        byte = (byte & 0xF0) >> 4 | (byte & 0x0F) << 4
        byte = (byte & 0xCC) >> 2 | (byte & 0x33) << 2
        byte = (byte & 0xAA) >> 1 | (byte & 0x55) << 1
        return Int(byte)
    }

    // MARK: Functions

    func connect(_ bus: Bus) {
        self.bus = bus
    }

    func frameReady() -> Bool {
        false
    }

    func step() {
        frameStep()
    }

    /// Reads a value from the specified PPU register address.
    /// Implements the PPU read protocol with proper timing and side-effects for each register.
    /// - Parameter address: The PPU register address (0x2000-0x2007).
    /// - Returns: The data read from the register, or the last value on the bus if unavailable.
    func read(_ address: UInt16) -> UInt8 {
        var data = lastBusData
        switch address {
            case 2: // PPU Status Register (0x2002)
                // Combine the status flags (bits 7-5) with the last bus data
                data |= UInt8(statusRegister.value & 0xE0)
                // Clear the vertical blank flag upon read (standard PPU behaviour)
                statusRegister.verticalBlank = false
                // Reset the VRAM address latch toggle to the low byte
                nextRenderingVramRegister.latched = false
                // Prevent spurious VBL flag set during specific cycle
                preventVBL = y == frame.height + 1 && x >= 0

            case 4: // OAM Data Register (0x2004)
                // During rendering, return sprite data from the secondary OAM (hardware behaviour)
                if mask.renderSprites, y >= 0, y < frame.height {
                    data = 0xFF
                    // Only return sprite data during sprite evaluation period (cycles 256-319)
                    if x > 256, x < 320 {
                        let line = spriteLines?[y] ?? []
                        let xPos = x - 256
                        let idx = xPos / 8
                        if idx < line.count {
                            let sprite = line[idx]
                            // Return sequential bytes of the sprite entry being evaluated
                            switch xPos % 8 {
                                case 0: data = UInt8(sprite.y)
                                case 1: data = UInt8(sprite.id)
                                case 2: data = UInt8(sprite.attribute)
                                case 3: data = UInt8(sprite.x)
                                default: break
                            }
                        }
                    }
                } else {
                    // During blanking, return the value at the current OAM address pointer
                    data = oam[Int(oamAddr)]
                }
                // Mask out the unused bits of the sprite attribute (bits 5 and 6)
                if oamAddr % 4 == 2 {
                    data &= 0xE3
                }

            case 7: // PPU Data Register (0x2007)
                // Fetch the value at the current VRAM address (increments address automatically)
                data = vramData

            default:
                break
        }
        // Update the bus latch to maintain open bus behaviour for future reads
        lastBusData = data
        return lastBusData
    }

    /// Writes a value to the specified PPU register address.
    /// Implements the PPU write protocol with proper side-effects for each register.
    /// - Parameters:
    ///   - address: The PPU register address (0x2000-0x2007).
    ///   - value: The data to write to the register.
    func write(address: UInt16, value: UInt8) {
        lastBusData = value
        switch address & 0x7 {
            case 0: // PPU Control Register (0x2000)
                let prevNMI = controlRegister.enableNMI
                controlRegister.value = Int(value)
                // Update the nametable select bits in the temporary VRAM register
                nextRenderingVramRegister.nameTableX = controlRegister.nameTableX
                nextRenderingVramRegister.nameTableY = controlRegister.nameTableY
                // Note: NMI edge detection would occur here; CPU would respond during next cycle
                let suppressNMI = y == -1 && x == 0

            case 1: // PPU Mask Register (0x2001)
                // Update rendering flags: background/sprite visibility and colour emphasis
                mask.value = Int(value)

            case 3: // OAM Address Register (0x2003)
                // Set the pointer into the Object Attribute Memory for subsequent reads/writes
                oamAddr = value

            case 4: // OAM Data Register (0x2004)
                // Write to OAM at the current address pointer and auto-increment
                oam[Int(oamAddr)] = value
                oamAddr &+= 1

            case 5: // Scroll Register (0x2005) - Write Twice
                // First write sets horizontal scroll, second write sets vertical scroll
                nextRenderingVramRegister.setScroll(Int(value))

            case 6: // VRAM Address Register (0x2006) - Write Twice
                // First write sets the high byte, second write sets the low byte of the VRAM address
                nextRenderingVramRegister.setAddress(Int(value))
                // Once both bytes are written, latch the address into the working register
                if !nextRenderingVramRegister.latched {
                    currentRenderingVramRegister = nextRenderingVramRegister
                }

            case 7: // PPU Data Register (0x2007)
                // Write to VRAM at the current address and auto-increment
                vramData = value

            default:
                break
        }
    }

    /// Fetches and buffers the next background tile from the nametable.
    /// Rotates tiles through the pipeline: buffer -> prev -> actual -> next.
    /// This method is called every 8 pixels to supply the rendering pipeline with fresh tile data
    /// including the colour information and pattern data (bit planes).
    func readNextTile() { // 2.4%
        // Rotate tiles through the pipeline for smooth 8-pixel boundary rendering
        bufferTile = prevTile
        prevTile = actTile
        actTile = nextTile
        // Fetch the tile ID and attribute (colour palette) from the nametable
        nextTile = getBgTile(idx: currentRenderingVramRegister.nameTableY << 1 | currentRenderingVramRegister.nameTableX, y: currentRenderingVramRegister.coarseY, x: currentRenderingVramRegister.coarseX) // 0.8%
        // Load both bit planes (LSB and MSB) of the tile pattern from CHR memory
        let address = (nextTile.id << 4) | currentRenderingVramRegister.fineY
        nextTile.lsb = Int(cartridge.chrMemory[address])
        nextTile.msb = Int(cartridge.chrMemory[address | 8])
        // Increment the horizontal scroll position by one tile (8 pixels)
        currentRenderingVramRegister.scrollX += 8
    }

    /// Retrieves background tile information from the nametable.
    /// Reads the tile ID and attribute (colour palette index) from the current nametable position.
    /// - Parameters:
    ///   - idx: Nametable index (0-3 representing the four 32x30 nametables).
    ///   - y: Coarse Y coordinate (0-29).
    ///   - x: Coarse X coordinate (0-31).
    /// - Returns: A PixelRow containing the tile ID and colour attribute.
    func getBgTile(idx: Int, y: Int, x: Int) -> PixelRow {
        let table = nameTables.banks[idx]
        // Read tile ID from nametable and combine with pattern table base address
        bufferTile.id = (controlRegister.patternBg << 8) | Int(table[y << 5 | x])
        // Read the attribute byte from the attribute table (one entry per 32×32 pixel block)
        bufferTile.attribute = Int(table[(y >> 2) << 3 | (x >> 2)])
        // Extract the 2-bit palette index for this tile's quadrant within the attribute byte
        bufferTile.attribute >>= ((y & 2) << 1) | (x & 2)
        bufferTile.attribute &= 3
        return bufferTile
    }

    /// Retrieves the final 32-bit colour value for a pixel based on palette and pattern indices.
    /// Applies the mask register's colour emphasis settings to the base palette colour.
    /// - Parameters:
    ///   - palette: The palette index (0-3) for selecting one of four colour palettes.
    ///   - pattern: The pixel colour index within the palette (0-3).
    /// - Returns: A 32-bit ARGB colour value.
    func getPixel(palette: Int, pattern: Int) -> Int32 {
        // Index into the palette indices array using palette (0-3) and pattern (0-3)
        // Then apply the mask register's colour emphasis bits and fetch the final colour
        self.palette[paletteIndices[palette << 2 | pattern] & mask.mask]
    }

    /// Renders an 8-pixel tile line to the frame buffer.
    /// Composites background and sprite layers, handling sprite priorities and sprite zero collision detection.
    /// This method is called every 8 pixels during the visible scanline to progressively render the frame.
    /// - Parameters:
    ///   - y: The Y coordinate (scanline) to render (0-239).
    ///   - x: The X coordinate (pixel column) to render (0-248).
    func drawTileLine(y: Int, x: Int) {
        // Determine if we should render background and sprite layers (accounting for left-edge masking)
        let renderBackground = mask.renderBackground && (x > 0 || mask.renderBackgroundLeft)
        let renderSprites = mask.renderSprites && (x > 0 || mask.renderSpritesLeft)

        // Optimisation: if neither layer is active, render background colour (palette index 0)
        if !renderBackground, !renderSprites {
            for i in 0 ..< 8 {
                tileLine[i] = getPixel(palette: 0, pattern: 0)
            }
            frame.copyPixels(from: tileLine, start: y * frame.width + x, bytes: 8)
            return
        }

        // Process each of the 8 pixels in this tile line
        for i in 0 ..< 8 {
            let screenX = x + i

            // Fetch the background pixel value from the tile pipeline
            var bgPattern = 0
            var bgPalette = 0
            if renderBackground {
                // Index into the current and previous tile based on fine X offset (0-7)
                let idx = 15 - (i + nextRenderingVramRegister.fineX)
                let patternTile = idx < 8 ? actTile : prevTile
                bgPattern = patternTile.getPatternPixel(index: idx)
                // Only apply palette index if the pixel is non-transparent
                if bgPattern > 0 {
                    bgPalette = Int(patternTile.attribute)
                }
            }

            // Initialise final colours; sprites may override these values
            var finalPattern = bgPattern
            var finalPalette = bgPalette

            // Composite the sprite layer if a sprite occupies this pixel
            if renderSprites, let sprite = spriteScanline[screenX] {
                // Detect collision between sprite zero and a non-transparent background pixel
                if sprite.isSpriteZero && bgPattern > 0 && screenX < frame.width - 1 {
                    statusRegister.spriteZeroHit = true
                }

                // Determine if the sprite should be rendered based on its priority flag
                // Priority 0 = sprite in front; Priority 1 = sprite behind background
                if sprite.priority || bgPattern == 0 {
                    let spritePattern = sprite.getPatternPixel(index: 7 - (screenX - Int(sprite.x)))
                    if spritePattern != 0 {
                        finalPattern = spritePattern
                        finalPalette = sprite.paletteIndex
                    }
                }
            }

            // Look up the final colour using the palette and pattern indices
            tileLine[i] = getPixel(palette: finalPalette, pattern: finalPattern)
        }

        // Write the 8-pixel line to the frame buffer at the correct position
        frame.copyPixels(from: tileLine, start: y * frame.width + x, bytes: 8)
    }

    /// Evaluates sprites that intersect with the current scanline and constructs the sprite scanline buffer.
    /// The NES hardware limitation allows only 8 sprites per scanline; additional sprites are ignored
    /// and the sprite overflow flag is set if exceeded.
    /// Each sprite's pattern data is fetched and the sprite is positioned in the scanline buffer.
    func readSpriteScanline() {
        // Clear the sprite scanline buffer for fresh evaluation (reuse array to avoid allocation)
        for i in 0 ..< spriteScanline.count {
            spriteScanline[i] = nil
        }
        // Reset OAM address (hardware behaviour during sprite evaluation)
        oamAddr = 0

        // Retrieve the list of sprites that overlap this scanline
        guard let line = spriteLines?[y] else { return }

        // Set overflow flag if more than 8 sprites exist on this scanline (NES hardware limitation)
        if line.count > 8 {
            statusRegister.spriteOverflow = true
        }

        // Process each sprite on this scanline, limiting to 8 due to hardware rendering constraint
        for baseSprite in line.prefix(8) { // NES hardware only renders first 8 sprites per line
            var sprite = baseSprite

            // Calculate the sprite row index relative to the current scanline
            var row = y - sprite.y

            // Apply vertical flip if the flip bit is set in the attribute byte
            if (sprite.attribute & 0x20) != 0 {
                row = controlRegister.spriteSize - 1 - row
            }

            // Load pattern data for this sprite row from CHR memory
            fetchSpritePattern(sprite: &sprite, row: row)

            // Apply horizontal flip to both bit planes if the flip bit is set
            if (sprite.attribute & 0x10) != 0 {
                sprite.lsb = Self.flipByte(sprite.lsb)
                sprite.msb = Self.flipByte(sprite.msb)
            }

            // Place sprite pixels into the scanline buffer, skipping transparent pixels and respecting overlap priority
            let spriteEndX = min(Int(sprite.x) + 8, spriteScanline.count)
            for x in Int(sprite.x) ..< spriteEndX {
                // Only place sprite if it's within screen bounds and no higher-priority sprite is already here
                if x >= 0, spriteScanline[x] == nil {
                    let pixelIndex = 7 - (x - Int(sprite.x))
                    // Only store non-transparent pixels (index 0 is transparent)
                    if sprite.getPatternPixel(index: pixelIndex) != 0 {
                        spriteScanline[x] = sprite
                    }
                }
            }
        }
    }

    /// Reads all sprites from the Object Attribute Memory (OAM) and organises them into scanline lists.
    /// Each sprite is added to the scanline entries it occupies based on the sprite height setting
    /// (either 8 or 16 pixels). This allows fast lookup of sprites during scanline rendering.
    func readSpriteLines() {
        // Initialise sprite lines array or reuse existing one (avoid repeated allocation)
        if spriteLines == nil {
            spriteLines = [[PixelRow]](repeating: [], count: frame.height)
        } else {
            // Clear existing sprite lists whilst retaining allocated capacity
            for i in 0 ..< spriteLines!.count {
                spriteLines![i].removeAll(keepingCapacity: true)
            }
        }

        // Iterate through OAM in groups of 4 bytes (one sprite entry per iteration)
        for i in stride(from: 0, to: oam.count, by: 4) {
            var sprite = PixelRow()

            // Mark the first sprite in OAM as sprite zero (required for collision detection)
            if i == 0 {
                sprite.isSpriteZero = true
            }

            // Extract sprite attributes from OAM bytes: Y position, tile ID, attributes, X position
            sprite.y = Int(oam[i])
            sprite.id = Int(oam[i + 1])
            sprite.attribute = Int(oam[i + 2])
            sprite.x = Int(oam[i + 3])

            // Add this sprite to each scanline it occupies (based on current sprite size setting)
            let endY = min(sprite.y + controlRegister.spriteSize, spriteLines!.count)

            for row in sprite.y ..< endY {
                // Only add sprites that intersect with valid scanlines
                if row >= 0 {
                    spriteLines![row].append(sprite)
                }
            }
        }
    }

    /// Exchanges a nametable bank with a swap bank, facilitating multi-board mapper configurations.
    /// Used by mappers that support nametable bank switching via hardware signals.
    /// - Parameters:
    ///   - bankIdx: The primary bank index to swap out.
    ///   - swapBankIdx: The swap bank index to take its place.
    func swapNameTable(bankIdx: Int, swapBankIdx: Int) {
        nameTables.swap(bankIdx: bankIdx, swapBankIdx: swapBankIdx)
    }

    // Advances the PPU state by one pixel clock cycle. This method manages the entire
    // PPU scanline and frame rendering state machine, including sprite evaluation,
    // background tile fetching, and vertical/horizontal blanking phases.
    //
    // The PPU cycles through 341 pixels per scanline (0-340) and up to 261 scanlines
    // per frame (-1 to 260 for NTSC). This method handles all transitions and operations
    // that occur during rendering, pre-render, and vertical blank periods.
    //
    // References: https://www.nesdev.org/wiki/PPU_rendering
    func frameStep() {
        let renderEnabled = mask.renderBackground || mask.renderSprites

        switch (y, x) {
            // Most frequent case: Background tile fetching during visible scanlines.
            // Every 8 pixels, fetch the next tile and shift the tile data into the
            // rendering pipeline. At x=0, clear A12 toggle detection to prepare for
            // the new scanline. After processing, advance x by 8 and render the tile line.
            case (0 ..< frame.height, let x) where x < frame.width && (x & 7) == 0:
                if renderEnabled {
                    if x == 0 {
                        currentRenderingVramRegister.a12Toggled = false
                    }
                    readNextTile()
                }
                drawTileLine(y: y, x: x)
                self.x += 8

            // Rendering: End of scanline (x == 256)
            // End of visible scanline (x == 256): perform Y-scroll increment and sprite fetch.
            // Increment the fine Y position (vertical scroll) and handle nametable transitions.
            // If a nametable vertical boundary is crossed, toggle the vertical nametable select bit.
            case (0 ..< frame.height, 256):
                if renderEnabled {
                    // Increment vertical scroll (Y position) by stepping through fine and coarse Y values.
                    // When fine Y reaches zero and coarse Y is at boundary (30), wrap to nametable below.
                    currentRenderingVramRegister.scrollY += 1
                    if currentRenderingVramRegister.coarseY == 0, currentRenderingVramRegister.fineY == 0 {
                        currentRenderingVramRegister.nameTableY ^= 1
                    } else if currentRenderingVramRegister.coarseY == 30 {
                        currentRenderingVramRegister.scrollY += 16
                    }
                    // Synchronise horizontal scroll from the temporary register at scanline end.
                    currentRenderingVramRegister.scrollX = nextRenderingVramRegister.scrollX
                    // Begin sprite evaluation for the next scanline.
                    readSpriteScanline()
                }
                x = 320

            // Pre-fetch tiles for the next scanline: fetch name table and attribute bytes.
            case (0 ..< frame.height, 320 ..< 336):
                if renderEnabled {
                    // Fetch tile data for the first two tiles of the next scanline,
                    // preparing the rendering pipeline for smooth edge rendering.
                    readNextTile()
                }
                x += 8

            // Pre-render scanline (y == -1): perform background tile pre-fetch at scanline end.
            // This ensures tile data is ready when rendering begins on the next frame.
            case (-1, 320 ..< 336):
                if renderEnabled {
                    readNextTile()
                }
                x += 8

            // Pre-render scanline: Load vertical scroll and perform sprite prefetch (x == 256).
            // Restore the current VRAM address from the temporary register to synchronise
            // vertical and horizontal scroll values at the start of the next frame.
            case (-1, 256):
                if renderEnabled {
                    // Restore the working VRAM register from the latched temporary register.
                    // This is the step that applies scroll changes from $2005 writes.
                    currentRenderingVramRegister = nextRenderingVramRegister
                    readSpriteLines()
                }
                x = 320

            // Standard scanline advance: move to the next line when end of line is reached.
            case (0 ..< frame.height, _):
                y += 1
                x = 0

            // Pre-render scanline setup (y == -1, x == 0): Clear VBL status flags and prepare
            // for the next frame. Reset sprite zero hit, sprite overflow, and vertical blank flags.
            case (-1, 0):
                // Clear collision and blanking flags before rendering begins.
                statusRegister.spriteZeroHit = false
                statusRegister.spriteOverflow = false
                statusRegister.verticalBlank = false
                preventVBL = false
                openBus = 0
                x = 256

            // Cycle skip point during pre-render: prepare for end-of-line fetch (y == -1, x == 336).
            case (-1, 336):
                x += 1

            // End of pre-render scanline: transition to the next frame. This marks the
            // completion of one full PPU frame (including vertical blank period).
            case (-1, 337):
                y = 0
                x = 0

            // Vertical blank period: the PPU is not rendering. This typically occurs after
            // the visible scanlines. The CPU can safely write to PPU registers during this time.
            case (frame.height, _):
                y += 1
                x = -1

            // Vertical blank flag assertion (y == screen.height + 1, x == 0): Apply any
            // pending scroll updates and raise the vertical blank status flag to signal
            // the start of the vertical blank period to the CPU.
            case (frame.height + 1, 0):
                // Capture the scroll position from the latched temporary register into the
                // working frame scroll buffer. This value is used by the renderer.
                frameScroll = Point(x: nextRenderingVramRegister.scrollX, y: nextRenderingVramRegister.scrollY)
                // Set the vertical blank flag unless suppressed by a $2002 read.
                if !preventVBL {
                    statusRegister.verticalBlank = true
                }
                x = 2

            // NMI trigger point (y == screen.height + 1, x == 2): Would normally trigger
            // the non-maskable interrupt if enabled. This cycle is where the 6502 responds.
            case (frame.height + 1, 2):
                // TODO: Add NMI triggering
                y = maxY + 1
                x = -1

            // Vertical blank phase continuation (y == screen.height + 1, x == -1).
            case (frame.height + 1, -1):
                x += 1

            // Frame completion (y > maxY): One full frame cycle (rendering + vertical blank)
            // has finished. Toggle the odd frame flag for NTSC cycle-skipping and reset
            // the scanline counter for the next frame.
            case let (y, _) where y > maxY:
                // Mark the frame as complete so the emulator can present the screen buffer.
                frameComplete = true
                // TODO: add cycles handling
                // Toggle the odd frame flag: on odd frames, one cycle is skipped for NTSC timing.
                oddFrame.toggle()
                // Reset scanline counter and pixel counter for the next frame.
                self.y = -1
                x = 0

            // Failsafe: Unexpected scanline/cycle state (indicates a bug in the state machine).
            default:
                assertionFailure("Unexpected (y: \(y), x: \(x)) state")
                y += 1
                x = 0
        }
    }

    /// Fetches sprite pattern data for a specific sprite row during scanline rendering.
    /// Handles both 8×8 and 8×16 sprite sizes, applying the appropriate pattern table address.
    /// For 8×16 sprites, the sprite tile index determines which pattern table is used.
    /// - Parameters:
    ///   - sprite: The sprite to fetch pattern data for (modified in-place with LSB and MSB).
    ///   - row: The row within the sprite (0-7 for 8×8, 0-15 for 8×16).
    func fetchSpritePattern(sprite: inout PixelRow, row: Int) {
        // Determine which pattern table to use (controlled by PPU control register for 8×8 sprites)
        var tableNo = controlRegister.patternSprite
        var tileId = sprite.id
        var tileRow = row

        // Handle 8×16 sprites: sprite ID selects the pattern table and split tile selection
        if controlRegister.spriteSize == 16 {
            // For 8×16 sprites, the sprite ID register determines the pattern table directly
            tableNo = sprite.id
            tileId = sprite.id
            // If the row is in the bottom half, fetch the next tile
            if tileRow > 7 {
                tileId += 1
                tileRow &= 7
            }
        }

        // Combine pattern table index with tile ID to form the complete tile index
        tileId |= tableNo << 8
        // Calculate CHR memory address: (tile ID << 4) + row within tile
        let address = (tileId << 4) | tileRow

        // Load both bit planes of the pattern (LSB and MSB are 8 bytes apart)
        sprite.lsb = Int(cartridge.chrMemory[address])
        sprite.msb = Int(cartridge.chrMemory[address | 8])
    }

    /// Loads the system palette from a PNG image resource.
    /// The palette contains all 64 valid NES colours, indexed by the PPU's colour lookup table.
    func loadPalette() {
        // Load the system palette from a PNG resource containing all 64 valid NES colours
        let paletteMap = PixelMatrix.fromPNG(filePath: Bundle.main.path(forResource: "PAL", ofType: "png")!)!
        // Copy each 32-bit ARGB colour value into the palette array for fast lookup
        for i in 0 ..< 64 {
            palette[i] = paletteMap.pixels[i]
        }
    }

    // MARK: - VRAM Helper Methods

    /// Calculates the palette index for memory access, accounting for palette RAM mirroring.
    /// Addresses divisible by 4 (e.g., 0x3F00, 0x3F04, 0x3F08, 0x3F0C) all mirror to the
    /// universal background colour at index 0, creating the special mirroring behaviour.
    /// - Parameter address: The VRAM address within the palette RAM region.
    /// - Returns: The effective palette index (0-31) accounting for mirroring.
    @inline(__always)
    private func getPaletteIndex(for address: Int) -> Int {
        // Palette mirroring: addresses divisible by 4 (0x3F00, 0x3F04, 0x3F08, 0x3F0C, etc.)
        // all mirror to the universal background colour at index 0. Other addresses map normally.
        // If address is divisible by 4, mask with 0x0F to get indices 0, 4, 8, 12, etc.
        // Otherwise, mask with 0x1F to get all other valid palette indices.
        (address & 0x03) == 0 ? (address & 0x0F) : (address & 0x1F)
    }

    /// Reads a value from the PPU's palette RAM.
    /// Implements the open bus behaviour where the upper 2 bits reflect the last data on the bus,
    /// whilst the lower 6 bits contain the actual palette index.
    /// - Parameter address: The VRAM address within the palette RAM region.
    /// - Returns: The colour palette index with open bus behaviour applied.
    @inline(__always)
    private func readPaletteMemory(at address: Int) -> UInt8 {
        let index = getPaletteIndex(for: address)
        // Combine palette index with open bus behaviour: lower 6 bits from palette RAM,
        // upper 2 bits from the last data value on the bus (read from previous operations).
        let value = paletteIndices[index] | (Int(lastBusData) & 0xC0)
        return UInt8(value)
    }

    /// Writes a value to the PPU's palette RAM.
    /// Updates the palette index at the calculated address, accounting for mirroring behaviour.
    /// - Parameters:
    ///   - address: The VRAM address within the palette RAM region.
    ///   - value: The colour palette index to write.
    @inline(__always)
    private func writePaletteMemory(at address: Int, value: UInt8) {
        // Calculate the palette index accounting for the special mirroring behaviour
        let index = getPaletteIndex(for: address)
        // Store the new palette colour index
        paletteIndices[index] = Int(value)
    }

    /// Loads the next PPU VRAM data value into the internal data latch.
    /// Implements the PPU's buffered read behaviour for nametable and CHR-ROM data.
    /// This latch is returned on the next PPU data read, whilst a new value is loaded here.
    /// - Parameter address: The VRAM address to load data from.
    @inline(__always)
    private func loadNextDataLatch(at address: Int) {
        // Load the next VRAM data value into the internal data latch
        if address >= MemoryRegion.chrRomEnd {
            // Read from nametable and attribute RAM (0x2000-0x3EFF)
            controlRegister.dataLatch = nameTables[address & MemoryRegion.nameTableMask]
        } else {
            // Read from CHR-ROM or CHR-RAM (0x0000-0x1FFF)
            controlRegister.dataLatch = cartridge.chrMemory[address]
        }
    }

    /// Writes to the PPU's CHR RAM if the cartridge mapper enables it.
    /// Most NES cartridges use CHR-ROM which is read-only; only select mappers support writable CHR-RAM.
    /// - Parameters:
    ///   - address: The VRAM address within the CHR region (0x0000-0x1FFF).
    ///   - value: The byte to write to CHR memory.
    @inline(__always)
    private func writeChrRam(at address: Int, value: UInt8) {
        // Only allow writes if the cartridge mapper explicitly enables CHR-RAM writes
        guard cartridge.mapper.chrRAMenabled == true else { return }
        // Write the value to CHR memory (most cartridges have read-only CHR-ROM instead)
        cartridge.chrMemory[address] = value
    }
}
