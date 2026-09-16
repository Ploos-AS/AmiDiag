/* AmiDiag M3.10b clean-room guarded CPU identification through 68020+. */
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

    move.l #illegal_vbr,VECTOR_ILLEGAL
    lea guard_record,%a0
    bsr serial_puts

    /* Stage 1: MOVEC VBR,D0. 68000 -> illegal, 68010+ -> present. */
    .word 0x4E7A,0x0801

vbr_present:
    lea probe_vbr_present,%a0
    bsr serial_puts

    /* Stage 2: CACR exists on 68020+. A 68010 implements MOVEC but not CACR.
     * Re-arm vector #4 before the raw MOVEC CACR,D0 capability probe.
     * Extension 0x0002 selects D0 and control register CACR.
     */
    move.l #illegal_cacr,VECTOR_ILLEGAL
    .word 0x4E7A,0x0002

cacr_present:
    lea probe_cacr_present,%a0
    bsr serial_puts
    lea cpu_68020plus,%a0
    bsr serial_puts
    lea id_68020plus,%a0
    bsr serial_puts
    lea baseline_later,%a0
    bsr serial_puts
    bra halt

illegal_vbr:
    /* M3.10b qualifies the 68000 negative path with the normal 68000
     * illegal-instruction frame: SR word followed by PC longword.
     */
    move.l #vbr_unsupported,2(%sp)
    rte

vbr_unsupported:
    lea probe_vbr_illegal,%a0
    bsr serial_puts
    lea cpu_68000,%a0
    bsr serial_puts
    lea id_68000,%a0
    bsr serial_puts
    lea baseline_68000,%a0
    bsr serial_puts
    bra halt

illegal_cacr:
    /* For the 68010 negative path, redirect the stacked normal exception PC
     * to the known continuation. No later-family instruction is executed
     * until the VBR capability has already established 68010+.
     */
    move.l #cacr_unsupported,2(%sp)
    rte

cacr_unsupported:
    lea probe_cacr_illegal,%a0
    bsr serial_puts
    lea cpu_68010,%a0
    bsr serial_puts
    lea id_68010,%a0
    bsr serial_puts
    lea baseline_later,%a0
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
banner: .asciz "AMIDIAG proto=1 milestone=M3.10b cpu=68k\r\n"
boot_record: .asciz "BOOT phase=reset status=PASS\r\n"
guard_record: .asciz "TEST id=CPU.ID.GUARD status=PASS exception=ILLEGAL recovery=armed\r\n"
probe_vbr_illegal: .asciz "PROBE class=CPU feature=VBR instruction=MOVEC result=ILLEGAL\r\n"
probe_vbr_present: .asciz "PROBE class=CPU feature=VBR instruction=MOVEC result=PRESENT\r\n"
probe_cacr_illegal: .asciz "PROBE class=CPU feature=CACR instruction=MOVEC result=ILLEGAL\r\n"
probe_cacr_present: .asciz "PROBE class=CPU feature=CACR instruction=MOVEC result=PRESENT\r\n"
cpu_68000: .asciz "CPU family=68000 confidence=architectural\r\n"
cpu_68010: .asciz "CPU family=68010 confidence=architectural\r\n"
cpu_68020plus: .asciz "CPU family=68020+ confidence=architectural\r\n"
id_68000: .asciz "TEST id=CPU.ID status=PASS family=68000\r\n"
id_68010: .asciz "TEST id=CPU.ID status=PASS family=68010\r\n"
id_68020plus: .asciz "TEST id=CPU.ID status=PASS family=68020+\r\n"
baseline_68000: .asciz "TEST id=CPU.BASELINE status=PASS cpu=68000 probe=family-identification\r\n"
baseline_later: .asciz "TEST id=CPU.BASELINE status=PASS cpu=68k probe=family-identification\r\n"
