#!/bin/bash
# Random buffer
# dd if=/dev/urandom count=2 | hexdump -v -e "1 / 1 "\"%02X\\n\" > test.hex

iverilog test.v ../../hdl/jt900h_ramctl.v -o sim && sim -lxt
rm -f sim