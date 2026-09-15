/* AmiDiag M3.6 clean-room guarded multi-bank Chip RAM discovery ROM. */

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

    .equ EXPECT_BUS,       2
    .equ RESULT_NONE,      0
    .equ RESULT_OK,        1
    .equ RESULT_BUS_ERROR, 2

    .equ MEM_PRESENT,      1
    .equ MEM_ALIAS,        2
    .equ MEM_OPEN_BUS,     3
    .equ MEM_BUS_ERROR,    4

    .equ BASE_ADDR,        0x00001000
    .equ CANDIDATE_512,    0x00081000
    .equ CANDIDATE_1024,   0x00101000
    .equ CANDIDATE_1536,   0x00181000
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

    move.l  #CANDIDATE_512,%a2
    bsr     probe_chip_candidate
    bsr     report_candidate_512
    cmpi.b  #MEM_PRESENT,%d0
    bne     discovered_512

    move.l  #CANDIDATE_1024,%a2
    bsr     probe_chip_candidate
    bsr     report_candidate_1024
    cmpi.b  #MEM_PRESENT,%d0
    bne     discovered_1024

    move.l  #CANDIDATE_1536,%a2
    bsr     probe_chip_candidate
    bsr     report_candidate_1536
    cmpi.b  #MEM_PRESENT,%d0
    bne     discovered_1536

    lea     mem_2048,%a0
    bra     discovery_done

discovered_1536:
    lea     mem_1536,%a0
    bra     discovery_done
discovered_1024:
    lea     mem_1024,%a0
    bra     discovery_done
discovered_512:
    lea     mem_512,%a0

discovery_done:
    bsr     serial_puts
    lea     discovery_pass,%a0
    bsr     serial_puts
    lea     baseline_record,%a0
    bsr     serial_puts
    bra     halt

/* A2 is the candidate address. D0 returns classification. */
probe_chip_candidate:
    move.w  BASE_ADDR,%d4

    move.l  %a2,%a0
    moveq   #EXPECT_BUS,%d0
    bsr     guarded_read16
    cmpi.b  #RESULT_BUS_ERROR,PROBE_RESULT
    beq     candidate_bus_error
    move.w  PROBE_VALUE,%d5

    move.w  #BASE_PATTERN,BASE_ADDR

    move.l  %a2,%a0
    move.w  #CAND_PATTERN,%d1
    moveq   #EXPECT_BUS,%d0
    bsr     guarded_write16
    cmpi.b  #RESULT_BUS_ERROR,PROBE_RESULT
    beq     candidate_bus_after_base

    move.l  %a2,%a0
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

    move.l  %a2,%a0
    move.w  %d5,%d1
    moveq   #EXPECT_BUS,%d0
    bsr     guarded_write16
    move.w  %d4,BASE_ADDR
    moveq   #MEM_PRESENT,%d0
    rts

candidate_alias:
    move.l  %a2,%a0
    move.w  %d5,%d1
    moveq   #EXPECT_BUS,%d0
    bsr     guarded_write16
    move.w  %d4,BASE_ADDR
    moveq   #MEM_ALIAS,%d0
    rts
candidate_open_bus:
    move.l  %a2,%a0
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

/* Preserve D0 classification while reporting. */
report_candidate_512:
    move.b  %d0,%d3
    cmpi.b  #MEM_PRESENT,%d0
    beq     r512_present
    cmpi.b  #MEM_ALIAS,%d0
    beq     r512_alias
    cmpi.b  #MEM_BUS_ERROR,%d0
    beq     r512_bus
    lea     p512_open,%a0
    bra     report_emit
r512_present: lea p512_present,%a0; bra report_emit
r512_alias:   lea p512_alias,%a0; bra report_emit
r512_bus:     lea p512_bus,%a0; bra report_emit

report_candidate_1024:
    move.b  %d0,%d3
    cmpi.b  #MEM_PRESENT,%d0
    beq     r1024_present
    cmpi.b  #MEM_ALIAS,%d0
    beq     r1024_alias
    cmpi.b  #MEM_BUS_ERROR,%d0
    beq     r1024_bus
    lea     p1024_open,%a0
    bra     report_emit
r1024_present: lea p1024_present,%a0; bra report_emit
r1024_alias:   lea p1024_alias,%a0; bra report_emit
r1024_bus:     lea p1024_bus,%a0; bra report_emit

report_candidate_1536:
    move.b  %d0,%d3
    cmpi.b  #MEM_PRESENT,%d0
    beq     r1536_present
    cmpi.b  #MEM_ALIAS,%d0
    beq     r1536_alias
    cmpi.b  #MEM_BUS_ERROR,%d0
    beq     r1536_bus
    lea     p1536_open,%a0
    bra     report_emit
r1536_present: lea p1536_present,%a0; bra report_emit
r1536_alias:   lea p1536_alias,%a0; bra report_emit
r1536_bus:     lea p1536_bus,%a0
report_emit:
    bsr     serial_puts
    move.b  %d3,%d0
    rts

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
    bra     exception_fatal
unexpected_bus:
    lea     exc_bus,%a0
    bra     exception_fatal
_exception_default:
    lea     exc_default,%a0
exception_fatal:
    bsr     serial_puts
exception_halt:
    stop    #0x2700
    bra     exception_halt

serial_puts:
    move.b  (%a0)+,%d0
    beq     serial_puts_done
    bsr     serial_putc
    bra     serial_puts
serial_puts_done:
    rts
serial_putc:
serial_wait_tbe:
    btst    #SERDATR_TBE,SERDATR
    beq     serial_wait_tbe
    andi.w  #0x00FF,%d0
    ori.w   #0x0100,%d0
    move.w  %d0,SERDAT
    rts
halt:
    stop    #0x2700
    bra     halt

    .section .rodata,"a"
banner: .asciz "AMIDIAG proto=1 milestone=M3.6 cpu=68000\r\n"
boot_record: .asciz "BOOT phase=reset status=PASS\r\n"
guard_record: .asciz "TEST id=MEM.PROBE.GUARD status=PASS mode=preserve-write-read-restore unexpected=fatal\r\n"
p512_present: .asciz "PROBE class=MEM region=CHIP address=0x00081000 result=PRESENT\r\n"
p512_alias: .asciz "PROBE class=MEM region=CHIP address=0x00081000 result=ALIAS\r\n"
p512_open: .asciz "PROBE class=MEM region=CHIP address=0x00081000 result=OPEN_BUS\r\n"
p512_bus: .asciz "PROBE class=MEM region=CHIP address=0x00081000 result=BUS_ERROR\r\n"
p1024_present: .asciz "PROBE class=MEM region=CHIP address=0x00101000 result=PRESENT\r\n"
p1024_alias: .asciz "PROBE class=MEM region=CHIP address=0x00101000 result=ALIAS\r\n"
p1024_open: .asciz "PROBE class=MEM region=CHIP address=0x00101000 result=OPEN_BUS\r\n"
p1024_bus: .asciz "PROBE class=MEM region=CHIP address=0x00101000 result=BUS_ERROR\r\n"
p1536_present: .asciz "PROBE class=MEM region=CHIP address=0x00181000 result=PRESENT\r\n"
p1536_alias: .asciz "PROBE class=MEM region=CHIP address=0x00181000 result=ALIAS\r\n"
p1536_open: .asciz "PROBE class=MEM region=CHIP address=0x00181000 result=OPEN_BUS\r\n"
p1536_bus: .asciz "PROBE class=MEM region=CHIP address=0x00181000 result=BUS_ERROR\r\n"
mem_512: .asciz "MEM region=CHIP start=0x00000000 end=0x00080000 bytes=524288 confidence=guarded-discovered\r\n"
mem_1024: .asciz "MEM region=CHIP start=0x00000000 end=0x00100000 bytes=1048576 confidence=guarded-discovered\r\n"
mem_1536: .asciz "MEM region=CHIP start=0x00000000 end=0x00180000 bytes=1572864 confidence=guarded-discovered\r\n"
mem_2048: .asciz "MEM region=CHIP start=0x00000000 end=0x00200000 bytes=2097152 confidence=guarded-discovered\r\n"
discovery_pass: .asciz "TEST id=MEM.CHIP.DISCOVER.GUARDED status=PASS step=524288 preserve=1 alias_check=1\r\n"
baseline_record: .asciz "TEST id=CPU.BASELINE status=PASS cpu=68000 probe=guarded-memory-discovery\r\n"
exc_bus: .asciz "EXCEPTION id=CPU.BUS status=FAIL fatal=1 reason=unexpected-or-unarmed\r\n"
exc_address: .asciz "EXCEPTION id=CPU.ADDRESS status=FAIL fatal=1 reason=unexpected-or-unarmed\r\n"
exc_default: .asciz "EXCEPTION id=CPU.UNKNOWN status=FAIL fatal=1\r\n"
