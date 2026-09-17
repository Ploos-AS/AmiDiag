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
    .equ INTREQ_TEST,0x8008

    .section .vectors,"a"
    .long STACK_TOP
    .long _rom_reset

    .section .text.boot,"ax"
    .globl _rom_reset
_rom_reset:
    move.w #0x2700,%sr
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
    cmp.l VEC_L2,%a0
    beq vector_ok
    lea vector_fail,%a0
    bsr serial_puts
    lea summary_fail,%a0
    bsr serial_puts
    bra halt
vector_ok:
    lea vector_pass,%a0
    bsr serial_puts

    move.w INTENAR,%d2
    andi.w #0x7fff,%d2
    move.w #0x7fff,INTENA
    move.w #INTF_PORTS,INTREQ

    /* Clear stale CIA state before enabling the Timer A mask. Reading ICR is
     * an acknowledge operation, so do not poll it after the test starts: a
     * read would deassert CIA-A /IRQ before Paula has necessarily sampled it. */
    move.b #0x01,CIAA_ICR
    move.b CIAA_ICR,%d0

    move.b CIAA_CRA,%d4
    move.b CIAA_TALO,%d5
    move.b CIAA_TAHI,%d6
    move.b %d4,%d0
    andi.b #0xDE,%d0
    move.b %d0,CIAA_CRA
    move.b #0x20,CIAA_TALO
    move.b #0x00,CIAA_TAHI

    move.b #0x81,CIAA_ICR
    move.w #INTENA_TEST,INTENA
    move.b %d0,%d1
    andi.b #0xF6,%d1
    ori.b #0x11,%d1
    move.b %d1,CIAA_CRA

    /* Stage 1: observe Paula first.  This leaves CIA-A /IRQ asserted until
     * PORTS has been observed, then acknowledges CIA exactly once. */
    move.l #0x00020000,%d3
1:  move.w INTREQR,%d0
    andi.w #INTF_PORTS,%d0
    bne 2f
    subq.l #1,%d3
    bne 1b
    bsr cleanup
    lea paula_route_fail,%a0
    bsr serial_puts
    lea paula_fail,%a0
    bsr serial_puts
    lea cpu_skip,%a0
    bsr serial_puts
    lea summary_fail,%a0
    bsr serial_puts
    bra halt

2:  lea paula_route_pass,%a0
    bsr serial_puts
    /* Now acknowledge the CIA source and clear the old Paula request. */
    move.b CIAA_ICR,%d0
    btst #0,%d0
    bne cia_seen
    lea cia_sync_fail,%a0
    bsr serial_puts
    bra stage2
cia_seen:
    lea cia_sync_pass,%a0
    bsr serial_puts
stage2:
    move.w #INTF_PORTS,INTREQ
    clr.l IRQ_FLAG
    move.w #0x2100,%sr
    move.w #INTREQ_TEST,INTREQ
    move.w INTREQR,%d0
    andi.w #INTF_PORTS,%d0
    bne cpu_req_pending
    move.w #0x2700,%sr
    bsr cleanup
    lea cpu_req_fail,%a0
    bsr serial_puts
    lea paula_pass,%a0
    bsr serial_puts
    lea cpu_fail,%a0
    bsr serial_puts
    lea summary_fail,%a0
    bsr serial_puts
    bra halt
cpu_req_pending:
    lea cpu_req_pass,%a0
    bsr serial_puts
    move.l #0x00020000,%d3
3:  tst.l IRQ_FLAG
    bne 4f
    subq.l #1,%d3
    bne 3b
    move.w #0x2700,%sr
    bsr cleanup
    lea handler_fail,%a0
    bsr serial_puts
    lea paula_pass,%a0
    bsr serial_puts
    lea cpu_fail,%a0
    bsr serial_puts
    lea summary_fail,%a0
    bsr serial_puts
    bra halt
4:
    move.w #0x2700,%sr
    bsr cleanup
    lea handler_pass,%a0
    bsr serial_puts
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
    beq 5f
    move.b CIAA_ICR,%d1
    move.w #INTF_PORTS,INTREQ
    move.l #1,IRQ_FLAG
5:  movem.l (%sp)+,%d0-%d1/%a0
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
    beq 6f
    move.w %d2,%d0
    ori.w #0x8000,%d0
    move.w %d0,INTENA
6:  rts

serial_puts:
    move.b (%a0)+,%d0
    beq 8f
7:  btst #13,SERDATR
    beq 7b
    andi.w #0x00ff,%d0
    ori.w #0x0100,%d0
    move.w %d0,SERDAT
    bra serial_puts
8:  rts
halt:
    stop #0x2700
    bra halt

    .section .rodata,"a"
banner: .asciz "AMIDIAG proto=1 milestone=M4.4 cpu=68000\r\n"
boot_record: .asciz "BOOT phase=reset status=PASS\r\n"
vector_pass: .asciz "IRQ.DIAG vector=0x68 writable=PASS handler-address=PASS\r\n"
vector_fail: .asciz "IRQ.DIAG vector=0x68 writable=FAIL reason=readback-mismatch\r\n"
cia_sync_pass: .asciz "IRQ.DIAG cia=timerA-pending status=PASS ack=after-paula\r\n"
cia_sync_fail: .asciz "IRQ.DIAG cia=timerA-pending status=FAIL ack=after-paula\r\n"
paula_route_pass: .asciz "IRQ.DIAG cia-to-paula=PORTS status=PASS ack-order=paula-before-cia\r\n"
paula_route_fail: .asciz "IRQ.DIAG cia-to-paula=PORTS status=FAIL ack-order=paula-before-cia\r\n"
cpu_req_pass: .asciz "IRQ.DIAG cpu-stage intreq=PORTS pending=PASS\r\n"
cpu_req_fail: .asciz "IRQ.DIAG cpu-stage intreq=PORTS pending=FAIL\r\n"
handler_pass: .asciz "IRQ.DIAG cpu-stage handler-entered=PASS\r\n"
handler_fail: .asciz "IRQ.DIAG cpu-stage handler-entered=FAIL\r\n"
paula_pass: .asciz "IRQ.PAULA status=PASS source=PORTS intena=enabled intreq=observed cleanup=PASS\r\n"
paula_fail: .asciz "IRQ.PAULA status=FAIL source=PORTS reason=timeout cleanup=attempted\r\n"
cpu_pass: .asciz "IRQ.CPU status=PASS level=2 vector=autovector handler=observed cleanup=PASS\r\n"
cpu_fail: .asciz "IRQ.CPU status=FAIL level=2 vector=autovector reason=handler-not-observed cleanup=attempted\r\n"
cpu_skip: .asciz "IRQ.CPU status=SKIP level=2 vector=autovector reason=paula-not-observed cleanup=attempted\r\n"
summary_pass: .asciz "TEST id=IRQ.CONTROLLER status=PASS paths=2 cleanup=2\r\n"
summary_fail: .asciz "TEST id=IRQ.CONTROLLER status=FAIL\r\n"
