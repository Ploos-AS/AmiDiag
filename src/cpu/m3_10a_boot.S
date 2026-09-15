/* AmiDiag M3.10a clean-room guarded 68000 vs 68010+ identification. */
    .equ CIAA_PRA, 0x00BFE001
    .equ SERDATR,  0x00DFF018
    .equ SERDAT,   0x00DFF030
    .equ SERPER,   0x00DFF032
    .equ SERDATR_TBE, 13
    .equ SERPER_9600_PAL, 369
    .equ STACK_TOP, 0x0007FFFC
    .equ VECTOR_ILLEGAL, 0x00000010

    .section .vectors,"a"
    .long STACK_TOP
    .long _rom_reset

    .section .text.boot,"ax"
    .globl _rom_reset
_rom_reset:
    bclr #0,CIAA_PRA
    move.l #STACK_TOP,%sp
    move.w #SERPER_9600_PAL,SERPER
    lea banner,%a0
    bsr serial_puts
    lea boot_record,%a0
    bsr serial_puts

    /* Vector #4 is writable after ROM overlay release. */
    move.l #illegal_handler,VECTOR_ILLEGAL
    lea guard_record,%a0
    bsr serial_puts

    /* MOVEC VBR,D0, encoded explicitly to keep the source 68000-safe.
     * 4E7A 0801 = MOVEC VBR,D0 on CPUs that implement MOVEC/VBR.
     * 68000 must take illegal-instruction vector #4.
     */
    .word 0x4E7A,0x0801

movec_supported:
    lea probe_present,%a0
    bsr serial_puts
    lea cpu_68010plus,%a0
    bsr serial_puts
    lea id_68010plus,%a0
    bsr serial_puts
    lea baseline_later,%a0
    bsr serial_puts
    bra halt

illegal_handler:
    /* Normal 68000 illegal-instruction frame is SR+PC. Redirect stacked PC
     * to the known unsupported continuation and RTE, preserving SSP/SR.
     */
    move.l #movec_unsupported,2(%sp)
    rte

movec_unsupported:
    lea probe_illegal,%a0
    bsr serial_puts
    lea cpu_68000,%a0
    bsr serial_puts
    lea id_68000,%a0
    bsr serial_puts
    lea baseline_68000,%a0
    bsr serial_puts
    bra halt

serial_puts:
    move.b (%a0)+,%d0
    beq serial_done
    bsr serial_putc
    bra serial_puts
serial_done:
    rts
serial_putc:
1:  btst #SERDATR_TBE,SERDATR
    beq 1b
    andi.w #0x00FF,%d0
    ori.w #0x0100,%d0
    move.w %d0,SERDAT
    rts
halt:
    stop #0x2700
    bra halt

    .section .rodata,"a"
banner: .asciz "AMIDIAG proto=1 milestone=M3.10a cpu=68k\r\n"
boot_record: .asciz "BOOT phase=reset status=PASS\r\n"
guard_record: .asciz "TEST id=CPU.ID.GUARD status=PASS exception=ILLEGAL recovery=armed\r\n"
probe_illegal: .asciz "PROBE class=CPU feature=VBR instruction=MOVEC result=ILLEGAL\r\n"
cpu_68000: .asciz "CPU family=68000 confidence=architectural\r\n"
id_68000: .asciz "TEST id=CPU.ID status=PASS family=68000\r\n"
baseline_68000: .asciz "TEST id=CPU.BASELINE status=PASS cpu=68000 probe=family-identification\r\n"
probe_present: .asciz "PROBE class=CPU feature=VBR instruction=MOVEC result=PRESENT\r\n"
cpu_68010plus: .asciz "CPU family=68010+ confidence=architectural\r\n"
id_68010plus: .asciz "TEST id=CPU.ID status=PASS family=68010+\r\n"
baseline_later: .asciz "TEST id=CPU.BASELINE status=PASS cpu=68k probe=family-identification\r\n"
