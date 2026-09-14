CROSS ?= m68k-amigaos-
CC := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
PYTHON ?= python3

BUILD := build
ELF := $(BUILD)/amidiag.elf
ROM := $(BUILD)/amidiag.rom
EXPECTED_SERIAL := tests/m2_1/expected-serial.txt

ASFLAGS := -m68000 -msoft-float -ffreestanding -fno-builtin -nostdlib -Wall -Wextra
LDFLAGS := -nostdlib -Wl,-T,linker.ld -Wl,-Map,$(BUILD)/amidiag.map

.PHONY: all rom check check-transcript fsuae-smoke qualify-m2_1 clean

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
	$(PYTHON) tools/check_serial.py $(EXPECTED_SERIAL)

check-transcript:
	@test -n "$(TRANSCRIPT)" || (echo "TRANSCRIPT=<path> is required" >&2; exit 2)
	$(PYTHON) tools/check_serial.py $(TRANSCRIPT)

fsuae-smoke: rom
	sh tools/run_fsuae_smoke.sh $(ROM) $(BUILD)/m2_1-fsuae-serial.txt

qualify-m2_1: check fsuae-smoke
	@echo "PASS: M2.1 host checks and FS-UAE memory-probe path"

clean:
	rm -rf $(BUILD)
