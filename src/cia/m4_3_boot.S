/* AmiDiag M4.3: clean-room CIA ICR diagnostics, 68000 baseline. */
    .equ CIAA_PRA,  0x00BFE001
    .equ CIAA_TALO, 0x00BFE401
    .equ CIAA_TAHI, 0x00BFE501
    .equ CIAA_ICR,  0x00BFED01
    .equ CIAA_CRA,  0x00BFEE01
    .equ CIAB_TALO, 0x00BFD400
    .equ CIAB_TAHI, 0x00BFD500
    .equ CIAB_ICR,  0x00BFDD00
    .equ CIAB_CRA,  0x00BFDE00
    .equ SERDATR,   0x00DFF018
    .equ SERDAT,    0x00DFF030
    .equ SERPER,    0x00DFF032
    .equ STACK_TOP, 0x0007FFFC

    .section .vectors,"a"
    .long STACK_TOP
    .long _rom_reset

    .section .text.boot,"ax"
    .globl _rom_reset
_rom_reset:
    bclr #0,CIAA_PRA
    move.l #STACK_TOP,%sp
    move.w #369,SERPER
    clr.l %d7
    lea banner,%a0
    bsr serial_puts
    lea boot_record,%a0
    bsr serial_puts

    lea CIAA_TALO,%a0
    lea CIAA_CRA,%a1
    lea CIAA_ICR,%a2
    lea ciaa_pass,%a3
    lea ciaa_fail,%a4
    bsr test_icr

    lea CIAB_TALO,%a0
    lea CIAB_CRA,%a1
    lea CIAB_ICR,%a2
    lea ciab_pass,%a3
    lea ciab_fail,%a4
    bsr test_icr

    tst.l %d7
    bne summary_bad
    lea summary_pass,%a0
    bsr serial_puts
    bra halt
summary_bad:
    lea summary_fail,%a0
    bsr serial_puts
    bra halt

/* A0=TALO, A1=CRA, A2=ICR, A3=PASS record, A4=FAIL record.
 * ICR bit 0 = Timer A source; bit 7 on writes selects set vs clear.
 * Reading ICR acknowledges pending sources.  CPU/Paula interrupt routing is
 * deliberately not enabled in M4.3; we prove the CIA-local request only. */
test_icr:
    move.b (%a1),%d4             /* saved CRA */
    move.b (%a0),%d5             /* current counter low snapshot */
    move.b 0x100(%a0),%d6        /* current counter high snapshot */

    move.b #0x01,(%a2)           /* clear Timer A mask */
    move.b (%a2),%d0             /* acknowledge stale pending sources */

    move.b %d4,%d0
    andi.b #0xDE,%d0             /* stop; force Phi2 source */
    move.b %d0,(%a1)
    move.b #0x20,(%a0)
    move.b #0x00,0x100(%a0)      /* short 0x0020 latch */

    move.b #0x81,(%a2)           /* set Timer A interrupt mask only */
    move.b %d0,%d1
    andi.b #0xF6,%d1             /* continuous mode, keep unrelated bits */
    ori.b #0x11,%d1              /* START + LOAD */
    move.b %d1,(%a1)

    move.w #0x7fff,%d3
1:
    move.b (%a2),%d0
    btst #0,%d0
    bne 2f
    dbra %d3,1b
    addq.l #1,%d7
    bsr cleanup_icr
    move.l %a4,%a0
    bsr serial_puts
    rts
2:
    /* Enabled Timer A request should carry the ICR master/request flag. */
    btst #7,%d0
    bne 3f
    addq.l #1,%d7
    bsr cleanup_icr
    move.l %a4,%a0
    bsr serial_puts
    rts
3:
    bsr cleanup_icr
    move.l %a3,%a0
    bsr serial_puts
    rts

cleanup_icr:
    move.b #0x01,(%a2)           /* always disable Timer A mask */
    move.b %d4,%d0
    andi.b #0xFE,%d0
    move.b %d0,(%a1)             /* stop before restoring counter */
    move.b %d5,(%a0)
    move.b %d6,0x100(%a0)
    move.b (%a2),%d0             /* acknowledge any final pending source */
    move.b %d4,(%a1)             /* restore control byte */
    rts

serial_puts:
    move.b (%a0)+,%d0
    beq 5f
4:  btst #13,SERDATR
    beq 4b
    andi.w #0x00ff,%d0
    ori.w #0x0100,%d0
    move.w %d0,SERDAT
    bra serial_puts
5:  rts
halt:
    stop #0x2700
    bra halt

    .section .rodata,"a"
banner: .asciz "AMIDIAG proto=1 milestone=M4.3 cpu=68000\r\n"
boot_record: .asciz "BOOT phase=reset status=PASS\r\n"
ciaa_pass: .asciz "CIAA.ICR status=PASS source=TIMERA pending=observed mask=set-clear cleanup=PASS\r\n"
ciaa_fail: .asciz "CIAA.ICR status=FAIL source=TIMERA pending=missing-or-inconsistent mask=set-clear cleanup=attempted\r\n"
ciab_pass: .asciz "CIAB.ICR status=PASS source=TIMERA pending=observed mask=set-clear cleanup=PASS\r\n"
ciab_fail: .asciz "CIAB.ICR status=FAIL source=TIMERA pending=missing-or-inconsistent mask=set-clear cleanup=attempted\r\n"
summary_pass: .asciz "TEST id=CIA.ICR status=PASS devices=2 cleanup=2\r\n"
summary_fail: .asciz "TEST id=CIA.ICR status=FAIL\r\n"
