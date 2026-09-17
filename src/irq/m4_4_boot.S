/* AmiDiag M4.4: clean-room Paula/68000 interrupt path, A500 baseline. */
    .equ CIAA_PRA,0x00BFE001
    .equ CIAA_DDRA,0x00BFE201
    .equ CIAA_TALO,0x00BFE401
    .equ CIAA_TAHI,0x00BFE501
    .equ CIAA_ICR,0x00BFED01
    .equ CIAA_CRA,0x00BFEE01
    .equ INTENAR,0x00DFF01C
    .equ INTREQR,0x00DFF01E
    .equ INTENA, 0x00DFF09A
    .equ INTREQ,  0x00DFF09C
    .equ SERDATR, 0x00DFF018
    .equ SERDAT,  0x00DFF030
    .equ SERPER,  0x00DFF032
    .equ STACK_TOP,0x0007FFFC
    .equ IRQ_FLAG,0x0007F000
    .equ VEC_L2,0x00000068
    .equ INTF_PORTS,0x0008
    .equ INTENA_TEST,0xC008

    .section .vectors,"a"
    .long STACK_TOP
    .long _rom_reset

    .section .text.boot,"ax"
    .globl _rom_reset
_rom_reset:
    move.w #0x2700,%sr
    /* CIAA PA0 is /OVL. Make it an output before driving it low. */
    bset #0,CIAA_DDRA
    bclr #0,CIAA_PRA
    move.l #STACK_TOP,%sp
    move.w #369,SERPER
    lea banner,%a0
    bsr serial_puts
    lea boot_record,%a0
    bsr serial_puts

    clr.l IRQ_FLAG
    move.l VEC_L2,%d7
    lea level2_handler,%a0
    move.l %a0,VEC_L2

    /* Save Paula enable state, then isolate this test from unrelated sources. */
    move.w INTENAR,%d2
    andi.w #0x7fff,%d2
    move.w #0x7fff,INTENA
    move.w #INTF_PORTS,INTREQ

    /* Establish a quiet CIA source. */
    move.b #0x01,CIAA_ICR
    move.b CIAA_ICR,%d0

    /* Save timer state and program a short Timer A source. */
    move.b CIAA_CRA,%d4
    move.b CIAA_TALO,%d5
    move.b CIAA_TAHI,%d6
    move.b %d4,%d0
    andi.b #0xDE,%d0
    move.b %d0,CIAA_CRA
    move.b #0x20,CIAA_TALO
    move.b #0x00,CIAA_TAHI

    /* Enable CIA Timer A and only Paula master + PORTS. */
    move.b #0x81,CIAA_ICR
    move.w #INTENA_TEST,INTENA
    move.b %d0,%d1
    andi.b #0xF6,%d1
    ori.b #0x11,%d1
    move.b %d1,CIAA_CRA

    /* Synchronize on a proven CIA Timer A request first.  Reading ICR
     * acknowledges that request; continuous Timer A then supplies a fresh
     * edge for the CIA -> Paula PORTS path.  This separates a timer failure
     * from a Paula routing failure without relying on an unsynchronised first
     * underflow during setup. */
    move.w #0x7fff,%d3
1:  move.b CIAA_ICR,%d0
    btst #0,%d0
    bne 2f
    dbra %d3,1b
    bsr cleanup
    lea paula_fail,%a0
    bsr serial_puts
    lea cpu_skip,%a0
    bsr serial_puts
    lea summary_fail,%a0
    bsr serial_puts
    bra halt

    /* Stage 1: CPU remains masked; require a fresh CIA -> Paula PORTS request. */
2:  move.w #INTF_PORTS,INTREQ
    move.l #0x00020000,%d3
3:  move.w INTREQR,%d0
    andi.w #INTF_PORTS,%d0
    bne 4f
    subq.l #1,%d3
    bne 3b
    bsr cleanup
    lea paula_fail,%a0
    bsr serial_puts
    lea cpu_skip,%a0
    bsr serial_puts
    lea summary_fail,%a0
    bsr serial_puts
    bra halt

    /* Stage 2: unmask the CPU and require the level-2 autovector handler. */
4:  move.w #0x2000,%sr
    move.l #0x00020000,%d3
5:  tst.l IRQ_FLAG
    bne 6f
    subq.l #1,%d3
    bne 5b
    move.w #0x2700,%sr
    bsr cleanup
    lea paula_pass,%a0
    bsr serial_puts
    lea cpu_fail,%a0
    bsr serial_puts
    lea summary_fail,%a0
    bsr serial_puts
    bra halt
6:
    move.w #0x2700,%sr
    bsr cleanup
    lea paula_pass,%a0
    bsr serial_puts
    lea cpu_pass,%a0
    bsr serial_puts
    lea summary_pass,%a0
    bsr serial_puts
    bra halt

level2_handler:
    movem.l %d0-%d1/%a0,-(%sp)
    move.w INTREQR,%d0
    andi.w #INTF_PORTS,%d0
    beq 7f
    move.b CIAA_ICR,%d1
    move.w #INTF_PORTS,INTREQ
    move.l #1,IRQ_FLAG
7:  movem.l (%sp)+,%d0-%d1/%a0
    rte

cleanup:
    move.b #0x01,CIAA_ICR
    move.w #0x7fff,INTENA
    move.b %d4,%d0
    andi.b #0xFE,%d0
    move.b %d0,CIAA_CRA
    move.b %d5,CIAA_TALO
    move.b %d6,CIAA_TAHI
    move.b CIAA_ICR,%d0
    move.w #INTF_PORTS,INTREQ
    move.b %d4,CIAA_CRA
    move.l %d7,VEC_L2
    tst.w %d2
    beq 8f
    move.w %d2,%d0
    ori.w #0x8000,%d0
    move.w %d0,INTENA
8:  rts

serial_puts:
    move.b (%a0)+,%d0
    beq 10f
9:  btst #13,SERDATR
    beq 9b
    andi.w #0x00ff,%d0
    ori.w #0x0100,%d0
    move.w %d0,SERDAT
    bra serial_puts
10: rts
halt:
    stop #0x2700
    bra halt

    .section .rodata,"a"
banner: .asciz "AMIDIAG proto=1 milestone=M4.4 cpu=68000\r\n"
boot_record: .asciz "BOOT phase=reset status=PASS\r\n"
paula_pass: .asciz "IRQ.PAULA status=PASS source=PORTS intena=enabled intreq=observed cleanup=PASS\r\n"
paula_fail: .asciz "IRQ.PAULA status=FAIL source=PORTS reason=timeout cleanup=attempted\r\n"
cpu_pass: .asciz "IRQ.CPU status=PASS level=2 vector=autovector handler=observed cleanup=PASS\r\n"
cpu_fail: .asciz "IRQ.CPU status=FAIL level=2 vector=autovector reason=handler-not-observed cleanup=attempted\r\n"
cpu_skip: .asciz "IRQ.CPU status=SKIP level=2 vector=autovector reason=paula-not-observed cleanup=attempted\r\n"
summary_pass: .asciz "TEST id=IRQ.CONTROLLER status=PASS paths=2 cleanup=2\r\n"
summary_fail: .asciz "TEST id=IRQ.CONTROLLER status=FAIL\r\n"
