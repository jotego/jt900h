    ; CPL
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ld b,0xfe
    cp b,(xix)
    jp ne,bad_end

    ld qh,1
    ld b,0xca
    cp b,(xix+1)
    jp ne,bad_end

    ld qh,2
    ld a,0x10
    cp a,9
    jp eq,bad_end
    jp c,bad_end
    jp ov,bad_end
    jp mi,bad_end

    ld qh,3
    ld wa,0x1023
    cp wa,0x2000
    jp eq,bad_end
    jp nc,bad_end
    jp ov,bad_end
    jp pl,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end