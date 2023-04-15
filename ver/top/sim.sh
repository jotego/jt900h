#!/bin/bash

TEST=
EXTRA=
ACCEPT=
RAM=0
BATCH=0
VERBOSE=0
COVERAGE=0
NODUMP=

function show_help() {
    cat << EOF
sim.sh <test name> [options]

--nodump        Do not dump waveforms
--batch         Do not use test.* filenames (batch mode)
--accept, -a    Update the valid output file, used for comparisons
                It will also add it to git
--cen           Set cen to 50% (default 100%)
--ram           Shows a short RAM dump before and after the simulation
--cov           Runs coverage. Requires 'covered' installed
--verbose,-v    Verbose
--help,   -h    Help
EOF
}

if [ $# -ge 1 ]; then
    TEST=$1
    echo test: $TEST
    shift
else
    show_help
    exit 1
fi

# Try linting the code first
cd ../../hdl
verilator --lint-only *.v --top-module jt900h || exit $?
cd -

while [ $# -gt 0 ]; do
    case $1 in
        --nodump) NODUMP=-DNODUMP;;
        --batch|-b) NODUMP=-DNODUMP; BATCH=1;;
        --accept|-a) ACCEPT=1;;
        --ram) RAM=1;;
        --cen) EXTRA="$EXTRA -DUSECEN";;
        --cov) COVERAGE=1;;
        -v|--verbose) VERBOSE=1;;
        --help|-h) show_help; exit 0;;
        *) >&2 echo "Unsupported argument $1"; exit 1;;
    esac
    shift
done

if [ $COVERAGE = 1 ]; then
    NODUMP=
fi

TEST=$(basename $TEST .asm)
EXTRA="$EXTRA $NODUMP"

if [ ! -e tests/${TEST}.asm ]; then
    echo Cannot find file tests/$TEST
    exit 1
fi

if [ $BATCH = 0 ]; then
    cp tests/${TEST}.asm test.asm
    rm -f test.out

    make --silent || exit $?
    FNAME=test
else
    # Always re-assemble the files
    cd tests
    # asm900 ${TEST}.asm || exit $?
    # dd bs=16 oflag=append if=/dev/zero of=${TEST}.bin conv=notrunc count=1 status=none
    if ! asl -cpu 96C141 ${TEST}.asm -l > ${TEST}-asl.log; then cat ${TEST}-asl.log; exit 1; fi
    if ! p2bin ${TEST}.p > ${TEST}-p2bin.log; then cat ${TEST}-p2bin.log; exit 1; fi
    # rm -f ${TEST}-{asl,p2bin}.log
    hexdump -v -e "1 / 2 "\"%04X\\n\" ${TEST}.bin > ${TEST}.hex
    cd ..
    FNAME=tests/$TEST
fi

CODELEN=$(cat ${FNAME}.bin|wc -c)
# The last bytes are NOPs
CODELEN=$((CODELEN-8))

SIMEXE=sim_$TEST

if [ $RAM = 1 ]; then
    xxd ${FNAME}.bin | head
fi

iverilog test.v -f files.f -o $SIMEXE -DSIMULATION $EXTRA \
    -DEND_RAM=$CODELEN -DHEXLEN=$(cat ${FNAME}.hex|wc -l) \
    -DFNAME=\"$FNAME\" \
    -I../../hdl || exit $?
./$SIMEXE -lxt
rm -f $SIMEXE

if [ $RAM = 1 ]; then
    xxd mem.bin | head
fi

CMPFILE=tests/$(basename $TEST .asm).ref

if [ -n "$ACCEPT"  ]; then
    cp ${FNAME}.out $CMPFILE
    git add $CMPFILE tests/${TEST}.asm
    cat ${FNAME}.out
    echo $CMPFILE updated
    exit 0
fi

if [ ! -e $CMPFILE ]; then
    echo Missing compare file. Run:
    echo -e \\tcp ${FNAME}.out $CMPFILE
    cat ${FNAME}.out
    echo FAIL
    exit 1
fi

if sdiff --suppress-common-lines --width=90 ${FNAME}.out $CMPFILE >/dev/null; then
    echo $FNAME PASS
    if [ $COVERAGE = 1 ]; then
        coverage.sh $FNAME
    fi
    if [ $VERBOSE = 1 ]; then
        cat $FNAME.out
    fi
    exit 0
else
    if [ $BATCH = 0 ]; then
        echo ======== EXPECTED =========
        cat $CMPFILE
        echo ======== BUT GOT ==========
        cat $FNAME.out
        echo see $CMPFILE
    fi
    echo $FNAME FAIL
    exit 1
fi