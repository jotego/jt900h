    ; RES
    main section code
    org 0
    ld a,0xbf    ; common header

    ; RES #4,r
    ld wa,0x55
    res 0,wa
    cp wa,0x54
    jp ne,bad_end

    ld bc,wa
    res 6,bc
    cp bc,0x14
    jp ne,bad_end

    ; RES #3,(mem)
    incf
    ld xix,data
    ld a,(xix)
    cp a,0xfe
    jp ne,bad_end

    res 7,(xix)
    ld b,(xix)
    cp b,0x7e
    jp ne,bad_end

    res 3,(xix)
    ld c,(xix)
    cp c,0x76
    jp ne,bad_end

test_end:
    ; ld (0xffff),0xff
end_loop:
    ldf 0
    ld hl,0xbabe
    jp end_loop
bad_end:
    ld hl,0xdead
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end