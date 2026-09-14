CROSS ?= m68k-amigaos-
CC := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
PYTHON ?= python3

BUILD := build
ELF := $(BUILD)/amidiag.elf
ROM := $(BUILD)/amidiag.rom
EXPECTED_512 := tests/m2_7/expected-512.txt
EXPECTED_1024 := tests/m2_7/expected-1024.txt
FAULT_FIXTURE := tests/m2_7/fault-records.txt

ASFLAGS := -m68000 -msoft-float -ffreestanding -fno-builtin -nostdlib -Wall -Wextra
LDFLAGS := -nostdlib -Wl,-T,linker.ld -Wl,-Map,$(BUILD)/amidiag.map

.PHONY: all rom check fsuae-smoke-512 fsuae-smoke-1024 qualify-m2_7 clean

all: rom

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/start.o: src/boot/start.S | $(BUILD)
	$(CC) $(ASFLAGS) -c $< -o $@

$(ELF): $(BUILD)/start.o linker.ld
	$(CC) $(ASFLAGS) $(LDFLAGS) $(BUILD)/start.o -o $@

$(ROM): $(ELF)
	$(OBJCOPY) -O binary $< $@
	truncate -s 524288 $@

rom: $(ROM)

check: rom
	$(PYTHON) tools/check_rom.py $(ROM)
	$(PYTHON) tools/check_serial.py $(EXPECTED_512) --chip-kib 512
	$(PYTHON) tools/check_serial.py $(EXPECTED_1024) --chip-kib 1024
	$(PYTHON) tools/check_fault_record.py $(FAULT_FIXTURE)

fsuae-smoke-512: rom
	CHIP_KIB=512 AMIDIAG_SERIAL_PORT=1234 sh tools/run_fsuae_smoke.sh $(ROM) $(BUILD)/m2_7-512-serial.txt

fsuae-smoke-1024: rom
	CHIP_KIB=1024 AMIDIAG_SERIAL_PORT=1235 sh tools/run_fsuae_smoke.sh $(ROM) $(BUILD)/m2_7-1024-serial.txt

qualify-m2_7: check fsuae-smoke-512 fsuae-smoke-1024
	@echo "PASS: M2.7 host checks, RAM fault reporting, and 512/1024 KiB FS-UAE paths"

clean:
	rm -rf $(BUILD)
