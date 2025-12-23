//
//  NESBus.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 05/07/2025.
//

class NESBus: Bus {
    // MARK: Properties

    var ram: [UInt8] = Array(repeating: 0, count: 0x2000)
    var ppu: PPU!
    var apu: APU!
    var cpu: CPU!
    var cartridge: Cartridge!

    var controllerState = [UInt8](repeating: 0, count: 2)
    var controller = [UInt8](repeating: 0, count: 2)
    var strobing: Bool = false
    var openBus: UInt8 = 0

    var dmaOamAddr: Int = 0

    // MARK: Lifecycle

    init() {}

    // MARK: Functions

    func read(address: Int) -> UInt8 {
        var data = openBus
        switch address {
            case 0 ..< 0x2000:
                data = ram[address & 0x07FF]

            case 0x2000 ..< 0x4000:
                data = ppu.read(address)

            case 0x4015:
                if cpu.enabled {
                    data = apu.status
                }

            case 0x4016,
                 0x4017:
                if cpu.enabled {
                    let port = address & 1
                    data &= ~0x1F
                    data |= (controllerState[port] & 1) | 0x40
                    controllerState[port] = (controllerState[port] >> 1) | 0x80
                }

            case 0x4000 ... 0x40FF:
                data = openBus

            case 0x6000 ..< 0x8000 where cartridge?.mapper.prgRAMenabled == true:
                data = cartridge.wRam[address & 0x1FFF]

            case 0x8000...:
                data = cartridge.prgMemory[address & 0x7FFF]

            default:
                data = openBus
        }
        openBus = data
        return data
    }

    func write(address: Int, data: UInt8) {
        openBus = data
        switch address {
            case 0 ..< 0x2000:
                ram[address & 0x7FF] = data

            case 0x2000 ..< 0x4000:
                ppu.write(address: address, value: data)

            case 0x4014:
                dmaOamAddr = Int(data) << 8
                cpu.setDmaOam(enable: true)

            case 0x4016:
                if strobing, (data & 1) == 0 {
                    controllerState[0] = controller[0]
                    controllerState[1] = controller[1]
                }
                strobing = data == 1

            case 0x4000 ... 0x4020:
                apu.write(address: address, value: data)

            case 0x6000 ..< 0x8000 where cartridge?.mapper.prgRAMenabled == true:
                cartridge?.wRam[address & 0x1FFF] = data

            default:
                print("write not supported")
        }
    }

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

    func swapNameTable(bankIdx: Int, swapBankIdx: Int) {
        ppu.swapNameTable(bankIdx: bankIdx, swapBankIdx: swapBankIdx)
    }

    func frameLoop() {
        ppu.frameComplete = false
        while !ppu.frameComplete {
            cpu.step()
        }
    }
}
