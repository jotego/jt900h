    ; TSET
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ; TSET #4,r
    ld a,2
    tset 1,a
    jp z,bad_end
    cp a,2
    jp ne,bad_end

    tset 0,a
    jp nz,bad_end
    cp a,3
    jp ne,bad_end

    ld xix,data
    ld d,4
    ld (xix),d
    tset 0,(xix)
    jp nz,bad_end
    ld d,(xix)
    cp d,5
    jp ne,bad_end

end_loop:
    ldf 0
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end