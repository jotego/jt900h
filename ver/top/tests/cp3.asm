    ; CP (mem),#
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ld (xix),0x10
    ; CP (mem),#8
    cp (xix),0x5
    jp eq,bad_end
    jp c,bad_end
    jp ov,bad_end

    ; CP (mem),#16
    ld qh,1
    ldw (xix+2),0x1234
    scf
    cpw (xix+2),0x2000
    jp eq,bad_end
    jp nc,bad_end
    jp ov,bad_end

    ld qh,2
    ; CP (mem),R
    ld xde,(xix+5)
    inc 2,xde
    cp (xix+5),xde
    jp eq,bad_end
    jp nc,bad_end
    jp ov,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end