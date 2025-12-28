//
//  NESCPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 27/06/2025.
//

// MARK: - NESCPU

public final class NESCPU: CPU {
    // MARK: Static Properties

    static var fakeAccumulatorAddress = Int.max

    // MARK: Properties

    var bus: Bus!

    var currentOperation: Operation!

    var reset = false

    var nmi: Interrupt!
    var apuIrq: Interrupt!
    var dmcIrq: Interrupt!

    var cycle: Int = 0
    var additionalCycle: Int = 0
    var toggleIrqDisabled = false

    var statusRegister = StatusRegister()

    var dmaDmcEnabled = false
    var dmaOamEnabled = false

    var irqDisabled: Bool = false
    var lastIrqDisabled: Bool = false

    var enabled: Bool = true

    var interrupts: [Interrupt] = []

    /// Formerly known as A.
    var accumulator: UInt8 = 0 {
        didSet {
            setZeroNegativeFlags(accumulator)
        }
    }

    /// Formerly known as X.
    var xRegister: UInt8 = 0 {
        didSet {
            setZeroNegativeFlags(xRegister)
        }
    }

    /// Formerly known as Y.
    var yRegister: UInt8 = 0 {
        didSet {
            setZeroNegativeFlags(yRegister)
        }
    }

    /// Used for unofficial opcodes.
    var resultRegister: UInt8 = 0 {
        didSet {
            setZeroNegativeFlags(resultRegister)
        }
    }

    /// Represents the Stack Pointer (SP).
    var stackPointer: UInt8 = 0
    /// Represents the Program Counter (PC). Although 6502 uses a 16-bit PC.
    var programCounter: Int = 0

    /// holds the list of all operations executable by the processor (256)
    var operations: [Operation]

    /// Holds the temporary address during opcode execution
    var address: Int = 0

    // MARK: Lifecycle

    init() {
        operations = NESCPU.setupOperations()
    }

    // MARK: Functions

    func connect(_ bus: any Bus) {
        self.bus = bus
    }

    func setDmaOam(enable: Bool) {
        dmaOamEnabled = enable
    }

    func setZeroNegativeFlags(_ register: UInt8) {
        statusRegister.zero = register == 0
        statusRegister.negative = register & 0b1000_0000 != 0
    }

    func readWord(_ address: Int) -> Int {
        let lo = Int(read(address))
        let hi = Int(read(address + 1))
        return (hi << 8) | lo
    }

    func resetProgram() {
        reset = true
        cycle = 0
        step()
        write(0x4015, 0)
    }

    func read(_ address: Int) -> UInt8 {
        if address == NESCPU.fakeAccumulatorAddress {
            return accumulator
        }

        // Handle DMA transfers if pending
        if enabled, dmaOamEnabled || dmaDmcEnabled {
            incrementCycle()
            _ = bus.read(address: address)
            ppuStep()
            enabled = false
            dmaTransfer(address: address)
            enabled = true
        }

        // Every CPU memory read takes a cycle and steps the PPU
        incrementCycle()
        let result = bus.read(address: address)
        ppuStep()
        return result
    }

    func incrementCycle() {
        cycle += 1
        bus.apu.step()
    }

    func ppuStep() {
        bus.ppu.step()
        if toggleIrqDisabled {
            toggleIrqDisabled = false
            statusRegister.irqDisabled = !statusRegister.irqDisabled
        }
        irqDisabled = lastIrqDisabled
        lastIrqDisabled = statusRegister.irqDisabled
    }

    func write(_ address: Int, _ value: UInt8) {
        if address == NESCPU.fakeAccumulatorAddress {
            accumulator = value
        } else {
            incrementCycle()
            bus.write(address: address, data: value)
            ppuStep()
        }
    }

    func resetCycles() {
        additionalCycle += cycle & 1
        nmi.resetCycles()
        apuIrq.resetCycles()
        dmcIrq.resetCycles()
        cycle = 0
    }

    func popStack() -> Int {
        stackPointer = stackPointer &+ 1
        return Int(read(0x100 | Int(stackPointer)))
    }

    func pushStack(_ value: Int) {
        write(0x100 | Int(stackPointer), UInt8(value & 0xFF))
        stackPointer = stackPointer &- 1
    }

    func delayInterrupts() {
        nmi.delayActivating()
        apuIrq.delayActivating()
        dmcIrq.delayActivating()
    }

    /// Read page cross detection for accurate 6502 timing simulation
    /// Performs a dummy read when crossing page boundaries or for write operations
    /// - Parameters:
    ///   - address: The final effective address
    ///   - baseAddress: The base address before indexing
    @inline(__always)
    func readPageCross(address: Int, baseAddress: Int) {
        if currentOperation.hasReadCycle || (address & 0xFF00) != (baseAddress & 0xFF00) {
            _ = read(baseAddress & 0xFF00 | address & 0xFF)
        }
    }

    func branch(to address: Int) {
        _ = read(programCounter)
        delayInterrupts()
        readPageCross(address: address, baseAddress: programCounter)
        programCounter = address
    }

    func pushToStack(_ value: UInt8) {
        write(Int(stackPointer) | 0x100, value)
        if stackPointer == 0 {
            stackPointer = 0xFF
        } else {
            stackPointer -= 1
        }
    }

    func popFromStack() -> UInt8 {
        stackPointer = stackPointer &+ 1
        return read(0x100 | Int(stackPointer))
    }

    func cmp(_ reg: UInt8, _ mem: UInt8) {
        statusRegister.carry = reg >= mem
        resultRegister = UInt8(reg &- mem)
    }

    func addNmiInterrupt(_ interrupt: Interrupt) {
        nmi = interrupt
        nmi.setCPU(self)
        interrupts.append(nmi)
    }

    func addApuIrqInterrupt(_ interrupt: Interrupt) {
        apuIrq = interrupt
        apuIrq.setCPU(self)
        interrupts.append(apuIrq)
    }

    func addDmcIrqInterrupt(_ interrupt: Interrupt) {
        dmcIrq = interrupt
        dmcIrq.setCPU(self)
        interrupts.append(dmcIrq)
    }
}

extension NESCPU {
    func step() {
        let irqActive = reset || nmi.isActive || (!irqDisabled && interrupts.contains { $0.isActive })
        var opcode = read(programCounter)
        programCounter += 1
        if irqActive { opcode = 0 }
        statusRegister.break = !irqActive
        currentOperation = operations[Int(opcode)]
//        print(operation.name)
        switch currentOperation.addressingMode {
            case .implied:
                imp()
            case .immediate:
                imm()
            case .zeroPage:
                zpg()
            case .zeroPageX:
                zpx()
            case .zeroPageY:
                zpy()
            case .relative:
                rel()
            case .absolute:
                abs()
            case .absoluteX:
                abx()
            case .absoluteY:
                aby()
            case .indirect:
                idi()
            case .indirectX:
                idx()
            case .indirectY:
                idy()
        }

        switch currentOperation.instruction {
            case .adc:
                adc()
            case .sbc:
                sbc()
            case .inc:
                inc()
            case .dec:
                dec()
            case .inx:
                inx()
            case .iny:
                iny()
            case .dex:
                dex()
            case .dey:
                dey()
            case .and:
                and()
            case .ora:
                ora()
            case .eor:
                eor()
            case .asl:
                asl()
            case .lsr:
                lsr()
            case .rol:
                rol()
            case .ror:
                ror()
            case .lda:
                lda()
            case .ldx:
                ldx()
            case .ldy:
                ldy()
            case .sta:
                sta()
            case .stx:
                stx()
            case .sty:
                sty()
            case .tax:
                tax()
            case .tay:
                tay()
            case .tsx:
                tsx()
            case .txa:
                txa()
            case .tya:
                tya()
            case .txs:
                txs()
            case .jmp:
                jmp()
            case .jsr:
                jsr()
            case .rts:
                rts()
            case .rti:
                rti()
            case .bcc:
                bcc()
            case .bcs:
                bcs()
            case .beq:
                beq()
            case .bne:
                bne()
            case .bmi:
                bmi()
            case .bpl:
                bpl()
            case .bvc:
                bvc()
            case .bvs:
                bvs()
            case .stp:
                stp()
            case .brk:
                brk()
            case .pha:
                pha()
            case .php:
                php()
            case .pla:
                pla()
            case .plp:
                plp()
            case .clc:
                clc()
            case .cld:
                cld()
            case .cli:
                cli()
            case .clv:
                clv()
            case .sec:
                sec()
            case .sed:
                sed()
            case .sei:
                sei()
            case .cmp:
                cmp()
            case .cpx:
                cpx()
            case .cpy:
                cpy()
            case .bit:
                bit()
            case .dop:
                dop()
            case .top:
                top()
            case .slo:
                slo()
            case .rla:
                rla()
            case .sre:
                sre()
            case .rra:
                rra()
            case .sax:
                sax()
            case .ahx:
                ahx()
            case .shx:
                shx()
            case .shy:
                shy()
            case .tas:
                tas()
            case .las:
                las()
            case .lax:
                lax()
            case .dcp:
                dcp()
            case .isc:
                isc()
            case .alr:
                alr()
            case .anc:
                anc()
            case .arr:
                arr()
            case .axs:
                axs()
            case .xaa:
                xaa()
            case .nop:
                nop()
        }
    }

    func dmaTransfer(address: Int) {
        var oamValue = 0
        var oamCount = 0
        var dmcLatched = false
        var halt = false
        var dummyRead = false
        if dmaDmcEnabled {
            dmcLatched = true
            dummyRead = true
        }
        var isGetCycle = isReadingCycle()
        while dmaDmcEnabled || dmaOamEnabled {
            if isGetCycle {
                if dmaDmcEnabled, !halt, !dummyRead {
                    dmcLatched = false
                    dmaDmcEnabled = false
                } else if dmaOamEnabled {
                    oamValue = Int(read(bus.dmaOamAddr))
                    bus.dmaOamAddr += 1
                    oamCount += 1
                } else {
                    _ = read(address)
                }
            } else if dmaOamEnabled, (oamCount & 1) != 0 {
                write(0x2004, UInt8(oamValue))
                oamCount += 1
                if oamCount == 0x200 {
                    dmaOamEnabled = false
                }
            } else {
                _ = read(address)
            }
            if dmaDmcEnabled {
                if dmcLatched {
                    if halt { halt = false } else { dummyRead = false }
                } else {
                    dmcLatched = true
                    halt = true
                    dummyRead = true
                }
            }
            isGetCycle = !isGetCycle
        }
    }

    func isReadingCycle() -> Bool {
        ((cycle + additionalCycle) & 1) == 0
    }

    func handleIRQ() {}

    func handleNMI() {}
}
