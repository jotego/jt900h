    maxmode on
    relaxed on
    org 0

    ld xhl,0x200
    ld (xhl+0x34),0xaa
    ld xwa,0xff4a09
    rrcw (xhl+0x34)
    cp xwa,0xff4a09
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end