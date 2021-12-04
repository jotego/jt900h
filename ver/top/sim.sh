#!/bin/bash
make || exit $?
iverilog test.v -f files.f -o sim && sim -lxt
rm -f sim