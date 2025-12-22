//
//  NESPPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

class NESPPU: PPU {
    // MARK: Properties

    var bus: Bus!

    var preventVBL: Bool = false

    var frameBuffer: [UInt32] = []

    var x: Int = 0
    var y: Int = -1 // set to -1 to force pre-render tile fetch - see frameStep()

    var currentRenderingVramRegister: VramRegister = .init()
    var nextRenderingVramRegister: VramRegister = .init()
    var oam: [UInt8] = .init(repeating: 0, count: 256)

    var paletteIndices: [Int] = .init(repeating: 0, count: 32)
    var palette: [Int32] = .init(repeating: 0, count: 64)

    var scanline: Int?

    var cycle: Int?

    var controlRegister: ControlRegister = .init()

    var mask: MaskRegister = .init()

    var statusRegister: PPUStatusRegister = .init()

    var openBus: UInt8 = 0

    var screen: PixelMatrix = .init(width: 256, height: 240)

    var frameScroll: Point = .init(x: 0, y: 0)

    var maxX: Int = 256

    var maxY: Int = 260

    var frameComplete: Bool = false

    var oddFrame: Bool = false

    // MARK: Lifecycle

    init(nesModel: NESModel) {
        maxX = nesModel.ppuMaxX
        maxY = nesModel.ppuMaxY

        for i in 0 ..< 32 {
            paletteIndices[i] = 0
        }

        for i in 0 ..< 64 {
            palette[i] = 0
        }

        loadPalette() // Placeholder palette
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

    func read(_ address: UInt16) -> UInt8 {
        0
    }

    func write(address: UInt16, value: UInt8) {}

    func readNextTile() {}

    func drawTileLine(y: Int, x: Int) {}

    func readSpriteScanline() {}

    func readSpriteLines() {}

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
            case (0 ..< screen.height, let x) where x < screen.width && (x & 7) == 0:
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
            case (0 ..< screen.height, 256):
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
            case (0 ..< screen.height, 320 ..< 336):
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
            case (0 ..< screen.height, _):
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
            case (screen.height, _):
                y += 1
                x = -1

            // Vertical blank flag assertion (y == screen.height + 1, x == 0): Apply any
            // pending scroll updates and raise the vertical blank status flag to signal
            // the start of the vertical blank period to the CPU.
            case (screen.height + 1, 0):
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
            case (screen.height + 1, 2):
                // TODO: Add NMI triggering
                y = maxY + 1
                x = -1

            // Vertical blank phase continuation (y == screen.height + 1, x == -1).
            case (screen.height + 1, -1):
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

    func loadPalette() {}

    func renderScanline() {}

    func fetchBackgrounds() {}

    func fetchSprites() {}
}
