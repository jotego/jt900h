#!/bin/bash

TEST=ld_8bit_imm
EXTRA=
ACCEPT=

# Try linting the code first
cd ../../hdl
verilator --lint-only *.v --top-module jt900h || exit $?
cd -

if [ $# -ge 1 ]; then
    TEST=$1
    echo test: $TEST
    shift
fi

function show_help() {
    cat << EOF
sim.sh <test name> [options]

-nodump     Do not dump waveforms
-accept     Update the valid output file, used for comparisons
            It will also add it to git
-cen        Set cen to 50% (default 100%)
EOF
}

while [ $# -gt 0 ]; do
    case $1 in
        -nodump) EXTRA="$EXTRA -DNODUMP";;
        -accept|-a) ACCEPT=1;;
        -cen) EXTRA="$EXTRA -DUSECEN";;
        -help) show_help; exit 0;;
        *) echo "Unsupported argument $1"; exit 1;;
    esac
    shift
done

TEST=$(basename $TEST .asm)

if [ ! -e tests/${TEST}.asm ]; then
    echo Cannot find file tests/$TEST
    exit 1
fi

cp tests/${TEST}.asm test.asm
rm -f test.out

make --silent || exit $?

CODELEN=$(cat test.bin|wc -c)
# The last bytes are NOPs
CODELEN=$((CODELEN-8))

SIMEXE=sim_${RANDOM}_${RANDOM}

iverilog test.v -f files.f -o $SIMEXE -DSIMULATION $EXTRA \
    -DEND_RAM=$CODELEN -DHEXLEN=$(cat test.hex|wc -l) \
    -I../../hdl || exit $?
./$SIMEXE -lxt
rm -f $SIMEXE

CMPFILE=tests/$(basename $TEST .asm).out

if [ -n "$ACCEPT"  ]; then
    cp test.out $CMPFILE
    git add $CMPFILE tests/${TEST}.asm
    cat test.out
    echo $CMPFILE updated
    exit 0
fi

if [ ! -e $CMPFILE ]; then
    echo Missing compare file. Run:
    echo -e \\tcp test.out $CMPFILE
    cat test.out
    echo FAIL
    exit 1
fi

if sdiff --suppress-common-lines --width=90 test.out $CMPFILE >/dev/null; then
    echo PASS
    exit 0
else
    echo ======== EXPECTED =========
    cat $CMPFILE
    echo ======== BUT GOT ==========
    cat test.out
    echo see $CMPFILE
    echo FAIL
    exit 1
fi