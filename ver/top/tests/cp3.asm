    ; CP (mem),#
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ; CP (mem),#8
    ld a,1
    cp (xix),0xfe
    jp ne,bad_end
    or ra3,1

    ; CP (mem),#16
    ld a,0
    scf
    cpw (xix+2),0xbeef
    jp ne,bad_end
    or ra3,2

    ; CP (mem),R
    ld a,(xix+5)
    cp (xix+5),a
    jp ne,bad_end
    or ra3,4

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end