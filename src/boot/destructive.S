/* AmiDiag M2.8 destructive profile - clean-room 68000 diagnostics.
   This ROM is deliberately destructive and is never built as the default ROM. */

    .equ CIAA_PRA,   0x00BFE001
    .equ SERDATR,    0x00DFF018
    .equ SERDAT,     0x00DFF030
    .equ SERPER,     0x00DFF032
    .equ SERDATR_TBE, 13
    .equ SERPER_9600_PAL, 369
    .equ STACK_TOP,  0x0007FFFC
    .equ TEST_START, 0x00008000
    .equ TEST_END,   0x00070000

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

    lea     banner,%a0
    bsr     serial_puts
    lea     warning,%a0
    bsr     serial_puts
    lea     profile,%a0
    bsr     serial_puts

    move.l  #0x00000000,%d0
    lea     phase_zero,%a0
    bsr     run_pattern
    tst.b   %d1
    bne     fail

    move.l  #0xFFFFFFFF,%d0
    lea     phase_ones,%a0
    bsr     run_pattern
    tst.b   %d1
    bne     fail

    move.l  #0xAAAAAAAA,%d0
    lea     phase_aa,%a0
    bsr     run_pattern
    tst.b   %d1
    bne     fail

    move.l  #0x55555555,%d0
    lea     phase_55,%a0
    bsr     run_pattern
    tst.b   %d1
    bne     fail

    lea     pass_record,%a0
    bsr     serial_puts
    bra     halt

/* d0=pattern, a0=phase name. On fail d2=address, d3=expected, d6=actual. */
run_pattern:
    movem.l %d0/%a0,-(%sp)
    move.l  %d0,%d3
    move.l  #TEST_START,%a3
write_loop:
    move.l  %d3,(%a3)+
    cmpa.l  #TEST_END,%a3
    blo.s   write_loop

    move.l  #TEST_START,%a3
verify_loop:
    cmp.l   (%a3),%d3
    bne.s   pattern_fail
    addq.l  #4,%a3
    cmpa.l  #TEST_END,%a3
    blo.s   verify_loop
    moveq   #0,%d1
    movem.l (%sp)+,%d0/%a0
    rts
pattern_fail:
    move.l  %a3,%d2
    move.l  (%a3),%d6
    moveq   #1,%d1
    movem.l (%sp)+,%d0/%a0
    rts

fail:
    move.l  %a0,%a1
    lea     fault_prefix,%a0
    bsr     serial_puts
    move.l  %a1,%a0
    bsr     serial_puts
    lea     fault_address,%a0
    bsr     serial_puts
    move.l  %d2,%d0
    bsr     serial_put_hex32
    lea     fault_expected,%a0
    bsr     serial_puts
    move.l  %d3,%d0
    bsr     serial_put_hex32
    lea     fault_actual,%a0
    bsr     serial_puts
    move.l  %d6,%d0
    bsr     serial_put_hex32
    lea     crlf,%a0
    bsr     serial_puts
    lea     fail_record,%a0
    bsr     serial_puts

halt:
    stop    #0x2700
    bra.s   halt

serial_put_hex32:
    movem.l %d1-%d3,-(%sp)
    move.l  %d0,%d2
    moveq   #7,%d3
hex_loop:
    rol.l   #4,%d2
    move.l  %d2,%d1
    andi.w  #0x000F,%d1
    cmpi.b  #9,%d1
    ble.s   hex_digit
    addi.b  #('A'-10),%d1
    bra.s   hex_emit
hex_digit:
    addi.b  #'0',%d1
hex_emit:
    move.b  %d1,%d0
    bsr     serial_putc
    dbra    %d3,hex_loop
    movem.l (%sp)+,%d1-%d3
    rts

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

    .section .rodata,"a"
banner:       .asciz "AMIDIAG proto=1 milestone=M2.8 cpu=68000 profile=destructive-a500-512k\r\n"
warning:      .asciz "WARN id=MEM.DESTRUCTIVE status=PASS destructive=1 preserve=0\r\n"
profile:      .asciz "TEST id=MEM.DESTRUCTIVE.PROFILE status=PASS start=0x00008000 end=0x00070000 bytes=425984 patterns=4 destructive=1\r\n"
pass_record:  .asciz "TEST id=MEM.DESTRUCTIVE status=PASS start=0x00008000 end=0x00070000 bytes=425984 patterns=4 destructive=1 final=0x55555555\r\n"
fail_record:  .asciz "TEST id=MEM.DESTRUCTIVE status=FAIL destructive=1\r\n"
fault_prefix: .asciz "FAULT class=MEM test=DESTRUCTIVE phase="
fault_address:.asciz " address=0x"
fault_expected:.asciz " expected=0x"
fault_actual: .asciz " actual=0x"
crlf:         .asciz "\r\n"
phase_zero:   .asciz "ZERO"
phase_ones:   .asciz "ONES"
phase_aa:     .asciz "AA"
phase_55:     .asciz "55"
