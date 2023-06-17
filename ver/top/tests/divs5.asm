    maxmode on
    relaxed on
    org 0

    ld xix,0xfffb9e5e ; -287130
    ld xiz,0x20900    ; iz = 0x900 = -1792
    ; 287138/1792 = 160 . remainder = 418
    divs xix,iz
    cp xix,0xfa5eff84
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end