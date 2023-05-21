    maxmode on
    relaxed on
    org 0
    ld wa,0xbf    ; common header

    ld qsph,0x00
    ld qiyh,0x00
    cp a,qiyh
    jp eq,bad_end
    cp a,qsph
    jp eq,bad_end

    ld a,0xff
    ld c,0x01
    ld qsph,0xff
    ld qiyh,0xff
    cp a,qiyh
    jp ne,bad_end
    cp c,qsph
    jp eq,bad_end

    ld qsph,0x00
    ld qiyh,0x00
    cp a,qsph
    jp eq,bad_end
    ld a,0x00
    cp a,qsph
    jp ne,bad_end

    include finish.inc
data:
    dw 0x0000, 0x0000, 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end