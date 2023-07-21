#!/bin/bash

verilator -I../../hdl ../../hdl/*.v --cc main.cpp --timescale 1ps/1ps -DSIMULATION \
    -GPC_RSTVAL="32'hff0000" --prefix UUT --top-module jt900h -o sim --exe || exit $?

if ! make -j -C obj_dir -f UUT.mk sim > make.log; then
    cat make.log
    exit $?
fi

obj_dir/sim
