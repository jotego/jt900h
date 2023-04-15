    maxmode on
    relaxed on
    org 0
    ld wa,0xbf    ; common header

    ld wa,0xffff
    ld bc,0x0000
    ld iz,0x0000
    ld ix,0x0000
    ld qix,0x0000
    cp wa,iz
    jp eq,bad_end
    cp wa,ix
    jp eq,bad_end
    cp bc,qix
    jp ne,bad_end

    ld iz,0xffff
    ld ix,0xffff
    ld qix,0xffff
    cp wa,iz
    jp ne,bad_end
    cp bc,ix
    jp eq,bad_end
    cp wa,qix
    jp ne,bad_end

    ld iz,0x0000
    ld ix,0x0000
    ld qix,0x0000
    cp wa,iz
    jp eq,bad_end
    cp wa,ix
    jp eq,bad_end
    cp bc,qix
    jp ne,bad_end

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0x0000, 0x0000, 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end