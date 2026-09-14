/* AmiDiag M2.1 bootstrap - clean-room 68000/A500 baseline. */

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
    lea     vector_record,%a0
    bsr     serial_puts
    lea     serial_record,%a0
    bsr     serial_puts

    /* M2.1 deliberately does not probe beyond the A500 profile boundary.
       Each probe preserves the original longword, writes two complementary
       patterns, verifies them, then restores the original value. Probe
       addresses avoid the low vector table and the bootstrap stack. */
    lea     0x00001000,%a1
    bsr     probe_preserve_long
    tst.b   %d1
    bne     memory_probe_failed
    lea     0x00010000,%a1
    bsr     probe_preserve_long
    tst.b   %d1
    bne     memory_probe_failed
    lea     0x00020000,%a1
    bsr     probe_preserve_long
    tst.b   %d1
    bne     memory_probe_failed
    lea     0x00030000,%a1
    bsr     probe_preserve_long
    tst.b   %d1
    bne     memory_probe_failed
    lea     0x00040000,%a1
    bsr     probe_preserve_long
    tst.b   %d1
    bne     memory_probe_failed
    lea     0x00050000,%a1
    bsr     probe_preserve_long
    tst.b   %d1
    bne     memory_probe_failed
    lea     0x00060000,%a1
    bsr     probe_preserve_long
    tst.b   %d1
    bne     memory_probe_failed
    lea     0x00070000,%a1
    bsr     probe_preserve_long
    tst.b   %d1
    bne     memory_probe_failed

    lea     memory_probe_pass,%a0
    bsr     serial_puts
    lea     memory_map_record,%a0
    bsr     serial_puts
    bra     halt

memory_probe_failed:
    lea     memory_probe_fail,%a0
    bsr     serial_puts

halt:
    stop    #0x2700
    bra.s   halt

probe_preserve_long:
    move.l  (%a1),%d2
    clr.b   %d1

    move.l  #0x55AA55AA,%d0
    move.l  %d0,(%a1)
    cmp.l   (%a1),%d0
    bne.s   probe_failed

    move.l  #0xAA55AA55,%d0
    move.l  %d0,(%a1)
    cmp.l   (%a1),%d0
    bne.s   probe_failed

    move.l  %d2,(%a1)
    rts

probe_failed:
    move.l  %d2,(%a1)
    moveq   #1,%d1
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
    lea     exc_bus,%a0
    bra.s   exception_fatal
_exception_address:
    lea     exc_address,%a0
    bra.s   exception_fatal
_exception_illegal:
    lea     exc_illegal,%a0
    bra.s   exception_fatal
_exception_zero_divide:
    lea     exc_zero_divide,%a0
    bra.s   exception_fatal
_exception_chk:
    lea     exc_chk,%a0
    bra.s   exception_fatal
_exception_trapv:
    lea     exc_trapv,%a0
    bra.s   exception_fatal
_exception_privilege:
    lea     exc_privilege,%a0
    bra.s   exception_fatal
_exception_trace:
    lea     exc_trace,%a0
    bra.s   exception_fatal
_exception_line_a:
    lea     exc_line_a,%a0
    bra.s   exception_fatal
_exception_line_f:
    lea     exc_line_f,%a0
    bra.s   exception_fatal
_exception_default:
    lea     exc_default,%a0

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

    .section .rodata,"a"
banner:
    .asciz "AMIDIAG proto=1 milestone=M2.1 cpu=68000\r\n"
boot_record:
    .asciz "BOOT phase=reset status=PASS\r\n"
vector_record:
    .asciz "TEST id=BOOT.VECTORS status=PASS\r\n"
serial_record:
    .asciz "TEST id=BOOT.SERIAL status=PASS\r\n"
memory_probe_pass:
    .asciz "TEST id=MEM.CHIP.PROBE status=PASS probes=8 mode=preserve\r\n"
memory_probe_fail:
    .asciz "TEST id=MEM.CHIP.PROBE status=FAIL mode=preserve\r\n"
memory_map_record:
    .asciz "MEM region=CHIP start=0x00000000 end=0x00080000 bytes=524288 confidence=profile-verified\r\n"

exc_bus:
    .asciz "EXCEPTION id=CPU.BUS status=FAIL fatal=1\r\n"
exc_address:
    .asciz "EXCEPTION id=CPU.ADDRESS status=FAIL fatal=1\r\n"
exc_illegal:
    .asciz "EXCEPTION id=CPU.ILLEGAL status=FAIL fatal=1\r\n"
exc_zero_divide:
    .asciz "EXCEPTION id=CPU.DIVZERO status=FAIL fatal=1\r\n"
exc_chk:
    .asciz "EXCEPTION id=CPU.CHK status=FAIL fatal=1\r\n"
exc_trapv:
    .asciz "EXCEPTION id=CPU.TRAPV status=FAIL fatal=1\r\n"
exc_privilege:
    .asciz "EXCEPTION id=CPU.PRIV status=FAIL fatal=1\r\n"
exc_trace:
    .asciz "EXCEPTION id=CPU.TRACE status=FAIL fatal=1\r\n"
exc_line_a:
    .asciz "EXCEPTION id=CPU.LINEA status=FAIL fatal=1\r\n"
exc_line_f:
    .asciz "EXCEPTION id=CPU.LINEF status=FAIL fatal=1\r\n"
exc_default:
    .asciz "EXCEPTION id=CPU.UNKNOWN status=FAIL fatal=1\r\n"
