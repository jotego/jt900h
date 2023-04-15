    maxmode on
    relaxed on
    org 0
    ld wa,0xbf    ; common header

    ld a,0xff
    ld b,0x00
    ld ixl,0x00
    ld spl,0x00
    ld qixl,0x00
    cp a,ixl
    jp eq,bad_end
    cp a,spl
    jp eq,bad_end
    cp b,qixl
    jp ne,bad_end

    ld ixl,0xff
    ld spl,0xff
    ld qixl,0xff
    cp a,ixl
    jp ne,bad_end
    cp b,spl
    jp eq,bad_end
    cp a,qixl
    jp ne,bad_end
    
    ld ixl,0x00
    ld spl,0x00
    ld qixl,0x00
    cp a,ixl
    jp eq,bad_end
    cp a,spl
    jp eq,bad_end
    cp b,qixl
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