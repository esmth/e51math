PROG = math

.PHONY: all clean ${PROG}
all: ${PROG}

${PROG}: ${PROG}.hex

${PROG}.lst: ${PROG}.asm
	sdas8051 -los ${PROG}.asm

${PROG}.ihx: ${PROG}.lst
	sdld -i ${PROG}

${PROG}.bin: ${PROG}.ihx
	arm-none-eabi-objcopy -I ihex -O binary ${PROG}.ihx ${PROG}.bin

${PROG}.hex: ${PROG}.bin
	arm-none-eabi-objcopy -I binary -O ihex ${PROG}.bin ${PROG}.hex

clean:
	rm -f *.sym *.rel *.lst *.ihx *.hex *.d52 *.bin

