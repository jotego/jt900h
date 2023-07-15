    ; set/reset/~zero to carry flag
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    jp c,bad_end
    bit 7,a
    scf
    jp nc,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end