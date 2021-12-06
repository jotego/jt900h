#!/bin/bash
make || exit $?
iverilog test.v -f files.f -o sim -DSIMULATION -DEND_RAM=$(cat test.bin|wc -c) && ./sim -lxt
rm -f sim