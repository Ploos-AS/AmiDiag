CROSS ?= m68k-amigaos-
CC := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
PYTHON ?= python3

BUILD := build
ELF := $(BUILD)/amidiag.elf
ROM := $(BUILD)/amidiag.rom
DESTRUCTIVE_ELF := $(BUILD)/amidiag-destructive.elf
DESTRUCTIVE_ROM := $(BUILD)/amidiag-destructive.rom
M3_1_ELF := $(BUILD)/amidiag-m3_1.elf
M3_1_ROM := $(BUILD)/amidiag-m3_1.rom
M3_2_ELF := $(BUILD)/amidiag-m3_2.elf
M3_2_ROM := $(BUILD)/amidiag-m3_2.rom
M3_3_ELF := $(BUILD)/amidiag-m3_3.elf
M3_3_ROM := $(BUILD)/amidiag-m3_3.rom
EXPECTED_512 := tests/m2_7/expected-512.txt
EXPECTED_1024 := tests/m2_7/expected-1024.txt
FAULT_FIXTURE := tests/m2_7/fault-records.txt

ASFLAGS := -m68000 -msoft-float -ffreestanding -fno-builtin -nostdlib -Wall -Wextra
LDFLAGS := -nostdlib -Wl,-T,linker.ld -Wl,-Map,$(BUILD)/amidiag.map
DESTRUCTIVE_LDFLAGS := -nostdlib -Wl,-T,linker.ld -Wl,-Map,$(BUILD)/amidiag-destructive.map
M3_1_LDFLAGS := -nostdlib -Wl,-T,linker.ld -Wl,-Map,$(BUILD)/amidiag-m3_1.map
M3_2_LDFLAGS := -nostdlib -Wl,-T,linker.ld -Wl,-Map,$(BUILD)/amidiag-m3_2.map
M3_3_LDFLAGS := -nostdlib -Wl,-T,linker.ld -Wl,-Map,$(BUILD)/amidiag-m3_3.map

.PHONY: all rom destructive-rom m3_1-rom m3_2-rom m3_3-rom check check-destructive check-m3_1 check-m3_2 check-m3_3 fsuae-smoke-512 fsuae-smoke-1024 fsuae-destructive fsuae-m3_1 fsuae-m3_2 fsuae-m3_3 qualify-m2_7 qualify-m2_8 qualify-m3_1 qualify-m3_2 qualify-m3_3 clean

all: rom destructive-rom m3_1-rom m3_2-rom m3_3-rom

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/start.o: src/boot/start.S | $(BUILD)
	$(CC) $(ASFLAGS) -c $< -o $@

$(BUILD)/destructive.o: src/boot/destructive.S | $(BUILD)
	$(CC) $(ASFLAGS) -c $< -o $@

$(BUILD)/m3_1_boot.o: src/cpu/m3_1_boot.S | $(BUILD)
	$(CC) $(ASFLAGS) -c $< -o $@

$(BUILD)/m3_2_boot.o: src/cpu/m3_2_boot.S | $(BUILD)
	$(CC) $(ASFLAGS) -c $< -o $@

$(BUILD)/m3_3_boot.o: src/cpu/m3_3_boot.S | $(BUILD)
	$(CC) $(ASFLAGS) -c $< -o $@

$(ELF): $(BUILD)/start.o linker.ld
	$(CC) $(ASFLAGS) $(LDFLAGS) $(BUILD)/start.o -o $@

$(DESTRUCTIVE_ELF): $(BUILD)/destructive.o linker.ld
	$(CC) $(ASFLAGS) $(DESTRUCTIVE_LDFLAGS) $(BUILD)/destructive.o -o $@

$(M3_1_ELF): $(BUILD)/m3_1_boot.o linker.ld
	$(CC) $(ASFLAGS) $(M3_1_LDFLAGS) $(BUILD)/m3_1_boot.o -o $@

$(M3_2_ELF): $(BUILD)/m3_2_boot.o linker.ld
	$(CC) $(ASFLAGS) $(M3_2_LDFLAGS) $(BUILD)/m3_2_boot.o -o $@

$(M3_3_ELF): $(BUILD)/m3_3_boot.o linker.ld
	$(CC) $(ASFLAGS) $(M3_3_LDFLAGS) $(BUILD)/m3_3_boot.o -o $@

$(ROM): $(ELF)
	$(OBJCOPY) -O binary $< $@
	truncate -s 524288 $@

$(DESTRUCTIVE_ROM): $(DESTRUCTIVE_ELF)
	$(OBJCOPY) -O binary $< $@
	truncate -s 524288 $@

$(M3_1_ROM): $(M3_1_ELF)
	$(OBJCOPY) -O binary $< $@
	truncate -s 524288 $@

$(M3_2_ROM): $(M3_2_ELF)
	$(OBJCOPY) -O binary $< $@
	truncate -s 524288 $@

$(M3_3_ROM): $(M3_3_ELF)
	$(OBJCOPY) -O binary $< $@
	truncate -s 524288 $@

rom: $(ROM)
destructive-rom: $(DESTRUCTIVE_ROM)
m3_1-rom: $(M3_1_ROM)
m3_2-rom: $(M3_2_ROM)
m3_3-rom: $(M3_3_ROM)

check: rom
	$(PYTHON) tools/check_rom.py $(ROM)
	$(PYTHON) tools/check_serial.py $(EXPECTED_512) --chip-kib 512
	$(PYTHON) tools/check_serial.py $(EXPECTED_1024) --chip-kib 1024
	$(PYTHON) tools/check_fault_record.py $(FAULT_FIXTURE)

check-destructive: destructive-rom
	$(PYTHON) tools/check_destructive_rom.py $(DESTRUCTIVE_ROM)

check-m3_1: m3_1-rom
	$(PYTHON) tools/check_m3_1_rom.py $(M3_1_ROM)

check-m3_2: m3_2-rom
	$(PYTHON) tools/check_m3_2_rom.py $(M3_2_ROM)

check-m3_3: m3_3-rom
	$(PYTHON) tools/check_m3_3_rom.py $(M3_3_ROM)

fsuae-smoke-512: rom
	CHIP_KIB=512 AMIDIAG_SERIAL_PORT=1234 sh tools/run_fsuae_smoke.sh $(ROM) $(BUILD)/m2_7-512-serial.txt

fsuae-smoke-1024: rom
	CHIP_KIB=1024 AMIDIAG_SERIAL_PORT=1235 sh tools/run_fsuae_smoke.sh $(ROM) $(BUILD)/m2_7-1024-serial.txt

fsuae-destructive: destructive-rom
	AMIDIAG_SERIAL_PORT=1236 sh tools/run_fsuae_destructive.sh $(DESTRUCTIVE_ROM) $(BUILD)/m2_8-destructive-serial.txt

fsuae-m3_1: m3_1-rom
	AMIDIAG_SERIAL_PORT=1237 sh tools/run_fsuae_m3_1.sh $(M3_1_ROM) $(BUILD)/m3_1-serial.txt

fsuae-m3_2: m3_2-rom
	AMIDIAG_SERIAL_PORT=1238 sh tools/run_fsuae_m3_2.sh $(M3_2_ROM) $(BUILD)/m3_2-serial.txt

fsuae-m3_3: m3_3-rom
	AMIDIAG_SERIAL_PORT=1239 sh tools/run_fsuae_m3_3.sh $(M3_3_ROM) $(BUILD)/m3_3-serial.txt

qualify-m2_7: check fsuae-smoke-512 fsuae-smoke-1024
	@echo "PASS: M2.7 host checks, RAM fault reporting, and 512/1024 KiB FS-UAE paths"

qualify-m2_8: check check-destructive fsuae-smoke-512 fsuae-smoke-1024 fsuae-destructive
	@echo "PASS: M2.8 preserve-safe baseline plus opt-in destructive A500/512K FS-UAE profile"

qualify-m3_1: check-m3_1 fsuae-m3_1
	@echo "PASS: M3.1 68000 recoverable TRAP0 exception frame capture and RTE round-trip"

qualify-m3_2: check-m3_2 fsuae-m3_2
	@echo "PASS: M3.2 68000 address-error frame capture and controlled recovery"

qualify-m3_3: check-m3_3 fsuae-m3_3
	@echo "PASS: M3.3 68000 bus-error frame capture and controlled recovery"

clean:
	rm -rf $(BUILD)
