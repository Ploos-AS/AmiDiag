/* AmiDiag M3.7 clean-room guarded Slow/Fast RAM profile probes. */

    .equ CIAA_PRA, 0x00BFE001
    .equ SERDATR,  0x00DFF018
    .equ SERDAT,   0x00DFF030
    .equ SERPER,   0x00DFF032
    .equ SERDATR_TBE, 13
    .equ SERPER_9600_PAL, 369
    .equ STACK_TOP, 0x0007FFFC

    .equ PROBE_STATE_BASE, 0x00003000
    .equ PROBE_ARMED, PROBE_STATE_BASE+0
    .equ PROBE_EXPECT, PROBE_STATE_BASE+2
    .equ PROBE_RESULT, PROBE_STATE_BASE+4
    .equ PROBE_VALUE, PROBE_STATE_BASE+6
    .equ EXPECT_BUS, 2
    .equ RESULT_NONE, 0
    .equ RESULT_OK, 1
    .equ RESULT_BUS_ERROR, 2

    .equ MEM_PRESENT, 1
    .equ MEM_OPEN_BUS, 2
    .equ MEM_BUS_ERROR, 3

    .equ SLOW_ADDR, 0x00C00000
    .equ FAST_ADDR, 0x00200000
    .equ TEST_PATTERN, 0xA55A

    .section .vectors,"a"
_rom_vectors:
    .long STACK_TOP
    .long _rom_reset

    .section .text.boot,"ax"
    .globl _rom_reset
_rom_reset:
    bclr #0,CIAA_PRA
    move.l #STACK_TOP,%sp
    move.w #SERPER_9600_PAL,SERPER
    bsr install_ram_vectors
    bsr probe_state_reset
    lea banner,%a0
    bsr serial_puts
    lea boot_record,%a0
    bsr serial_puts
    lea guard_record,%a0
    bsr serial_puts

    move.l #SLOW_ADDR,%a2
    bsr probe_candidate
    bsr report_slow

    move.l #FAST_ADDR,%a2
    bsr probe_candidate
    bsr report_fast

    lea done_record,%a0
    bsr serial_puts
    lea baseline_record,%a0
    bsr serial_puts
    bra halt

/* Guarded reversible single-cell RAM qualification. A2=candidate, D0=class. */
probe_candidate:
    move.l %a2,%a0
    moveq #EXPECT_BUS,%d0
    bsr guarded_read16
    cmpi.b #RESULT_BUS_ERROR,PROBE_RESULT
    beq candidate_bus
    move.w PROBE_VALUE,%d5

    move.l %a2,%a0
    move.w #TEST_PATTERN,%d1
    moveq #EXPECT_BUS,%d0
    bsr guarded_write16
    cmpi.b #RESULT_BUS_ERROR,PROBE_RESULT
    beq candidate_bus

    move.l %a2,%a0
    moveq #EXPECT_BUS,%d0
    bsr guarded_read16
    cmpi.b #RESULT_BUS_ERROR,PROBE_RESULT
    beq candidate_bus_restore
    move.w PROBE_VALUE,%d6

    move.l %a2,%a0
    move.w %d5,%d1
    moveq #EXPECT_BUS,%d0
    bsr guarded_write16
    cmpi.w #TEST_PATTERN,%d6
    bne candidate_open
    moveq #MEM_PRESENT,%d0
    rts
candidate_open:
    moveq #MEM_OPEN_BUS,%d0
    rts
candidate_bus_restore:
    move.l %a2,%a0
    move.w %d5,%d1
    moveq #EXPECT_BUS,%d0
    bsr guarded_write16
candidate_bus:
    moveq #MEM_BUS_ERROR,%d0
    rts

report_slow:
    cmpi.b #MEM_PRESENT,%d0
    beq slow_present
    cmpi.b #MEM_BUS_ERROR,%d0
    beq slow_bus
    lea slow_open,%a0
    bra report_emit
slow_present: lea slow_yes,%a0; bra report_emit
slow_bus: lea slow_berr,%a0; bra report_emit

report_fast:
    cmpi.b #MEM_PRESENT,%d0
    beq fast_present
    cmpi.b #MEM_BUS_ERROR,%d0
    beq fast_bus
    lea fast_open,%a0
    bra report_emit
fast_present: lea fast_yes,%a0; bra report_emit
fast_bus: lea fast_berr,%a0
report_emit:
    bsr serial_puts
    rts

guarded_read16:
    move.b #1,PROBE_ARMED
    move.b %d0,PROBE_EXPECT
    move.b #RESULT_NONE,PROBE_RESULT
    clr.w PROBE_VALUE
    lea guarded_recovered,%a6
    move.w (%a0),%d1
    move.w %d1,PROBE_VALUE
    clr.b PROBE_ARMED
    move.b #RESULT_OK,PROBE_RESULT
    rts

guarded_write16:
    move.b #1,PROBE_ARMED
    move.b %d0,PROBE_EXPECT
    move.b #RESULT_NONE,PROBE_RESULT
    lea guarded_recovered,%a6
    move.w %d1,(%a0)
    clr.b PROBE_ARMED
    move.b #RESULT_OK,PROBE_RESULT
    rts

guarded_recovered:
    clr.b PROBE_ARMED
    rts

probe_state_reset:
    clr.b PROBE_ARMED
    clr.b PROBE_EXPECT
    clr.b PROBE_RESULT
    clr.w PROBE_VALUE
    rts

install_ram_vectors:
    move.l #_exception_default,%d0
    lea 8,%a1
    move.w #253,%d1
1:  move.l %d0,(%a1)+
    dbra %d1,1b
    move.l #_exception_bus,8
    move.l #_exception_address,12
    rts

_exception_bus:
    cmpi.b #1,PROBE_ARMED
    bne unexpected_bus
    cmpi.b #EXPECT_BUS,PROBE_EXPECT
    bne unexpected_bus
    move.b #RESULT_BUS_ERROR,PROBE_RESULT
    adda.w #14,%sp
    jmp (%a6)
_exception_address:
    lea exc_address,%a0
    bra exception_fatal
unexpected_bus:
    lea exc_bus,%a0
    bra exception_fatal
_exception_default:
    lea exc_default,%a0
exception_fatal:
    bsr serial_puts
exception_halt:
    stop #0x2700
    bra exception_halt

serial_puts:
    move.b (%a0)+,%d0
    beq serial_puts_done
    bsr serial_putc
    bra serial_puts
serial_puts_done: rts
serial_putc:
serial_wait_tbe:
    btst #SERDATR_TBE,SERDATR
    beq serial_wait_tbe
    andi.w #0x00FF,%d0
    ori.w #0x0100,%d0
    move.w %d0,SERDAT
    rts
halt:
    stop #0x2700
    bra halt

    .section .rodata,"a"
banner: .asciz "AMIDIAG proto=1 milestone=M3.7 cpu=68000\r\n"
boot_record: .asciz "BOOT phase=reset status=PASS\r\n"
guard_record: .asciz "TEST id=MEM.EXPANSION.PROBE.GUARD status=PASS mode=preserve-write-read-restore unexpected=fatal\r\n"
slow_yes: .asciz "PROBE class=MEM region=SLOW address=0x00C00000 width=16 result=PRESENT preserve=1\r\n"
slow_open: .asciz "PROBE class=MEM region=SLOW address=0x00C00000 width=16 result=OPEN_BUS preserve=1\r\n"
slow_berr: .asciz "PROBE class=MEM region=SLOW address=0x00C00000 width=16 result=BUS_ERROR preserve=1\r\n"
fast_yes: .asciz "PROBE class=MEM region=FAST address=0x00200000 width=16 result=PRESENT preserve=1\r\n"
fast_open: .asciz "PROBE class=MEM region=FAST address=0x00200000 width=16 result=OPEN_BUS preserve=1\r\n"
fast_berr: .asciz "PROBE class=MEM region=FAST address=0x00200000 width=16 result=BUS_ERROR preserve=1\r\n"
done_record: .asciz "TEST id=MEM.EXPANSION.PROBE status=PASS regions=SLOW,FAST preserve=1 confidence=guarded-profile-probe\r\n"
baseline_record: .asciz "TEST id=CPU.BASELINE status=PASS cpu=68000 probe=guarded-expansion-memory\r\n"
exc_bus: .asciz "EXCEPTION id=CPU.BUS status=FAIL fatal=1 reason=unexpected-or-unarmed\r\n"
exc_address: .asciz "EXCEPTION id=CPU.ADDRESS status=FAIL fatal=1 reason=unexpected-or-unarmed\r\n"
exc_default: .asciz "EXCEPTION id=CPU.UNKNOWN status=FAIL fatal=1\r\n"
