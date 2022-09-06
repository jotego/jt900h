#!/bin/bash
FNAME=$1
echo "Running coverage for $FNAME"
covered score -t jt900h -g 2 -vcd $FNAME.vcd -cdd $FNAME.cdd \
	-i test.uut \
	-v ../../hdl/jt900h_ctrl.v \
	-v ../../hdl/jt900h_idxaddr.v \
	-v ../../hdl/jt900h_pc.v \
	-v ../../hdl/jt900h_ramctl.v \
	-v ../../hdl/jt900h_regs.v \
	-v ../../hdl/jt900h_alu.v \
	-v ../../hdl/jt900h_div.v \
	-v ../../hdl/jt900h.v \
	-I ../../hdl
