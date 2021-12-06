#!/bin/bash
TEST=ld_8bit_imm

TEST=$(basename $TEST .asm)

if [ ! -e tests/${TEST}.asm ]; then
    echo Cannot find file tests/$TEST
    exit 1
fi

cp tests/${TEST}.asm test.asm
rm -f test.out

make || exit $?

iverilog test.v -f files.f -o sim -DSIMULATION -DEND_RAM=$(cat test.bin|wc -c) && ./sim -lxt
rm -f sim

if sdiff --suppress-common-lines test.out tests/$(basename $TEST .asm).out; then
    echo PASS
else
    echo FAIL
fi