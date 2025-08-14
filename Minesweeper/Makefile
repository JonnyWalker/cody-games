# \/ do not modify below \/
TASS_COMMON_ARGS	= --mw65c02 --nostart --quiet
TASS_OUTPUT_ARGS	= -o ROM.bin

64TASS				= @64tass ${TASS_COMMON_ARGS} ${TASS_OUTPUT_ARGS}

STYLE_BOLD			= \033[1m
COLOR_GREEN			= \033[0;32m
COLOR_RED			= \033[0;33m
COLOR_RESET			= \033[0m

build:
	${64TASS} sources/executable.asm
	@echo "> $(COLOR_GREEN)successfully assembled ROM.bin$(COLOR_RESET)"

plink:
	${64TASS} sources/executable.asm
	@echo "> $(COLOR_GREEN)successfully assembled ROM.bin$(COLOR_RESET)"
	@echo "> press CTRL + C to terminate"
	@echo "> Make will throw an error; this is expected behaviour"
	@sudo plink -batch -serial -sercfg "19200,8,1,n,N" "/dev/ttyUSB0" < ROM.bin

clean:
	rm -f ROM.bin
	clear
	@echo "> $(COLOR_GREEN)deleted assembler output$(COLOR_RESET)"

.PHONY: build
.PHONY: plink
.PHONY: clean
