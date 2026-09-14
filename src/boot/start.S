/* AmiDiag M1 bootstrap - clean-room implementation for a 68000-safe baseline. */

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
    /* CPU reset already enters supervisor mode with interrupts masked.
       Clear Amiga overlay before relying on low Chip RAM. */
    bclr    #0,CIAA_PRA
    move.l  #STACK_TOP,%sp

    /* 8-bit receive mode, ~9600 baud for PAL baseline. */
    move.w  #SERPER_9600_PAL,SERPER

    lea     banner,%a0
    bsr     serial_puts
    lea     boot_record,%a0
    bsr     serial_puts
    lea     test_record,%a0
    bsr     serial_puts

halt:
    stop    #0x2700
    bra.s   halt

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
    ori.w   #0x0100,%d0          /* stop bit */
    move.w  %d0,SERDAT
    rts

    .section .rodata,"a"
banner:
    .asciz "AMIDIAG proto=1 milestone=M1 cpu=68000\r\n"
boot_record:
    .asciz "BOOT phase=reset status=PASS\r\n"
test_record:
    .asciz "TEST id=BOOT.SERIAL status=PASS\r\n"
