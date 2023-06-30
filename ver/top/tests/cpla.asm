    maxmode on
    relaxed on
    org 0

    ld xwa,0x8e80000
    cpl a
    cp xwa,0x8e800ff
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end