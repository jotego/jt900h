    maxmode on
    relaxed on
    org 0

    ld xwa,0xffc000
    sll 2,wa
    jp nc,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end