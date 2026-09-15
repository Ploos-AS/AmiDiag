/* AmiDiag M3.8 clean-room 68000 instruction sanity diagnostics. */

    .equ CIAA_PRA, 0x00BFE001
    .equ SERDATR,  0x00DFF018
    .equ SERDAT,   0x00DFF030
    .equ SERPER,   0x00DFF032
    .equ SERDATR_TBE, 13
    .equ SERPER_9600_PAL, 369
    .equ STACK_TOP, 0x0007FFFC
    /* Fixed low Chip RAM scratch, consistent with the M3 guarded-probe state area. */
    .equ SCRATCH_ADDR, 0x00003020

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

    /* MOVE / register data path. */
    move.l #0x12345678,%d0
    move.l %d0,%d1
    cmp.l %d0,%d1
    bne fail_move
    lea pass_move,%a0
    bsr serial_puts

    /* ADD/SUB arithmetic. */
    moveq #17,%d0
    moveq #25,%d1
    add.l %d1,%d0
    cmpi.l #42,%d0
    bne fail_add
    subi.l #12,%d0
    cmpi.l #30,%d0
    bne fail_add
    lea pass_add,%a0
    bsr serial_puts

    /* AND/OR/EOR logical unit. */
    move.l #0x55AA55AA,%d0
    andi.l #0x0FF00FF0,%d0
    cmpi.l #0x05A005A0,%d0
    bne fail_logic
    ori.l #0xA0000005,%d0
    cmpi.l #0xA5A005A5,%d0
    bne fail_logic
    eori.l #0xFFFFFFFF,%d0
    cmpi.l #0x5A5FFA5A,%d0
    bne fail_logic
    lea pass_logic,%a0
    bsr serial_puts

    /* Shift/rotate datapath. */
    moveq #1,%d0
    lsl.l #4,%d0
    cmpi.l #16,%d0
    bne fail_shift
    lsr.l #2,%d0
    cmpi.l #4,%d0
    bne fail_shift
    rol.l #1,%d0
    cmpi.l #8,%d0
    bne fail_shift
    lea pass_shift,%a0
    bsr serial_puts

    /* Condition codes + conditional branch. */
    moveq #5,%d0
    cmpi.l #5,%d0
    bne fail_cc
    moveq #-1,%d0
    tst.l %d0
    bpl fail_cc
    moveq #0,%d0
    tst.l %d0
    bne fail_cc
    lea pass_cc,%a0
    bsr serial_puts

    /* Address-register arithmetic and memory round-trip in safe Chip RAM. */
    move.l #SCRATCH_ADDR,%a0
    move.l #0xCAFEBABE,(%a0)
    move.l (%a0),%d0
    cmpi.l #0xCAFEBABE,%d0
    bne fail_addr
    lea pass_addr,%a0
    bsr serial_puts

    lea summary_pass,%a0
    bsr serial_puts
    lea baseline_record,%a0
    bsr serial_puts
    bra halt

fail_move:  lea fail_move_record,%a0;  bra fatal
fail_add:   lea fail_add_record,%a0;   bra fatal
fail_logic: lea fail_logic_record,%a0; bra fatal
fail_shift: lea fail_shift_record,%a0; bra fatal
fail_cc:    lea fail_cc_record,%a0;    bra fatal
fail_addr:  lea fail_addr_record,%a0
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
banner: .asciz "AMIDIAG proto=1 milestone=M3.8 cpu=68000\r\n"
boot_record: .asciz "BOOT phase=reset status=PASS\r\n"
pass_move: .asciz "TEST id=CPU.INSTR.MOVE status=PASS width=32\r\n"
pass_add: .asciz "TEST id=CPU.INSTR.ARITH status=PASS ops=ADD,SUB width=32\r\n"
pass_logic: .asciz "TEST id=CPU.INSTR.LOGIC status=PASS ops=AND,OR,EOR width=32\r\n"
pass_shift: .asciz "TEST id=CPU.INSTR.SHIFT status=PASS ops=LSL,LSR,ROL width=32\r\n"
pass_cc: .asciz "TEST id=CPU.INSTR.CCR status=PASS flags=Z,N branches=BEQ,BNE,BPL\r\n"
pass_addr: .asciz "TEST id=CPU.INSTR.ADDRESS status=PASS mode=indirect width=32\r\n"
summary_pass: .asciz "TEST id=CPU.INSTR.SANITY status=PASS cpu=68000 tests=6\r\n"
baseline_record: .asciz "TEST id=CPU.BASELINE status=PASS cpu=68000 probe=instruction-sanity\r\n"
fail_move_record: .asciz "TEST id=CPU.INSTR.MOVE status=FAIL\r\n"
fail_add_record: .asciz "TEST id=CPU.INSTR.ARITH status=FAIL\r\n"
fail_logic_record: .asciz "TEST id=CPU.INSTR.LOGIC status=FAIL\r\n"
fail_shift_record: .asciz "TEST id=CPU.INSTR.SHIFT status=FAIL\r\n"
fail_cc_record: .asciz "TEST id=CPU.INSTR.CCR status=FAIL\r\n"
fail_addr_record: .asciz "TEST id=CPU.INSTR.ADDRESS status=FAIL\r\n"
summary_fail: .asciz "TEST id=CPU.INSTR.SANITY status=FAIL cpu=68000\r\n"
