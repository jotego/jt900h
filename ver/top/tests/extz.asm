    ; CPL
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xwa,0x12345678
    extz wa
    sub wa,0x78
    jp ne,bad_end

    or b,1
    ld xde,0x87654321
    extz xde
    sub xde,0x4321
    jp ne,bad_end

    or b,2

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end