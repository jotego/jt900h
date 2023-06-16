    ; ADD (mem),R
    maxmode on
    relaxed on
    org 0

    ld bc,8
    ld qde,bc
    cp xde,0x80000
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end