/* AmiDiag M3.9 clean-room 68000 supervisor/user-mode diagnostics. */

    .equ CIAA_PRA, 0x00BFE001
    .equ SERDATR,  0x00DFF018
    .equ SERDAT,   0x00DFF030
    .equ SERPER,   0x00DFF032
    .equ SERDATR_TBE, 13
    .equ SERPER_9600_PAL, 369
    .equ STACK_TOP, 0x0007FFFC
    .equ USER_STACK_TOP, 0x00007000
    .equ VECTOR_PRIV, 0x00000020

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

    lea banner,%a0
    bsr serial_puts
    lea boot_record,%a0
    bsr serial_puts

    /* Reset entry must be supervisor mode. */
    move.w %sr,%d0
    btst #13,%d0
    beq fail_supervisor
    lea pass_supervisor,%a0
    bsr serial_puts

    /* Install privilege-violation vector in writable low Chip RAM. */
    move.l #privilege_handler,VECTOR_PRIV

    /* Prepare USP while privileged, then enter user mode by clearing S. */
    move.l #USER_STACK_TOP,%a0
    move.l %a0,%usp
    move.w %sr,%d0
    andi.w #0xDFFF,%d0
    move.w %d0,%sr

user_entry:
    /* Verify we are actually in user mode. */
    move.w %sr,%d0
    btst #13,%d0
    bne fail_user
    lea pass_user,%a0
    bsr serial_puts

    /* STOP is privileged on 68000. In user mode it must vector through #8. */
    stop #0x2000
    bra fail_privilege

after_privilege:
    /* Handler returns here in supervisor mode. */
    move.w %sr,%d0
    btst #13,%d0
    beq fail_recovery
    lea pass_privilege,%a0
    bsr serial_puts
    lea pass_recovery,%a0
    bsr serial_puts
    lea summary_pass,%a0
    bsr serial_puts
    lea baseline_record,%a0
    bsr serial_puts
    bra halt

/* 68000 normal exception frame: SR word followed by PC longword.
 * Do not RTE back to the faulting privileged instruction: discard the frame
 * and continue at a known supervisor-mode continuation.
 */
privilege_handler:
    addq.l #6,%sp
    jmp after_privilege

fail_supervisor:
    lea fail_supervisor_record,%a0
    bra fatal
fail_user:
    lea fail_user_record,%a0
    bra fatal
fail_privilege:
    lea fail_privilege_record,%a0
    bra fatal
fail_recovery:
    lea fail_recovery_record,%a0
fatal:
    bsr serial_puts
    lea summary_fail,%a0
    bsr serial_puts
    bra halt

serial_puts:
    move.b (%a0)+,%d0
    beq serial_puts_done
    bsr serial_putc
    bra serial_puts
serial_puts_done:
    rts
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
banner: .asciz "AMIDIAG proto=1 milestone=M3.9 cpu=68000\r\n"
boot_record: .asciz "BOOT phase=reset status=PASS\r\n"
pass_supervisor: .asciz "TEST id=CPU.MODE.SUPERVISOR status=PASS phase=reset\r\n"
pass_user: .asciz "TEST id=CPU.MODE.USER status=PASS transition=SR.S-clear\r\n"
pass_privilege: .asciz "TEST id=CPU.EXCEPTION.PRIVILEGE status=PASS vector=8 instruction=STOP\r\n"
pass_recovery: .asciz "TEST id=CPU.MODE.RECOVERY status=PASS mode=supervisor\r\n"
summary_pass: .asciz "TEST id=CPU.MODE status=PASS cpu=68000 tests=4\r\n"
baseline_record: .asciz "TEST id=CPU.BASELINE status=PASS cpu=68000 probe=supervisor-user-mode\r\n"
fail_supervisor_record: .asciz "TEST id=CPU.MODE.SUPERVISOR status=FAIL\r\n"
fail_user_record: .asciz "TEST id=CPU.MODE.USER status=FAIL\r\n"
fail_privilege_record: .asciz "TEST id=CPU.EXCEPTION.PRIVILEGE status=FAIL vector=8 instruction=STOP\r\n"
fail_recovery_record: .asciz "TEST id=CPU.MODE.RECOVERY status=FAIL\r\n"
summary_fail: .asciz "TEST id=CPU.MODE status=FAIL cpu=68000\r\n"
