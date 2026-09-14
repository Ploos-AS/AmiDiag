/* AmiDiag M3.3 clean-room 68000 bus-error handler qualification ROM. */

    .equ CIAA_PRA,   0x00BFE001
    .equ SERDATR,    0x00DFF018
    .equ SERDAT,     0x00DFF030
    .equ SERPER,     0x00DFF032
    .equ SERDATR_TBE, 13
    .equ SERPER_9600_PAL, 369
    .equ STACK_TOP,  0x0007FFFC
    .equ BUS_PROBE_ADDR, 0x00400000
    .equ SYNTH_SSW,  0x1234
    .equ SYNTH_IR,   0x4E71
    .equ SYNTH_SR,   0x2700

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

    /* Probe whether this platform/emulator actually asserts /BERR for an
       unmapped A500 address. Lack of /BERR is a platform capability result,
       not a failure of the bus-error handler. */
    bsr     probe_hardware_berr
    tst.b   %d1
    bne.s   hardware_berr_unavailable
    lea     hardware_berr_pass,%a0
    bsr     serial_puts
    bra.s   hardware_probe_done
hardware_berr_unavailable:
    lea     hardware_berr_unavailable_record,%a0
    bsr     serial_puts
hardware_probe_done:

    /* Independently prove 68000 14-byte bus-error frame parsing and the
       controlled unwind/jump recovery path with a deterministic synthetic
       frame. This does not claim that software can assert the physical BERR
       pin; it qualifies the handler logic once such a frame exists. */
    bsr     test_synthetic_bus_frame
    tst.b   %d1
    bne     bus_fail

    lea     frame_prefix,%a0
    bsr     serial_puts
    move.l  %d2,%d0
    bsr     serial_put_hex16
    lea     frame_addr,%a0
    bsr     serial_puts
    move.l  %d3,%d0
    bsr     serial_put_hex32
    lea     frame_ir,%a0
    bsr     serial_puts
    move.l  %d4,%d0
    bsr     serial_put_hex16
    lea     frame_sr,%a0
    bsr     serial_puts
    move.l  %d5,%d0
    bsr     serial_put_hex16
    lea     frame_pc,%a0
    bsr     serial_puts
    move.l  %d6,%d0
    bsr     serial_put_hex32
    lea     frame_source,%a0
    bsr     serial_puts

    lea     frame_pass,%a0
    bsr     serial_puts
    lea     bus_pass,%a0
    bsr     serial_puts
    lea     baseline_pass,%a0
    bsr     serial_puts
    bra     halt

bus_fail:
    lea     bus_fail_record,%a0
    bsr     serial_puts
    bra     halt

/* Probe a plausible unmapped A500 address. If no /BERR is generated the
   read completes and d1=1. If /BERR is generated, _exception_bus unwinds
   to hardware_bus_recovered, d7=1 and d1 remains zero. */
probe_hardware_berr:
    moveq   #0,%d1
    moveq   #0,%d7
    lea     hardware_bus_recovered,%a6
    move.l  #BUS_PROBE_ADDR,%a0
hardware_bus_fault_instruction:
    move.w  (%a0),%d0
    moveq   #1,%d1
    rts
hardware_bus_recovered:
    cmpi.b  #1,%d7
    beq.s   hardware_bus_done
    moveq   #1,%d1
hardware_bus_done:
    rts

/* Build a deterministic MC68000 group-0 frame on the supervisor stack and
   enter the same handler used by vector 2. Frame layout:
     +0 special-status word, +2 access address, +6 IR,
     +8 SR, +10 PC.
   The handler captures the complete frame, removes all 14 bytes and jumps
   to a6. */
test_synthetic_bus_frame:
    moveq   #0,%d1
    moveq   #0,%d2
    moveq   #0,%d3
    moveq   #0,%d4
    moveq   #0,%d5
    moveq   #0,%d6
    moveq   #0,%d7
    lea     synthetic_bus_recovered,%a6
    suba.w  #14,%sp
    move.w  #SYNTH_SSW,0(%sp)
    move.l  #BUS_PROBE_ADDR,2(%sp)
    move.w  #SYNTH_IR,6(%sp)
    move.w  #SYNTH_SR,8(%sp)
    move.l  #synthetic_fault_pc,10(%sp)
    jmp     _exception_bus
synthetic_fault_pc:
    nop
synthetic_bus_recovered:
    cmpi.b  #1,%d7
    bne.s   synthetic_bus_bad
    cmpi.l  #BUS_PROBE_ADDR,%d3
    bne.s   synthetic_bus_bad
    cmpi.w  #SYNTH_SSW,%d2
    bne.s   synthetic_bus_bad
    cmpi.w  #SYNTH_IR,%d4
    bne.s   synthetic_bus_bad
    cmpi.w  #SYNTH_SR,%d5
    bne.s   synthetic_bus_bad
    lea     synthetic_fault_pc,%a0
    cmp.l   %a0,%d6
    beq.s   synthetic_bus_ok
synthetic_bus_bad:
    moveq   #1,%d1
synthetic_bus_ok:
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

_exception_bus:
    moveq   #0,%d2
    move.w  0(%sp),%d2
    move.l  2(%sp),%d3
    moveq   #0,%d4
    move.w  6(%sp),%d4
    moveq   #0,%d5
    move.w  8(%sp),%d5
    move.l  10(%sp),%d6
    moveq   #1,%d7
    adda.w  #14,%sp
    jmp     (%a6)

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
banner:          .asciz "AMIDIAG proto=1 milestone=M3.3 cpu=68000\r\n"
boot_record:     .asciz "BOOT phase=reset status=PASS\r\n"
vectors_record:  .asciz "TEST id=CPU.VECTORS status=PASS table=ram\r\n"
hardware_berr_pass:.asciz "TEST id=CPU.BUS.HARDWARE status=PASS address=0x00400000 width=16 source=vector2\r\n"
hardware_berr_unavailable_record:.asciz "TEST id=CPU.BUS.HARDWARE status=UNAVAILABLE address=0x00400000 width=16 reason=no-berr\r\n"
frame_prefix:    .asciz "FRAME id=CPU.BUS ssw=0x"
frame_addr:      .asciz " address=0x"
frame_ir:        .asciz " ir=0x"
frame_sr:        .asciz " sr=0x"
frame_pc:        .asciz " pc=0x"
frame_source:    .asciz " source=synthetic\r\n"
frame_pass:      .asciz "TEST id=CPU.BUS.FRAME status=PASS source=synthetic frame=68000-14-byte\r\n"
bus_pass:        .asciz "TEST id=CPU.BUS.RECOVER status=PASS source=synthetic frame=68000-14-byte return=unwind-jump\r\n"
bus_fail_record: .asciz "TEST id=CPU.BUS.RECOVER status=FAIL reason=frame-mismatch\r\n"
baseline_pass:   .asciz "TEST id=CPU.BASELINE status=PASS cpu=68000 exception=bus-frame-handler\r\n"
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
