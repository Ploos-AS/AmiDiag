/* AmiDiag M4.1: clean-room CIA-A/CIA-B safe register-access baseline. */
    .equ CIAA_PRA,  0x00BFE001
    .equ CIAA_DDRA, 0x00BFE201
    .equ CIAB_PRB,  0x00BFD100
    .equ CIAB_DDRB, 0x00BFD300
    .equ SERDATR,   0x00DFF018
    .equ SERDAT,    0x00DFF030
    .equ SERPER,    0x00DFF032
    .equ SERDATR_TBE, 13
    .equ SERPER_9600_PAL, 369
    .equ STACK_TOP, 0x0007FFFC

    .section .vectors,"a"
    .long STACK_TOP
    .long _rom_reset

    .section .text.boot,"ax"
    .globl _rom_reset
_rom_reset:
    /* Release ROM overlay through CIA-A PRA before using low RAM/stack. */
    bclr #0,CIAA_PRA
    move.l #STACK_TOP,%sp
    move.w #SERPER_9600_PAL,SERPER

    lea banner,%a0
    bsr serial_puts
    lea boot_record,%a0
    bsr serial_puts

    /*
     * M4.1 deliberately avoids changing CIA port data.  DDRA/DDRB are
     * writable state suitable for a reversible register-access probe.
     * Toggle only one direction bit, read it back, then restore the exact
     * saved byte.  No external data output bit is modified here.
     */
    move.b CIAA_DDRA,%d2
    move.b %d2,%d0
    eori.b #0x80,%d0
    move.b %d0,CIAA_DDRA
    move.b CIAA_DDRA,%d1
    move.b %d2,CIAA_DDRA
    cmp.b %d0,%d1
    bne ciaa_fail
    cmp.b CIAA_DDRA,%d2
    bne ciaa_restore_fail
    lea ciaa_pass,%a0
    bsr serial_puts
    bra ciab_test
ciaa_fail:
    move.b %d2,CIAA_DDRA
    lea ciaa_fail_record,%a0
    bsr serial_puts
    bra ciab_test
ciaa_restore_fail:
    move.b %d2,CIAA_DDRA
    lea ciaa_restore_fail_record,%a0
    bsr serial_puts

ciab_test:
    move.b CIAB_DDRB,%d2
    move.b %d2,%d0
    eori.b #0x80,%d0
    move.b %d0,CIAB_DDRB
    move.b CIAB_DDRB,%d1
    move.b %d2,CIAB_DDRB
    cmp.b %d0,%d1
    bne ciab_fail
    cmp.b CIAB_DDRB,%d2
    bne ciab_restore_fail
    lea ciab_pass,%a0
    bsr serial_puts
    lea summary_pass,%a0
    bsr serial_puts
    bra halt
ciab_fail:
    move.b %d2,CIAB_DDRB
    lea ciab_fail_record,%a0
    bsr serial_puts
    lea summary_fail,%a0
    bsr serial_puts
    bra halt
ciab_restore_fail:
    move.b %d2,CIAB_DDRB
    lea ciab_restore_fail_record,%a0
    bsr serial_puts
    lea summary_fail,%a0
    bsr serial_puts

halt:
    stop #0x2700
    bra halt

serial_puts:
    move.b (%a0)+,%d0
    beq serial_done
    bsr serial_putc
    bra serial_puts
serial_done:
    rts
serial_putc:
1:  btst #SERDATR_TBE,SERDATR
    beq 1b
    andi.w #0x00FF,%d0
    ori.w #0x0100,%d0
    move.w %d0,SERDAT
    rts

    .section .rodata,"a"
banner: .asciz "AMIDIAG proto=1 milestone=M4.1 cpu=68000\r\n"
boot_record: .asciz "BOOT phase=reset status=PASS\r\n"
ciaa_pass: .asciz "CIAA.ACCESS status=PASS register=DDRA restore=PASS\r\n"
ciaa_fail_record: .asciz "CIAA.ACCESS status=FAIL register=DDRA reason=readback restore=attempted\r\n"
ciaa_restore_fail_record: .asciz "CIAA.ACCESS status=FAIL register=DDRA reason=restore\r\n"
ciab_pass: .asciz "CIAB.ACCESS status=PASS register=DDRB restore=PASS\r\n"
ciab_fail_record: .asciz "CIAB.ACCESS status=FAIL register=DDRB reason=readback restore=attempted\r\n"
ciab_restore_fail_record: .asciz "CIAB.ACCESS status=FAIL register=DDRB reason=restore\r\n"
summary_pass: .asciz "TEST id=CIA.ACCESS status=PASS devices=2 restored=2\r\n"
summary_fail: .asciz "TEST id=CIA.ACCESS status=FAIL\r\n"
