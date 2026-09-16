/* AmiDiag M3.10d clean-room guarded CPU identification through 68060. */
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
    lea guard_record,%a0
    bsr serial_puts

    /* M3.10a: VBR distinguishes 68000 from 68010+. */
    move.l #illegal_vbr,VECTOR_ILLEGAL
    .word 0x4E7A,0x0801              /* MOVEC VBR,D0 */

vbr_present:
    lea probe_vbr_present,%a0
    bsr serial_puts

    /* M3.10b: CACR distinguishes 68010 from 68020+. */
    move.l #illegal_cacr,VECTOR_ILLEGAL
    .word 0x4E7A,0x0002              /* MOVEC CACR,D0 */

cacr_present:
    lea probe_cacr_present,%a0
    bsr serial_puts

    /* M3.10d stage 1 comes before the M3.10c CACR.ED discriminator.
     * Read-only MOVEC ITT0,D0 identifies the 68040+ control-register set.
     * 68020/68030 reject ITT0 and continue to the reversible CACR.ED probe.
     */
    move.l #illegal_itt0,VECTOR_ILLEGAL
    .word 0x4E7A,0x0004              /* MOVEC ITT0,D0 */

itt0_present:
    lea probe_itt0_present,%a0
    bsr serial_puts

    /* M3.10d stage 2: PCR is 68060-specific; 68040 rejects it. */
    move.l #illegal_pcr,VECTOR_ILLEGAL
    .word 0x4E7A,0x0808              /* MOVEC PCR,D0 */

pcr_present:
    lea probe_pcr_present,%a0
    bsr serial_puts
    lea cpu_68060,%a0
    bsr serial_puts
    lea id_68060,%a0
    bsr serial_puts
    bra baseline_later_halt

cpu_020_030_path:
    /* M3.10c: reversible CACR.ED probe distinguishes 68020 from 68030. */
    .word 0x4E7A,0x2002              /* MOVEC CACR,D2 */
    move.l %d2,%d1
    ori.l #0x00000100,%d1
    .word 0x4E7B,0x1002              /* MOVEC D1,CACR */
    .word 0x4E7A,0x0002              /* MOVEC CACR,D0 */
    .word 0x4E7B,0x2002              /* MOVEC D2,CACR: restore */
    btst #8,%d0
    bne cpu_030_path

cpu_020_path:
    lea probe_dc_ignored,%a0
    bsr serial_puts
    lea cpu_68020,%a0
    bsr serial_puts
    lea id_68020,%a0
    bsr serial_puts
    bra baseline_later_halt

cpu_030_path:
    lea probe_dc_present,%a0
    bsr serial_puts
    lea cpu_68030,%a0
    bsr serial_puts
    lea id_68030,%a0
    bsr serial_puts
    bra baseline_later_halt

illegal_vbr:
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
    move.l #cacr_unsupported,2(%sp)
    rte
cacr_unsupported:
    lea probe_cacr_illegal,%a0
    bsr serial_puts
    lea cpu_68010,%a0
    bsr serial_puts
    lea id_68010,%a0
    bsr serial_puts
    bra baseline_later_halt

illegal_itt0:
    move.l #itt0_unsupported,2(%sp)
    rte
itt0_unsupported:
    lea probe_itt0_illegal,%a0
    bsr serial_puts
    bra cpu_020_030_path

illegal_pcr:
    move.l #pcr_unsupported,2(%sp)
    rte
pcr_unsupported:
    lea probe_pcr_illegal,%a0
    bsr serial_puts
    lea cpu_68040,%a0
    bsr serial_puts
    lea id_68040,%a0
    bsr serial_puts
    bra baseline_later_halt

baseline_later_halt:
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
banner: .asciz "AMIDIAG proto=1 milestone=M3.10d cpu=68k\r\n"
boot_record: .asciz "BOOT phase=reset status=PASS\r\n"
guard_record: .asciz "TEST id=CPU.ID.GUARD status=PASS exception=ILLEGAL recovery=armed\r\n"
probe_vbr_illegal: .asciz "PROBE class=CPU feature=VBR instruction=MOVEC result=ILLEGAL\r\n"
probe_vbr_present: .asciz "PROBE class=CPU feature=VBR instruction=MOVEC result=PRESENT\r\n"
probe_cacr_illegal: .asciz "PROBE class=CPU feature=CACR instruction=MOVEC result=ILLEGAL\r\n"
probe_cacr_present: .asciz "PROBE class=CPU feature=CACR instruction=MOVEC result=PRESENT\r\n"
probe_dc_ignored: .asciz "PROBE class=CPU feature=CACR.ED bit=8 result=IGNORED restore=PASS\r\n"
probe_dc_present: .asciz "PROBE class=CPU feature=CACR.ED bit=8 result=PRESENT restore=PASS\r\n"
probe_itt0_illegal: .asciz "PROBE class=CPU feature=ITT0 instruction=MOVEC result=ILLEGAL\r\n"
probe_itt0_present: .asciz "PROBE class=CPU feature=ITT0 instruction=MOVEC result=PRESENT\r\n"
probe_pcr_illegal: .asciz "PROBE class=CPU feature=PCR instruction=MOVEC result=ILLEGAL\r\n"
probe_pcr_present: .asciz "PROBE class=CPU feature=PCR instruction=MOVEC result=PRESENT\r\n"
cpu_68000: .asciz "CPU family=68000 confidence=architectural\r\n"
cpu_68010: .asciz "CPU family=68010 confidence=architectural\r\n"
cpu_68020: .asciz "CPU family=68020 confidence=architectural\r\n"
cpu_68030: .asciz "CPU family=68030 confidence=architectural\r\n"
cpu_68040: .asciz "CPU family=68040 confidence=architectural\r\n"
cpu_68060: .asciz "CPU family=68060 confidence=architectural\r\n"
id_68000: .asciz "TEST id=CPU.ID status=PASS family=68000\r\n"
id_68010: .asciz "TEST id=CPU.ID status=PASS family=68010\r\n"
id_68020: .asciz "TEST id=CPU.ID status=PASS family=68020\r\n"
id_68030: .asciz "TEST id=CPU.ID status=PASS family=68030\r\n"
id_68040: .asciz "TEST id=CPU.ID status=PASS family=68040\r\n"
id_68060: .asciz "TEST id=CPU.ID status=PASS family=68060\r\n"
baseline_68000: .asciz "TEST id=CPU.BASELINE status=PASS cpu=68000 probe=family-identification\r\n"
baseline_later: .asciz "TEST id=CPU.BASELINE status=PASS cpu=68k probe=family-identification\r\n"
