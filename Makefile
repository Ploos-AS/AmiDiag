CROSS ?= m68k-amigaos-
CC := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
PYTHON ?= python3

BUILD := build
ELF := $(BUILD)/amidiag.elf
ROM := $(BUILD)/amidiag.rom
EXPECTED_SERIAL := tests/m1_1/expected-serial.txt

ASFLAGS := -m68000 -msoft-float -ffreestanding -fno-builtin -nostdlib -Wall -Wextra
LDFLAGS := -nostdlib -Wl,-T,linker.ld -Wl,-Map,$(BUILD)/amidiag.map

.PHONY: all rom check check-transcript clean

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

# Use after an emulator or real machine has captured a serial transcript:
#   make check-transcript TRANSCRIPT=build/m1_1-serial.txt
check-transcript:
	@test -n "$(TRANSCRIPT)" || (echo "TRANSCRIPT=<path> is required" >&2; exit 2)
	$(PYTHON) tools/check_serial.py $(TRANSCRIPT)

clean:
	rm -rf $(BUILD)
