    maxmode on
    relaxed on
    org 0
    ld wa,0xbf    ; common header

    ld a,0xff
    ld b,0x00
    ld izh,0x00
    ld qizl,0x00
    ld izl,0x00
    cp a,izh
    jp eq,bad_end
    cp a,qizl
    jp eq,bad_end
    cp b,izl
    jp ne,bad_end

    ld izh,0xff
    ld qizl,0xff
    ld izl,0xff
    cp a,izh
    jp ne,bad_end
    cp b,qizl
    jp eq,bad_end
    cp a,izl
    jp ne,bad_end

    ld izh,0x00
    ld qizl,0x00
    ld izl,0x00
    cp a,izh
    jp eq,bad_end
    cp a,qizl
    jp eq,bad_end
    cp b,izl
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