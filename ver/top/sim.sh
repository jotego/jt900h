#!/bin/bash
TEST=ld_8bit_imm

if [ $# = 1 ]; then
    TEST=$1
    echo test: $1
elif [ $# -gt 1 ]; then
    echo Only the test name can be used as argument
    exit 1
fi

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

CMPFILE=tests/$(basename $TEST .asm).out

if [ ! -e $CMPFILE ]; then
    echo Missing compare file $CMPFILE
    cat test.out
    echo FAIL
    exit 1
fi

if sdiff --suppress-common-lines test.out $CMPFILE; then
    echo PASS
    exit 0
else
    cat test.out
    echo see $CMPFILE
    echo FAIL
    exit 1
fi