    ; PAA: pointer adjust accumulator
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix, 1
    paa xix
    cp xix,2
    jp ne,bad_end

    ld xiy,10
    paa xiy
    cp xiy,10
    jp ne,bad_end

    ld xiz,0
    paa xiz
    cp xiz,0
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
    end