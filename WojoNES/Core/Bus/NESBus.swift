//
//  NESBus.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

class NESBus: Bus {
    // MARK: Properties

    /// System RAM mirrored every 0x800 bytes
    var ram: [UInt8] = Array(repeating: 0, count: 0x2000)
    // Connected components; set via `connect` methods
    var ppu: PPU!
    var apu: APU!
    var cpu: CPU!
    var cartridge: Cartridge!

    // Controller serial state and latched controller values
    var controllerState = [UInt8](repeating: 0, count: 2)
    var controller = [UInt8](repeating: 0, count: 2)
    /// When true, writes to $4016 latch the controller state
    var strobing: Bool = false
    /// The open bus retains the last value read from the bus
    var openBus: UInt8 = 0

    /// Address used for OAM DMA transfers (high byte)
    var dmaOamAddr: Int = 0

    // MARK: Computed Properties

    var cycle: Int {
        cpu.cycle
    }

    // MARK: Lifecycle

    init() {}

    // MARK: Functions

    /// Read a byte from the bus at the given address.
    /// Returns the value from the appropriate device or the open bus if unmapped.
    func read(address: Int) -> UInt8 {
        var data = openBus
        switch address {
            case 0 ..< 0x2000:
                // CPU sees mirrored internal RAM
                data = ram[address & 0x07FF]

            case 0x2000 ..< 0x4000:
                // PPU registers are mirrored in this range
                data = ppu.read(address)

            case 0x4015:
                // APU status register (readable when CPU enabled)
                if cpu.enabled {
                    data = apu.status
                }

            case 0x4016,
                 0x4017:
                // Controller ports: return serialised controller bits
                if cpu.enabled {
                    let port = address & 1
                    data &= ~0x1F
                    data |= (controllerState[port] & 1) | 0x40
                    // Shift to next button for subsequent reads
                    controllerState[port] = (controllerState[port] >> 1) | 0x80
                }

            case 0x4000 ... 0x40FF:
                // Other components or open bus reads
                data = openBus

            case 0x6000 ..< 0x8000 where cartridge?.mapper.prgRAMenabled == true:
                // Cartridge battery-backed PRG RAM
                data = cartridge.wRam[address & 0x1FFF]

            case 0x8000...:
                // PRG ROM,  mapped PRG memory
                data = cartridge.prgMemory[address & 0x7FFF]

            default:
                data = openBus
        }
        // Updatee open bus with the value last seen on the bus
        openBus = data
        return data
    }

    /// Write a byte to the bus at the given address.
    /// Routes the value to RAM, PPU, APU, cartridge or triggers DMA as needed.
    func write(address: Int, data: UInt8) {
        // Value put on the bus becomes the open bus value
        openBus = data
        switch address {
            case 0 ..< 0x2000:
                // Writes go to mirrored internal RAM
                ram[address & 0x7FF] = data

            case 0x2000 ..< 0x4000:
                // PPU register writes
                ppu.write(address: address, value: data)

            case 0x4014:
                // OAM DMA - set high byte and inform CPU to perform DMA
                dmaOamAddr = Int(data) << 8
                cpu.setDmaOam(enable: true)

            case 0x4016:
                // Controller strobe handling: when strobing transitions
                // from high to low, latch controller values into serial state
                if strobing, (data & 1) == 0 {
                    controllerState[0] = controller[0]
                    controllerState[1] = controller[1]
                }
                strobing = data == 1

            case 0x4000 ... 0x4020:
                // APU and IO register writes
                apu.write(address: address, value: data)

            case 0x6000 ..< 0x8000 where cartridge?.mapper.prgRAMenabled == true:
                // Writes to cartridge PRG RAM
                cartridge?.wRam[address & 0x1FFF] = data

            default:
                // Unmapped writes are ignored for now; log for debugging
                print("write not supported")
        }
    }

    /// Convenience connect methods to attach components to the bus
    func connect(_ ppu: PPU) {
        self.ppu = ppu
    }

    func connect(_ apu: APU) {
        self.apu = apu
    }

    func connect(_ cartridge: any Cartridge) {
        self.cartridge = cartridge
    }

    func connect(_ cpu: CPU) {
        self.cpu = cpu
    }

    /// Swap PPU name table banks via bus.
    func swapNameTable(bankIdx: Int, swapBankIdx: Int) {
        ppu.swapNameTable(bankIdx: bankIdx, swapBankIdx: swapBankIdx)
    }

    /// Run the main frame loop until the PPU completes a frame.
    /// The CPU steps while the PPU renders the current frame.
    func step() {
        ppu.frameComplete = false
        while !ppu.frameComplete {
            cpu.step()
        }
        // print("frame complete")
    }

    func resetCycles() {
        cpu.resetCycles()
    }
}
