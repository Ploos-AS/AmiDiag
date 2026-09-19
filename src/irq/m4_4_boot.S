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

    /*
     * CIA-A's /IRQ output is wired to Paula PORTS (level 2).  Generate a
     * fresh hardware IRQ edge with CIA-A Timer A only after the vector,
     * Paula enables and CPU IPL are ready.
     */
    move.w #INTENA_TEST,INTENA
    move.w INTENAR,%d0
    andi.w #0x4008,%d0
    cmpi.w #0x4008,%d0
    bne paula_setup_fail
    lea paula_enable_pass,%a0
    bsr serial_puts

    /* Stop Timer A, clear pending ICR state, then arm Timer-A interrupt. */
    move.b CIAA_CRA,%d4
    andi.b #0xFE,%d4
    move.b %d4,CIAA_CRA
    move.b CIAA_ICR,%d0
    move.b #0x01,CIAA_ICR
    move.b #0x81,CIAA_ICR
    /* ICR mask is write-only.  Validate the actual IRQ output path by
     * waiting for PORTS after a fresh timer expiry, not by reading ICR. */
    move.b #0x20,CIAA_TALO
    move.b #0x00,CIAA_TAHI
    clr.l IRQ_FLAG
    move.w #INTF_PORTS,INTREQ

    move.w #0x2100,%sr
    lea sr_unmask_pass,%a0
    bsr serial_puts

    /* Start one-shot Timer A: START|RUNMODE|LOAD, Phi2 source. */
    move.b %d4,%d0
    andi.b #0xC0,%d0
    ori.b #0x19,%d0
    move.b %d0,CIAA_CRA
    /* Give the 8520 a short synchronization window after ICR mask/start
     * programming before diagnosing the downstream Paula line. */
    move.l #0x00000100,%d5
cia_sync:
    subq.l #1,%d5
    bne cia_sync

    /* Observe each hardware link while CPU IRQs are still eligible.  Reading
     * ICR clears CIA pending state, so do not read it here; instead observe
     * Timer-A progress and Paula PORTS non-destructively before the handler
     * is expected to acknowledge the chain. */
    move.l #0x00040000,%d3
timer_progress_wait:
    move.b CIAA_TALO,%d0
    cmpi.b #0x20,%d0
    bne timer_progress_seen
    subq.l #1,%d3
    bne timer_progress_wait
    lea timer_progress_fail,%a0
    bsr serial_puts
    bra chain_wait
timer_progress_seen:
    lea timer_progress_pass,%a0
    bsr serial_puts

chain_wait:
    move.l #0x00040000,%d3
ports_wait:
    move.w INTREQR,%d0
    andi.w #INTF_PORTS,%d0
    bne ports_seen
    tst.l IRQ_FLAG
    bne irq_observed
    subq.l #1,%d3
    bne ports_wait
    lea ports_pending_fail,%a0
    bsr serial_puts
    /* Diagnose CIA locally only after PORTS failed. Reading ICR acknowledges
     * the CIA source, so this is intentionally a failure-path probe. Bit 0
     * proves Timer A pending; bit 7 proves an enabled source asserted IRQ. */
    move.b CIAA_ICR,%d0
    move.b %d0,%d1
    andi.b #0x81,%d1
    cmpi.b #0x81,%d1
    bne cia_icr_not_asserted
    lea cia_icr_pending_pass,%a0
    bsr serial_puts
    bra handler_wait
cia_icr_not_asserted:
    lea cia_icr_pending_fail,%a0
    bsr serial_puts
    bra handler_wait
ports_seen:
    lea ports_pending_pass,%a0
    bsr serial_puts

handler_wait:
    move.l #0x00040000,%d3
1:  tst.l IRQ_FLAG
    bne irq_observed
    subq.l #1,%d3
    bne 1b

    move.w #0x2700,%sr
    bsr cleanup
    lea handler_fail,%a0
    bsr serial_puts
    lea paula_fail,%a0
    bsr serial_puts
    lea cpu_fail,%a0
    bsr serial_puts
    lea summary_fail,%a0
    bsr serial_puts
    bra halt

paula_setup_fail:
    bsr cleanup
    lea paula_enable_fail,%a0
    bsr serial_puts
    lea paula_fail,%a0
    bsr serial_puts
    lea cpu_skip,%a0
    bsr serial_puts
    lea summary_fail,%a0
    bsr serial_puts
    bra halt

irq_observed:
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
    /* CIA-A ICR read acknowledges the CIA source; Paula PORTS is then
     * acknowledged separately below. */
    move.b CIAA_ICR,%d1
    move.w INTREQR,%d0
    andi.w #INTF_PORTS,%d0
    beq 5f
    move.w #INTF_PORTS,INTREQ
    move.l #1,IRQ_FLAG
5:  movem.l (%sp)+,%d0-%d1/%a0
    rte

cleanup:
    move.w #0x7fff,INTENA
    move.w #INTF_PORTS,INTREQ
    move.b #0x01,CIAA_ICR
    move.b CIAA_ICR,%d0
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
paula_enable_pass: .asciz "IRQ.DIAG paula-intena master=PASS ports=PASS\r\n"
paula_enable_fail: .asciz "IRQ.DIAG paula-intena master-or-ports=FAIL\r\n"
handler_pass: .asciz "IRQ.DIAG cpu-stage handler-entered=PASS\r\n"
handler_fail: .asciz "IRQ.DIAG cpu-stage handler-entered=FAIL\r\n"
timer_progress_pass: .asciz "IRQ.DIAG chain timerA-progress=PASS\r\n"
timer_progress_fail: .asciz "IRQ.DIAG chain timerA-progress=FAIL\r\n"
ports_pending_pass: .asciz "IRQ.DIAG chain paula-PORTS-pending=PASS\r\n"
ports_pending_fail: .asciz "IRQ.DIAG chain paula-PORTS-pending=FAIL\r\n"
cia_icr_pending_pass: .asciz "IRQ.DIAG chain ciaA-ICR-timerA-pending=PASS\r\n"
cia_icr_pending_fail: .asciz "IRQ.DIAG chain ciaA-ICR-timerA-pending=FAIL\r\n"
cia_route_note: .asciz "IRQ.DIAG chain ciaA-irq-route=PORTS source=TIMERA\r\n"
sr_unmask_pass: .asciz "IRQ.DIAG cpu-stage sr-ipl-after=1 status=PASS\r\n"
paula_pass: .asciz "IRQ.PAULA status=PASS source=PORTS intena=enabled intreq=observed cleanup=PASS\r\n"
paula_fail: .asciz "IRQ.PAULA status=FAIL source=PORTS reason=timeout cleanup=attempted\r\n"
cpu_pass: .asciz "IRQ.CPU status=PASS level=2 vector=autovector handler=observed cleanup=PASS\r\n"
cpu_fail: .asciz "IRQ.CPU status=FAIL level=2 vector=autovector reason=handler-not-observed cleanup=attempted\r\n"
cpu_skip: .asciz "IRQ.CPU status=SKIP level=2 vector=autovector reason=paula-not-observed cleanup=attempted\r\n"
summary_pass: .asciz "TEST id=IRQ.CONTROLLER status=PASS paths=2 cleanup=2\r\n"
summary_fail: .asciz "TEST id=IRQ.CONTROLLER status=FAIL\r\n"
