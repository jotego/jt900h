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

jtframe ucode --list --gtkwave jt900h 900h
parallel sim.sh {} $* --batch ::: $ALLTEST > runall.log
FAIL=$(grep FAIL runall.log | wc -l)

if [ $FAIL = 0 ]; then
    figlet PASS
    # Merge coverage results
    if which covered >/dev/null; then
        DAY=`date --date='today' +"covered_%d%m%y.txt"`
        YESTERDAY=`date --date='yesterday' +"covered_%d%m%y.txt"`
        covered merge -o merged.cdd tests/*.cdd
        covered exclude -f waivers
        covered report -d d -x merged.cdd > err.txt
        covered report merged.cdd > $DAY
        if [ -e $YESTERDAY ]; then
            sdiff -w 240 $YESTERDAY $DAY > sdiff.txt
        fi
    else
        echo "Install covered to run coverage sims"
    fi
else
    echo Some tests failed:
    grep FAIL runall.log
    echo $FAIL
fi

rm -f tests/*.{p,bin,hex,out}