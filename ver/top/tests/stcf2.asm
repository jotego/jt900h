    ; Store carry flag 2
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ; STCF A,(mem)
    ld a,3
    rcf
    stcf a,(xix)
    ld a,0xf6
    ld w,(xix)
    cp a,(xix)
    jp ne,bad_end
    or ra1,1

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end