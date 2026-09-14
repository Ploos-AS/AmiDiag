/* AmiDiag M3.4 clean-room guarded probe qualification ROM. */

    .equ CIAA_PRA,   0x00BFE001
    .equ SERDATR,    0x00DFF018
    .equ SERDAT,     0x00DFF030
    .equ SERPER,     0x00DFF032
    .equ SERDATR_TBE, 13
    .equ SERPER_9600_PAL, 369
    .equ STACK_TOP,  0x0007FFFC

    .equ PROBE_STATE_BASE, 0x00003000
    .equ PROBE_ARMED,      PROBE_STATE_BASE+0
    .equ PROBE_EXPECT,     PROBE_STATE_BASE+2
    .equ PROBE_RESULT,     PROBE_STATE_BASE+4
    .equ PROBE_VALUE,      PROBE_STATE_BASE+6

    .equ EXPECT_NONE,      0
    .equ EXPECT_BUS,       2
    .equ EXPECT_ADDRESS,   3

    .equ RESULT_NONE,          0
    .equ RESULT_READABLE,      1
    .equ RESULT_BUS_ERROR,     2
    .equ RESULT_ADDRESS_ERROR, 3
    .equ RESULT_OPEN_BUS,      4

    .equ CHIP_TEST_ADDR,   0x00004000
    .equ BUS_PROBE_ADDR,   0x00400000

    .section .vectors,"a"
    .globl _rom_vectors
_rom_vectors:
    .long STACK_TOP
    .long _rom_reset

    .section .text.boot,"ax"
    .globl _rom_reset
_rom_reset:
    bclr    #0,CIAA_PRA
    move.l  #STACK_TOP,%sp
    move.w  #SERPER_9600_PAL,SERPER
    bsr     install_ram_vectors
    bsr     probe_state_reset

    lea     banner,%a0
    bsr     serial_puts
    lea     boot_record,%a0
    bsr     serial_puts
    lea     vectors_record,%a0
    bsr     serial_puts
    lea     guard_record,%a0
    bsr     serial_puts

    /* Known Chip RAM: the guarded read must complete normally. */
    move.l  #CHIP_TEST_ADDR,%a0
    moveq   #EXPECT_NONE,%d0
    bsr     guarded_read16
    cmpi.b  #RESULT_READABLE,PROBE_RESULT
    bne     probe_fail
    lea     readable_record,%a0
    bsr     serial_puts

    /* Odd word access: must enter vector 3 while the guard expects it. */
    move.l  #1,%a0
    moveq   #EXPECT_ADDRESS,%d0
    bsr     guarded_read16
    cmpi.b  #RESULT_ADDRESS_ERROR,PROBE_RESULT
    bne     probe_fail
    lea     address_record,%a0
    bsr     serial_puts

    /* A500 unmapped address: some platforms assert /BERR, others complete
       the cycle as an open/unmapped bus. Both are valid capability results. */
    move.l  #BUS_PROBE_ADDR,%a0
    moveq   #EXPECT_BUS,%d0
    bsr     guarded_read16
    cmpi.b  #RESULT_BUS_ERROR,PROBE_RESULT
    beq.s   bus_result
    cmpi.b  #RESULT_OPEN_BUS,PROBE_RESULT
    bne     probe_fail
    lea     open_bus_record,%a0
    bsr     serial_puts
    bra.s   probes_done
bus_result:
    lea     bus_record,%a0
    bsr     serial_puts
probes_done:
    lea     summary_record,%a0
    bsr     serial_puts
    lea     baseline_record,%a0
    bsr     serial_puts
    bra     halt

probe_fail:
    lea     fail_record,%a0
    bsr     serial_puts
    bra     halt

/* guarded_read16
   a0 = address
   d0 = EXPECT_NONE / EXPECT_BUS / EXPECT_ADDRESS
   Result is stored in PROBE_RESULT and read value in PROBE_VALUE.
   Expected bus/address exceptions recover through a6. Unexpected exceptions
   remain fatal. A BUS-expected access that completes normally is classified
   OPEN_BUS rather than pretending absence of RAM necessarily asserts /BERR. */
guarded_read16:
    move.b  #1,PROBE_ARMED
    move.b  %d0,PROBE_EXPECT
    move.b  #RESULT_NONE,PROBE_RESULT
    clr.w   PROBE_VALUE
    lea     guarded_recovered,%a6
    move.w  (%a0),%d1
    move.w  %d1,PROBE_VALUE
    move.b  PROBE_EXPECT,%d2
    clr.b   PROBE_ARMED
    cmpi.b  #EXPECT_BUS,%d2
    beq.s   guarded_open_bus
    move.b  #RESULT_READABLE,PROBE_RESULT
    rts
guarded_open_bus:
    move.b  #RESULT_OPEN_BUS,PROBE_RESULT
    rts
guarded_recovered:
    clr.b   PROBE_ARMED
    rts

probe_state_reset:
    clr.b   PROBE_ARMED
    clr.b   PROBE_EXPECT
    clr.b   PROBE_RESULT
    clr.w   PROBE_VALUE
    rts

install_ram_vectors:
    move.l  #_exception_default,%d0
    lea     8,%a1
    move.w  #253,%d1
1:
    move.l  %d0,(%a1)+
    dbra    %d1,1b
    move.l  #_exception_bus,8
    move.l  #_exception_address,12
    move.l  #_exception_illegal,16
    move.l  #_exception_zero_divide,20
    move.l  #_exception_chk,24
    move.l  #_exception_trapv,28
    move.l  #_exception_privilege,32
    move.l  #_exception_trace,36
    move.l  #_exception_line_a,40
    move.l  #_exception_line_f,44
    rts

/* MC68000 group-0 bus/address frames are 14 bytes. These handlers only
   recover when a probe is explicitly armed for the matching fault class. */
_exception_bus:
    cmpi.b  #1,PROBE_ARMED
    bne     unexpected_bus
    cmpi.b  #EXPECT_BUS,PROBE_EXPECT
    bne     unexpected_bus
    move.b  #RESULT_BUS_ERROR,PROBE_RESULT
    adda.w  #14,%sp
    jmp     (%a6)

_exception_address:
    cmpi.b  #1,PROBE_ARMED
    bne     unexpected_address
    cmpi.b  #EXPECT_ADDRESS,PROBE_EXPECT
    bne     unexpected_address
    move.b  #RESULT_ADDRESS_ERROR,PROBE_RESULT
    adda.w  #14,%sp
    jmp     (%a6)

unexpected_bus:
    lea     exc_bus,%a0
    bra.s   exception_fatal
unexpected_address:
    lea     exc_address,%a0
    bra.s   exception_fatal
_exception_illegal:      lea exc_illegal,%a0; bra.s exception_fatal
_exception_zero_divide:  lea exc_zero_divide,%a0; bra.s exception_fatal
_exception_chk:          lea exc_chk,%a0; bra.s exception_fatal
_exception_trapv:        lea exc_trapv,%a0; bra.s exception_fatal
_exception_privilege:    lea exc_privilege,%a0; bra.s exception_fatal
_exception_trace:        lea exc_trace,%a0; bra.s exception_fatal
_exception_line_a:       lea exc_line_a,%a0; bra.s exception_fatal
_exception_line_f:       lea exc_line_f,%a0; bra.s exception_fatal
_exception_default:      lea exc_default,%a0
exception_fatal:
    bsr     serial_puts
exception_halt:
    stop    #0x2700
    bra.s   exception_halt

serial_puts:
    move.b  (%a0)+,%d0
    beq.s   serial_puts_done
    bsr.s   serial_putc
    bra.s   serial_puts
serial_puts_done:
    rts

serial_putc:
serial_wait_tbe:
    btst    #SERDATR_TBE,SERDATR
    beq.s   serial_wait_tbe
    andi.w  #0x00FF,%d0
    ori.w   #0x0100,%d0
    move.w  %d0,SERDAT
    rts

halt:
    stop    #0x2700
    bra.s   halt

    .section .rodata,"a"
banner:          .asciz "AMIDIAG proto=1 milestone=M3.4 cpu=68000\r\n"
boot_record:     .asciz "BOOT phase=reset status=PASS\r\n"
vectors_record:  .asciz "TEST id=CPU.VECTORS status=PASS table=ram\r\n"
guard_record:    .asciz "TEST id=CPU.PROBE.GUARD status=PASS armed=explicit bus=guarded address=guarded unexpected=fatal\r\n"
readable_record: .asciz "PROBE class=MEM address=0x00004000 width=16 result=READABLE\r\n"
address_record:  .asciz "PROBE class=MEM address=0x00000001 width=16 result=ADDRESS_ERROR\r\n"
bus_record:      .asciz "PROBE class=MEM address=0x00400000 width=16 result=BUS_ERROR\r\n"
open_bus_record: .asciz "PROBE class=MEM address=0x00400000 width=16 result=OPEN_BUS\r\n"
summary_record:  .asciz "TEST id=CPU.PROBE.RESULTS status=PASS readable=1 address_error=1 unmapped=classified\r\n"
baseline_record: .asciz "TEST id=CPU.BASELINE status=PASS cpu=68000 probe=guarded\r\n"
fail_record:     .asciz "TEST id=CPU.PROBE.GUARD status=FAIL reason=result-mismatch\r\n"
exc_bus:         .asciz "EXCEPTION id=CPU.BUS status=FAIL fatal=1 reason=unexpected-or-unarmed\r\n"
exc_address:     .asciz "EXCEPTION id=CPU.ADDRESS status=FAIL fatal=1 reason=unexpected-or-unarmed\r\n"
exc_illegal:     .asciz "EXCEPTION id=CPU.ILLEGAL status=FAIL fatal=1\r\n"
exc_zero_divide: .asciz "EXCEPTION id=CPU.DIVZERO status=FAIL fatal=1\r\n"
exc_chk:         .asciz "EXCEPTION id=CPU.CHK status=FAIL fatal=1\r\n"
exc_trapv:       .asciz "EXCEPTION id=CPU.TRAPV status=FAIL fatal=1\r\n"
exc_privilege:   .asciz "EXCEPTION id=CPU.PRIV status=FAIL fatal=1\r\n"
exc_trace:       .asciz "EXCEPTION id=CPU.TRACE status=FAIL fatal=1\r\n"
exc_line_a:      .asciz "EXCEPTION id=CPU.LINEA status=FAIL fatal=1\r\n"
exc_line_f:      .asciz "EXCEPTION id=CPU.LINEF status=FAIL fatal=1\r\n"
exc_default:     .asciz "EXCEPTION id=CPU.UNKNOWN status=FAIL fatal=1\r\n"
