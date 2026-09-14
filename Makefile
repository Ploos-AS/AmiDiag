CROSS ?= m68k-amigaos-
CC := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
PYTHON ?= python3

BUILD := build
ELF := $(BUILD)/amidiag.elf
ROM := $(BUILD)/amidiag.rom
EXC_ELF := $(BUILD)/amidiag-exception.elf
EXC_ROM := $(BUILD)/amidiag-exception.rom
EXPECTED_SERIAL := tests/m1_1/expected-serial.txt

ASFLAGS := -m68000 -msoft-float -ffreestanding -fno-builtin -nostdlib -Wall -Wextra
LDFLAGS := -nostdlib -Wl,-T,linker.ld -Wl,-Map,$(BUILD)/amidiag.map

.PHONY: all rom exception-rom check check-transcript fsuae-smoke clean

all: rom

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/start.o: src/boot/start.S | $(BUILD)
	$(CC) $(ASFLAGS) -c $< -o $@

$(BUILD)/start-exception.o: src/boot/start.S | $(BUILD)
	$(CC) $(ASFLAGS) -DAMIDIAG_TEST_ILLEGAL=1 -c $< -o $@

$(ELF): $(BUILD)/start.o linker.ld
	$(CC) $(ASFLAGS) $(LDFLAGS) $(BUILD)/start.o -o $@

$(EXC_ELF): $(BUILD)/start-exception.o linker.ld
	$(CC) $(ASFLAGS) -nostdlib -Wl,-T,linker.ld -Wl,-Map,$(BUILD)/amidiag-exception.map $(BUILD)/start-exception.o -o $@

$(ROM): $(ELF)
	$(OBJCOPY) -O binary $< $@
	truncate -s 524288 $@

$(EXC_ROM): $(EXC_ELF)
	$(OBJCOPY) -O binary $< $@
	truncate -s 524288 $@

rom: $(ROM)

exception-rom: $(EXC_ROM)

check: rom exception-rom
	$(PYTHON) tools/check_rom.py $(ROM)
	$(PYTHON) tools/check_rom.py $(EXC_ROM)
	$(PYTHON) tools/check_serial.py $(EXPECTED_SERIAL)

# Use after an emulator or real machine has captured a serial transcript:
#   make check-transcript TRANSCRIPT=build/m1_2-serial.txt
check-transcript:
	@test -n "$(TRANSCRIPT)" || (echo "TRANSCRIPT=<path> is required" >&2; exit 2)
	$(PYTHON) tools/check_serial.py $(TRANSCRIPT)

# Requires FS-UAE available on the host. Override FS_UAE with a wrapper when
# necessary, e.g. FS_UAE='xvfb-run -a fs-uae'.
fsuae-smoke: rom
	sh tools/run_fsuae_smoke.sh $(ROM) $(BUILD)/m1_2-fsuae-serial.txt

clean:
	rm -rf $(BUILD)
