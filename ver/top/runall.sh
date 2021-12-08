#!/bin/bash
FAIL=
K=0
for i in tests/*.out; do
    TESTNAME=$(basename $i .out)
    figlet "* ${K} *"
    sim.sh $TESTNAME -nodump || FAIL="$FAIL $TESTNAME"
    K=$((K+1))
done

if [ -z "$FAIL" ]; then
    figlet PASS
else
    echo Some tests failed:
    echo $FAIL
fi