OBJ := foodmem.bin
INCLUDES := $(wildcard *.asm)

# checkout of https://github.com/fjmilens3/cody-computer
CODY_BASIC ?= ../../../../cody-computer/Spin/codybasic.bin
PLINK_SERIAL ?= /dev/ttyUSB0

# this could also be the path to the compiled executable
CODY_EMULATOR ?= cargo run --release --manifest-path ../../../../cody_emulator/Cargo.toml --
TASS ?= 64tass
PLINK ?= plink

.PHONY: all clean emulator plink

all: $(OBJ)

clean:
	$(RM) *.bin

emulator: all
	$(CODY_EMULATOR) --rom $(CODY_BASIC) --cartridge $(OBJ) --reset-vector 0x0300

plink: all
	$(PLINK) -batch -serial -sercfg "19200,8,1,n,N" $(PLINK_SERIAL) < $(OBJ)

%.bin: %.asm $(INCLUDES)
	$(TASS) --mw65c02 --nostart -o $@ $<
