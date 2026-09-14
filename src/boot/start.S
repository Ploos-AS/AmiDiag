/* AmiDiag M1.2 bootstrap - clean-room implementation for a 68000-safe baseline. */

    .equ CIAA_PRA,   0x00BFE001
    .equ SERDATR,    0x00DFF018
    .equ SERDAT,     0x00DFF030
    .equ SERPER,     0x00DFF032

    .equ SERDATR_TBE, 13
    .equ SERPER_9600_PAL, 369
    .equ STACK_TOP,  0x0007FFFC

    /* Reset-time vectors are fetched while the Amiga ROM overlay is active. */
    .section .vectors,"a"
    .globl _rom_vectors
_rom_vectors:
    .long STACK_TOP
    .long _rom_reset

    .section .text.boot,"ax"
    .globl _rom_reset
_rom_reset:
    /* Reset enters supervisor mode with interrupts masked. Release the Amiga
       overlay so address zero becomes Chip RAM, then establish our stack. */
    bclr    #0,CIAA_PRA
    move.l  #STACK_TOP,%sp

    /* Direct Paula serial, ~9600 baud for the initial PAL/A500 profile. */
    move.w  #SERPER_9600_PAL,SERPER

    /* 68000 has no movable VBR. Once overlay is released, vectors 0..255 live
       in low Chip RAM. Install a conservative default table before tests run. */
    bsr     install_ram_vectors

    lea     banner,%a0
    bsr     serial_puts
    lea     boot_record,%a0
    bsr     serial_puts
    lea     vector_record,%a0
    bsr     serial_puts
    lea     test_record,%a0
    bsr     serial_puts

#ifdef AMIDIAG_TEST_ILLEGAL
    /* Qualification-only build: prove that the installed vector table and
       fatal exception reporter are actually executable. 0x4AFC is ILLEGAL
       on the 68000 and must enter vector 4. */
    .word   0x4AFC
#endif

halt:
    stop    #0x2700
    bra.s   halt

install_ram_vectors:
    move.l  #_exception_default,%d0
    lea     8,%a1                   /* vector 2 */
    move.w  #253,%d1                /* vectors 2..255 = 254 entries */
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
    /* Fatal exceptions are terminal in M1.2. Later milestones may decode
       exception frames and continue where doing so is demonstrably safe. */
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
    ori.w   #0x0100,%d0          /* stop bit */
    move.w  %d0,SERDAT
    rts

    .section .rodata,"a"
banner:
    .asciz "AMIDIAG proto=1 milestone=M1.2 cpu=68000\r\n"
boot_record:
    .asciz "BOOT phase=reset status=PASS\r\n"
vector_record:
    .asciz "TEST id=BOOT.VECTORS status=PASS\r\n"
test_record:
    .asciz "TEST id=BOOT.SERIAL status=PASS\r\n"

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
