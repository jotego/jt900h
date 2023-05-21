    ; ADD (mem),R
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ; ADD (mem),R
    ld a,1
    add (xix),a
    ld w,(xix)
    cp w,0xff
    jp ne,bad_end
    or ra1,1

    ld a,0
    scf
    adc (xix+2),a
    ld w,(xix+2)
    cp w,0xf0
    jp ne,bad_end
    or ra1,2

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end