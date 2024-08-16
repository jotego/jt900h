#!/bin/bash

iverilog  -o sim ../../hdl/jt900h_div.v test.v && sim -lxt
rm -f sim