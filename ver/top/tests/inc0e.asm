    maxmode on
    relaxed on
    org 0

    ld xde,0x808e8
    inc 8,e
    cp xde,0x808f0
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end