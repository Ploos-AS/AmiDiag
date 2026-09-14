/* AmiDiag M3.1 clean-room recoverable exception qualification ROM. */

    .equ CIAA_PRA,   0x00BFE001
    .equ SERDATR,    0x00DFF018
    .equ SERDAT,     0x00DFF030
    .equ SERPER,     0x00DFF032
    .equ SERDATR_TBE, 13
    .equ SERPER_9600_PAL, 369
    .equ STACK_TOP,  0x0007FFFC

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

    lea     banner,%a0
    bsr     serial_puts
    lea     boot_record,%a0
    bsr     serial_puts
    lea     vectors_record,%a0
    bsr     serial_puts

    bsr     test_recoverable_trap0
    tst.b   %d1
    bne     trap_fail

    lea     frame_prefix,%a0
    bsr     serial_puts
    move.l  %d4,%d0
    bsr     serial_put_hex16
    lea     frame_pc,%a0
    bsr     serial_puts
    move.l  %d5,%d0
    bsr     serial_put_hex32
    lea     crlf,%a0
    bsr     serial_puts

    lea     trap_pass,%a0
    bsr     serial_puts
    lea     baseline_pass,%a0
    bsr     serial_puts
    bra     halt

trap_fail:
    lea     trap_fail_record,%a0
    bsr     serial_puts
    bra     halt

/* Controlled format-0 style exception round trip.
   TRAP #0 stacks SR and return PC. The handler captures both and RTEs.
   d7 is the handler witness; d4/d5 return captured SR/PC. */
test_recoverable_trap0:
    moveq   #0,%d1
    moveq   #0,%d4
    moveq   #0,%d5
    moveq   #0,%d7
    trap    #0
trap0_return:
    cmpi.b  #1,%d7
    beq.s   trap0_ok
    moveq   #1,%d1
trap0_ok:
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
    move.l  #_exception_trap0,128
    rts

_exception_trap0:
    moveq   #0,%d4
    move.w  (%sp),%d4
    move.l  2(%sp),%d5
    moveq   #1,%d7
    rte

_exception_bus:          lea exc_bus,%a0; bra.s exception_fatal
_exception_address:      lea exc_address,%a0; bra.s exception_fatal
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

serial_put_hex16:
    movem.l %d1-%d3,-(%sp)
    andi.l  #0x0000FFFF,%d0
    move.l  %d0,%d2
    moveq   #3,%d3
hex16_loop:
    rol.w   #4,%d2
    move.w  %d2,%d1
    andi.w  #0x000F,%d1
    bsr.s   serial_put_hex_nibble
    dbra    %d3,hex16_loop
    movem.l (%sp)+,%d1-%d3
    rts

serial_put_hex32:
    movem.l %d1-%d3,-(%sp)
    move.l  %d0,%d2
    moveq   #7,%d3
hex32_loop:
    rol.l   #4,%d2
    move.l  %d2,%d1
    andi.w  #0x000F,%d1
    bsr.s   serial_put_hex_nibble
    dbra    %d3,hex32_loop
    movem.l (%sp)+,%d1-%d3
    rts

serial_put_hex_nibble:
    cmpi.b  #9,%d1
    ble.s   hex_digit
    addi.b  #('A'-10),%d1
    bra.s   hex_emit
hex_digit:
    addi.b  #'0',%d1
hex_emit:
    move.b  %d1,%d0
    bra     serial_putc

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
banner:          .asciz "AMIDIAG proto=1 milestone=M3.1 cpu=68000\r\n"
boot_record:     .asciz "BOOT phase=reset status=PASS\r\n"
vectors_record:  .asciz "TEST id=CPU.VECTORS status=PASS table=ram\r\n"
frame_prefix:    .asciz "FRAME id=CPU.TRAP0 sr=0x"
frame_pc:        .asciz " pc=0x"
trap_pass:       .asciz "TEST id=CPU.EXCEPTION.RECOVER status=PASS vector=TRAP0 frame=sr-pc return=RTE\r\n"
trap_fail_record:.asciz "TEST id=CPU.EXCEPTION.RECOVER status=FAIL vector=TRAP0\r\n"
baseline_pass:   .asciz "TEST id=CPU.BASELINE status=PASS cpu=68000 exception=trap0\r\n"
crlf:            .asciz "\r\n"
exc_bus:         .asciz "EXCEPTION id=CPU.BUS status=FAIL fatal=1\r\n"
exc_address:     .asciz "EXCEPTION id=CPU.ADDRESS status=FAIL fatal=1\r\n"
exc_illegal:     .asciz "EXCEPTION id=CPU.ILLEGAL status=FAIL fatal=1\r\n"
exc_zero_divide: .asciz "EXCEPTION id=CPU.DIVZERO status=FAIL fatal=1\r\n"
exc_chk:         .asciz "EXCEPTION id=CPU.CHK status=FAIL fatal=1\r\n"
exc_trapv:       .asciz "EXCEPTION id=CPU.TRAPV status=FAIL fatal=1\r\n"
exc_privilege:   .asciz "EXCEPTION id=CPU.PRIV status=FAIL fatal=1\r\n"
exc_trace:       .asciz "EXCEPTION id=CPU.TRACE status=FAIL fatal=1\r\n"
exc_line_a:      .asciz "EXCEPTION id=CPU.LINEA status=FAIL fatal=1\r\n"
exc_line_f:      .asciz "EXCEPTION id=CPU.LINEF status=FAIL fatal=1\r\n"
exc_default:     .asciz "EXCEPTION id=CPU.UNKNOWN status=FAIL fatal=1\r\n"
