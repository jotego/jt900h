#!/bin/bash
FAIL=
K=0
ALLTEST=
for i in tests/*.ref; do
    TESTNAME=$(basename $i .ref)
    ALLTEST="$ALLTEST $TESTNAME"
    # figlet "* ${K} *"
    # sim.sh $TESTNAME -batch $* || FAIL="$FAIL $TESTNAME"
    K=$((K+1))
done

parallel --jobs 4 sim.sh {} $* -batch ::: $ALLTEST > runall.log
FAIL=$(grep FAIL runall.log | wc -l)

if [ $FAIL = 0 ]; then
    figlet PASS
else
    echo Some tests failed:
    grep FAIL runall.log
    echo $FAIL
fi