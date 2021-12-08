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

CODELEN=$(cat test.bin|wc -c)
# The last bytes are NOPs
CODELEN=$((CODELEN-8))

iverilog test.v -f files.f -o sim -DSIMULATION \
    -DEND_RAM=$CODELEN -DHEXLEN=$(cat test.hex|wc -l) || exit $?
./sim -lxt
rm -f sim

CMPFILE=tests/$(basename $TEST .asm).out

if [ ! -e $CMPFILE ]; then
    echo Missing compare file. Run:
    echo -e \\tcp test.out $CMPFILE
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