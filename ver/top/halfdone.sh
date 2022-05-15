#!/bin/bash
for i in tests/*.asm; do
    if [ ! -e tests/$(basename $i .asm).ref ]; then
        echo $i
    fi
done