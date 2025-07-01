//
//  NESCPU.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 27/06/2025.
//

// MARK: - NESCPU

public final class NESCPU {
    // MARK: Properties

    /// Formerly known as A.
    var accumulator: UInt8 = 0 {
        didSet {
            setZeroNegativeFlags()
        }
    }

    /// Formerly known as X.
    var xRegister: UInt8 = 0 {
        didSet {
            setZeroNegativeFlags()
        }
    }

    /// Formerly known as Y.
    var yRegister: UInt8 = 0 {
        didSet {
            setZeroNegativeFlags()
        }
    }

    /// Used for unofficial opcodes.
    var resultRegister: UInt8 = 0 {
        didSet {
            setZeroNegativeFlags()
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

    /// needed for tests, will be removed later
    var temporaryMemory: [UInt8] = Array(repeating: 0, count: 0x10000)

    // MARK: Lifecycle

    init() {
        operations = NESCPU.setupOperations()
    }

    // MARK: Functions

    func setZeroNegativeFlags() {}

    func read(_ address: Int) -> UInt8 {
        temporaryMemory[address]
    }
}

extension NESCPU {
    func step() {
        let opcode = read(programCounter)
        programCounter += 1
        let operation = operations[Int(opcode)]
        switch operation.addressingMode {
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

        switch operation.instruction {
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
}
