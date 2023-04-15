    maxmode on
    relaxed on
    org 0
    ld wa,0xbf    ; common header

    ld a,0xff
    ld b,0x00
    ld qixh,0x00
    ld qizh,0x00
    ld iyh,0x00
    cp a,qixh
    jp eq,bad_end
    cp a,qizh
    jp eq,bad_end
    cp b,iyh
    jp ne,bad_end

    ld qixh,0xff
    ld qizh,0xff
    ld iyh,0xff
    cp a,qixh
    jp ne,bad_end
    cp b,qizh
    jp eq,bad_end
    cp a,iyh
    jp ne,bad_end

    ld qixh,0x00
    ld qizh,0x00
    ld iyh,0x00
    cp a,qixh
    jp eq,bad_end
    cp a,qizh
    jp eq,bad_end
    cp b,iyh
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