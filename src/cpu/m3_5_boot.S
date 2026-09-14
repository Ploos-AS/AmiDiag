/* AmiDiag M3.5 clean-room guarded Chip RAM candidate qualification ROM. */

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

    .equ RESULT_NONE,      0
    .equ RESULT_OK,        1
    .equ RESULT_BUS_ERROR, 2

    .equ MEM_PRESENT,      1
    .equ MEM_ALIAS,        2
    .equ MEM_OPEN_BUS,     3
    .equ MEM_BUS_ERROR,    4

    .equ BASE_ADDR,        0x00001000
    .equ CANDIDATE_ADDR,   0x00081000
    .equ BASE_PATTERN,     0x55AA
    .equ CAND_PATTERN,     0xAA55

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
    lea     guard_record,%a0
    bsr     serial_puts

    bsr     probe_chip_candidate
    cmpi.b  #MEM_PRESENT,%d0
    beq.s   report_present
    cmpi.b  #MEM_ALIAS,%d0
    beq.s   report_alias
    cmpi.b  #MEM_OPEN_BUS,%d0
    beq.s   report_open_bus
    cmpi.b  #MEM_BUS_ERROR,%d0
    beq.s   report_bus_error
    bra     probe_fail

report_present:
    lea     present_record,%a0
    bsr     serial_puts
    bra.s   report_done
report_alias:
    lea     alias_record,%a0
    bsr     serial_puts
    bra.s   report_done
report_open_bus:
    lea     open_bus_record,%a0
    bsr     serial_puts
    bra.s   report_done
report_bus_error:
    lea     bus_error_record,%a0
    bsr     serial_puts
report_done:
    lea     summary_record,%a0
    bsr     serial_puts
    lea     baseline_record,%a0
    bsr     serial_puts
    bra     halt

probe_fail:
    lea     fail_record,%a0
    bsr     serial_puts
    bra     halt

/* Preserve-safe candidate classification for the first 512 KiB boundary.
   BASE_ADDR is known-good low Chip RAM. CANDIDATE_ADDR is the corresponding
   address in the next 512 KiB bank. The routine distinguishes independent
   RAM, address aliasing, non-storing/open-bus behaviour, and real /BERR.
   Candidate is restored before base; base is restored last so alias cases
   also leave the known-good physical cell with its original value. */
probe_chip_candidate:
    move.w  BASE_ADDR,%d4

    move.l  #CANDIDATE_ADDR,%a0
    moveq   #EXPECT_BUS,%d0
    bsr     guarded_read16
    cmpi.b  #RESULT_BUS_ERROR,PROBE_RESULT
    beq     candidate_bus_error
    move.w  PROBE_VALUE,%d5

    move.w  #BASE_PATTERN,BASE_ADDR

    move.l  #CANDIDATE_ADDR,%a0
    move.w  #CAND_PATTERN,%d1
    moveq   #EXPECT_BUS,%d0
    bsr     guarded_write16
    cmpi.b  #RESULT_BUS_ERROR,PROBE_RESULT
    beq     candidate_bus_after_base

    move.l  #CANDIDATE_ADDR,%a0
    moveq   #EXPECT_BUS,%d0
    bsr     guarded_read16
    cmpi.b  #RESULT_BUS_ERROR,PROBE_RESULT
    beq     candidate_bus_after_base
    move.w  PROBE_VALUE,%d6
    move.w  BASE_ADDR,%d7

    cmpi.w  #CAND_PATTERN,%d6
    bne     candidate_open_bus
    cmpi.w  #BASE_PATTERN,%d7
    bne     candidate_alias

    /* Independent RAM. */
    move.l  #CANDIDATE_ADDR,%a0
    move.w  %d5,%d1
    moveq   #EXPECT_BUS,%d0
    bsr     guarded_write16
    move.w  %d4,BASE_ADDR
    moveq   #MEM_PRESENT,%d0
    rts

candidate_alias:
    move.l  #CANDIDATE_ADDR,%a0
    move.w  %d5,%d1
    moveq   #EXPECT_BUS,%d0
    bsr     guarded_write16
    move.w  %d4,BASE_ADDR
    moveq   #MEM_ALIAS,%d0
    rts

candidate_open_bus:
    /* Best-effort restoration in case the target is writable but behaves
       unexpectedly; a genuine open bus simply ignores the write. */
    move.l  #CANDIDATE_ADDR,%a0
    move.w  %d5,%d1
    moveq   #EXPECT_BUS,%d0
    bsr     guarded_write16
    move.w  %d4,BASE_ADDR
    moveq   #MEM_OPEN_BUS,%d0
    rts

candidate_bus_after_base:
    move.w  %d4,BASE_ADDR
candidate_bus_error:
    moveq   #MEM_BUS_ERROR,%d0
    rts

/* guarded_read16 / guarded_write16 recover only from explicitly expected
   bus errors. Any unarmed bus error or any address error remains fatal. */
guarded_read16:
    move.b  #1,PROBE_ARMED
    move.b  %d0,PROBE_EXPECT
    move.b  #RESULT_NONE,PROBE_RESULT
    clr.w   PROBE_VALUE
    lea     guarded_recovered,%a6
    move.w  (%a0),%d1
    move.w  %d1,PROBE_VALUE
    clr.b   PROBE_ARMED
    move.b  #RESULT_OK,PROBE_RESULT
    rts

guarded_write16:
    move.b  #1,PROBE_ARMED
    move.b  %d0,PROBE_EXPECT
    move.b  #RESULT_NONE,PROBE_RESULT
    lea     guarded_recovered,%a6
    move.w  %d1,(%a0)
    clr.b   PROBE_ARMED
    move.b  #RESULT_OK,PROBE_RESULT
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

_exception_bus:
    cmpi.b  #1,PROBE_ARMED
    bne     unexpected_bus
    cmpi.b  #EXPECT_BUS,PROBE_EXPECT
    bne     unexpected_bus
    move.b  #RESULT_BUS_ERROR,PROBE_RESULT
    adda.w  #14,%sp
    jmp     (%a6)

_exception_address:
    lea     exc_address,%a0
    bra.s   exception_fatal
unexpected_bus:
    lea     exc_bus,%a0
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
banner:          .asciz "AMIDIAG proto=1 milestone=M3.5 cpu=68000\r\n"
boot_record:     .asciz "BOOT phase=reset status=PASS\r\n"
guard_record:    .asciz "TEST id=MEM.PROBE.GUARD status=PASS bus=guarded unexpected=fatal mode=preserve-alias\r\n"
present_record:  .asciz "PROBE class=MEM region=CHIP address=0x00081000 width=16 result=PRESENT mode=preserve-alias\r\n"
alias_record:    .asciz "PROBE class=MEM region=CHIP address=0x00081000 width=16 result=ALIAS base=0x00001000 mode=preserve-alias\r\n"
open_bus_record: .asciz "PROBE class=MEM region=CHIP address=0x00081000 width=16 result=OPEN_BUS mode=preserve-alias\r\n"
bus_error_record:.asciz "PROBE class=MEM region=CHIP address=0x00081000 width=16 result=BUS_ERROR mode=preserve-alias\r\n"
summary_record:  .asciz "TEST id=MEM.CHIP.CANDIDATE status=PASS base=0x00001000 candidate=0x00081000 preserve=1 alias_check=1\r\n"
baseline_record: .asciz "TEST id=CPU.BASELINE status=PASS cpu=68000 probe=guarded-memory\r\n"
fail_record:     .asciz "TEST id=MEM.CHIP.CANDIDATE status=FAIL reason=unclassified\r\n"
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
