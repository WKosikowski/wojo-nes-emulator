//
//  NESModel.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 21/12/2025.
//

/// Model describing timing and period constants for a target NES TV system.
///
/// References:
/// - NESDev APU frame counter: https://www.nesdev.org/wiki/APU_Frame_Counter
/// - NESDev DMC channel (periods): https://www.nesdev.org/wiki/APU_DMC
/// - NESDev noise channel: https://www.nesdev.org/wiki/APU_noise
/// - NESDev PPU timing and scanlines: https://www.nesdev.org/wiki/PPU
/// - NESDev NTSC video timing: https://www.nesdev.org/wiki/NTSC_video_timing
/// - NESDev PAL video timing: https://www.nesdev.org/wiki/PAL_video_timing
///
/// These tables and timings are taken from the NESDev documentation and
/// other community resources; consult the pages above for detailed notes and
/// the hardware behaviour that informed these constants.
struct NESModel {
    // MARK: Static Computed Properties

    /// NTSC configuration: CPU frequency, APU frame sequencing and noise/DMC periods.
    /// Values are chosen to match NES hardware timing for NTSC regions.
    static var ntsc: NESModel {
        let cpuFrequency = 1_789_773

        let qfc = cpuFrequency / 60 / 4
        var cycles = [qfc, qfc - 1, qfc + 1, qfc, 1, 1, qfc - 6, 1]
        for i in 1 ..< cycles.count {
            cycles[i] += cycles[i - 1]
        }
        let apuFrameCycles = cycles
        let dmcPeriods = [428, 380, 340, 320, 286, 254, 226, 214, 190, 160, 142, 128, 106, 84, 72, 54]
        let noisePeriods = [4, 8, 16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762, 1016, 2034, 4068]

        return NESModel(
            ppuClockRatio: 3.0,
            ppuMaxY: 260,
            cpuFrequency: cpuFrequency,
            apuFrameCycles: apuFrameCycles,
            dmcPeriods: dmcPeriods,
            noisePeriods: noisePeriods
        )
    }

    /// PAL configuration: CPU frequency, APU frame sequencing and noise/DMC periods.
    /// Values reflect the slightly slower PAL clocking and associated periods.
    static var pal: NESModel {
        let cpuFrequency = 1_662_607

        let qfcPal = cpuFrequency / 50 / 4
        var palCycles = [qfcPal, qfcPal + 1, qfcPal - 1, qfcPal, 1, 1, qfcPal - 2, 1]
        for i in 1 ..< palCycles.count {
            palCycles[i] += palCycles[i - 1]
        }
        let apuFrameCycles = palCycles
        let dmcPeriods = [398, 354, 316, 298, 276, 236, 210, 198, 176, 148, 132, 118, 98, 78, 66, 50]
        let noisePeriods = [4, 7, 14, 30, 60, 88, 118, 148, 188, 236, 354, 472, 708, 944, 1890, 3778]

        return NESModel(
            ppuClockRatio: 3.2,
            ppuMaxY: 310,
            cpuFrequency: cpuFrequency,
            apuFrameCycles: apuFrameCycles,
            dmcPeriods: dmcPeriods,
            noisePeriods: noisePeriods
        )
    }

    // MARK: Properties

    /// Ratio of PPU clock to CPU clock. This value is used to synchronise
    /// rendering cycles with CPU execution (three PPU cycles per CPU cycle
    /// for standard NES timing, adjusted for PAL where necessary).
    var ppuClockRatio: Float

    /// Maximum X coordinate for the PPU scanline (fixed for NES raster timings).
    let ppuMaxX: Int = 339

    /// Maximum Y coordinate (number of scanlines) for the PPU; varies by region.
    var ppuMaxY: Int

    /// CPU frequency in Hertz for the chosen TV system.
    var cpuFrequency: Int

    /// Cumulative cycle counts for APU frame sequence steps. These are used to
    /// advance APU state at the correct moments during the frame (frame timing
    /// sequence behaviour is hardware-specific).
    var apuFrameCycles: [Int]

    /// DMC sample periods (timer values) for the DMC channel; index maps to
    /// period values as defined by the hardware.
    var dmcPeriods: [Int]

    /// Noise channel period table; these values determine the noise channel's
    /// frequency behaviour for different settings.
    var noisePeriods: [Int]

    // MARK: Lifecycle

    /// Private initialiser: instances are created via the static `ntsc` and
    /// `pal` factories to ensure timing tables are set up correctly for each
    /// regional variant.
    private init(
        ppuClockRatio: Float,
        ppuMaxY: Int,
        cpuFrequency: Int,
        apuFrameCycles: [Int],
        dmcPeriods: [Int],
        noisePeriods: [Int]
    ) {
        self.ppuClockRatio = ppuClockRatio
        self.ppuMaxY = ppuMaxY
        self.cpuFrequency = cpuFrequency
        self.apuFrameCycles = apuFrameCycles
        self.dmcPeriods = dmcPeriods
        self.noisePeriods = noisePeriods
    }
}
