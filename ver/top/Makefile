SHELL := /bin/bash

test.hex: test.bin
	# Add some NOP instructions at the end
	dd bs=16 oflag=append if=/dev/zero of=test.bin conv=notrunc count=1 status=none
	hexdump -v -e "1 / 2 "\"%04X\\n\" test.bin > test.hex

test.bin: test.asm
	# asm900 test.asm
	if ! asl -cpu 96C141 test.asm > asl.log; then cat asl.log; exit 1; fi
	if ! p2bin test.p > p2bin.log; then cat p2bin.log; exit 1; fi
clean:
	rm test.bin