#!/bin/bash

gcc test_vcd.c ../../model/jt900h.c -I../../model -o sim_vcd && sim_vcd