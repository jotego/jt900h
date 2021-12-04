test.hex: test.bin
	hexdump -e "1 / 2 "\"%04X\\n\" test.bin > test.hex

test.bin: test.asm
	asm900 test.asm
