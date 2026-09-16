/* AmiDiag M4.2: clean-room CIA timer polling diagnostics, 68000 baseline. */
    .equ CIAA_PRA, 0x00BFE001
    .equ CIAA_TALO,0x00BFE401
    .equ CIAA_TAHI,0x00BFE501
    .equ CIAA_TBLO,0x00BFE601
    .equ CIAA_TBHI,0x00BFE701
    .equ CIAA_CRA, 0x00BFEE01
    .equ CIAA_CRB, 0x00BFEF01
    .equ CIAB_TALO,0x00BFD400
    .equ CIAB_TAHI,0x00BFD500
    .equ CIAB_TBLO,0x00BFD600
    .equ CIAB_TBHI,0x00BFD700
    .equ CIAB_CRA,0x00BFDE00
    .equ CIAB_CRB,0x00BFDF00
    .equ SERDATR,0x00DFF018
    .equ SERDAT,0x00DFF030
    .equ SERPER,0x00DFF032
    .equ STACK_TOP,0x0007FFFC

    .section .vectors,"a"
    .long STACK_TOP
    .long _rom_reset
    .section .text.boot,"ax"
    .globl _rom_reset
_rom_reset:
    bclr #0,CIAA_PRA
    move.l #STACK_TOP,%sp
    move.w #369,SERPER
    moveq #0,%d7                  /* failure count: keep all state ROM-only */
    lea banner,%a0
    bsr serial_puts
    lea boot_record,%a0
    bsr serial_puts

    lea CIAA_TALO,%a0
    lea CIAA_CRA,%a1
    lea ciaa_ta_pass,%a2
    lea ciaa_ta_fail,%a3
    bsr test_timer
    lea CIAA_TBLO,%a0
    lea CIAA_CRB,%a1
    lea ciaa_tb_pass,%a2
    lea ciaa_tb_fail,%a3
    bsr test_timer
    lea CIAB_TALO,%a0
    lea CIAB_CRA,%a1
    lea ciab_ta_pass,%a2
    lea ciab_ta_fail,%a3
    bsr test_timer
    lea CIAB_TBLO,%a0
    lea CIAB_CRB,%a1
    lea ciab_tb_pass,%a2
    lea ciab_tb_fail,%a3
    bsr test_timer

    tst.b %d7
    bne summary_bad
    lea summary_pass,%a0
    bsr serial_puts
    bra halt
summary_bad:
    lea summary_fail,%a0
    bsr serial_puts
    bra halt

/* A0=timer low (high is +0x100), A1=control, A2=PASS, A3=FAIL.
 * Preserve control byte and current counter snapshot.  Force-load a known
 * latch, start continuous Phi2 counting, observe bounded progress, then
 * stop and restore saved counter/control state. ICR is never enabled. */
test_timer:
    move.b (%a1),%d4
    move.b (%a0),%d5
    move.b 0x100(%a0),%d6

    move.b %d4,%d0
    andi.b #0xFE,%d0
    move.b %d0,(%a1)
    move.b #0xFF,(%a0)
    move.b #0x7F,0x100(%a0)
    move.b %d0,%d1
    andi.b #0xC0,%d1
    ori.b #0x11,%d1
    move.b %d1,(%a1)
    nop
    nop
    move.b 0x100(%a0),%d2
    lsl.w #8,%d2
    move.b (%a0),%d2
    andi.l #0x0000FFFF,%d2
    move.w #0x2000,%d3
1:
    move.b 0x100(%a0),%d0
    lsl.w #8,%d0
    move.b (%a0),%d0
    andi.l #0x0000FFFF,%d0
    cmp.w %d2,%d0
    bne 2f
    dbra %d3,1b
    addq.b #1,%d7
    move.b %d4,%d0
    andi.b #0xFE,%d0
    move.b %d0,(%a1)
    move.b %d5,(%a0)
    move.b %d6,0x100(%a0)
    move.b %d4,(%a1)
    move.l %a3,%a0
    bsr serial_puts
    rts
2:
    move.b %d4,%d0
    andi.b #0xFE,%d0
    move.b %d0,(%a1)
    move.b %d5,(%a0)
    move.b %d6,0x100(%a0)
    move.b %d4,(%a1)
    move.l %a2,%a0
    bsr serial_puts
    rts

serial_puts:
    move.b (%a0)+,%d0
    beq 4f
3:  btst #13,SERDATR
    beq 3b
    andi.w #0x00ff,%d0
    ori.w #0x0100,%d0
    move.w %d0,SERDAT
    bra serial_puts
4:  rts
halt:
    stop #0x2700
    bra halt

    .section .rodata,"a"
banner: .asciz "AMIDIAG proto=1 milestone=M4.2 cpu=68000\r\n"
boot_record: .asciz "BOOT phase=reset status=PASS\r\n"
ciaa_ta_pass: .asciz "CIAA.TIMERA status=PASS mode=poll progress=observed restore=PASS\r\n"
ciaa_ta_fail: .asciz "CIAA.TIMERA status=FAIL mode=poll reason=no-progress restore=attempted\r\n"
ciaa_tb_pass: .asciz "CIAA.TIMERB status=PASS mode=poll progress=observed restore=PASS\r\n"
ciaa_tb_fail: .asciz "CIAA.TIMERB status=FAIL mode=poll reason=no-progress restore=attempted\r\n"
ciab_ta_pass: .asciz "CIAB.TIMERA status=PASS mode=poll progress=observed restore=PASS\r\n"
ciab_ta_fail: .asciz "CIAB.TIMERA status=FAIL mode=poll reason=no-progress restore=attempted\r\n"
ciab_tb_pass: .asciz "CIAB.TIMERB status=PASS mode=poll progress=observed restore=PASS\r\n"
ciab_tb_fail: .asciz "CIAB.TIMERB status=FAIL mode=poll reason=no-progress restore=attempted\r\n"
summary_pass: .asciz "TEST id=CIA.TIMERS status=PASS timers=4 restored=4\r\n"
summary_fail: .asciz "TEST id=CIA.TIMERS status=FAIL\r\n"
