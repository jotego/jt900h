#!/bin/bash
make || exit $?
iverilog test.v ../../hdl/jt900h_ramctl.v -o sim && sim -lxt
rm -f sim