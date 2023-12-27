    ; Some indexed addressing fetching from RAM
    maxmode on
    relaxed on
    org 0

    ; (r32) -any register
    ld xwa3,0x12345678
    lda xbc,(xwa3)
    cp xbc,xwa3
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end