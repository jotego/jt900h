    ; SET
    main section code
    org 0
    ld a,0xbf    ; common header

    ; SET #4,r
    ld wa,0x54
    set 0,wa
    cp wa,0x55
    jp ne,bad_end

    ld bc,wa
    set 7,bc
    cp bc,0xd5
    jp ne,bad_end

    ; SET #3,(mem)
    incf
    ld xix,data+1
    ld a,(xix)
    cp a,0xca
    jp ne,bad_end

    set 0,(xix)
    ld b,(xix)
    cp b,0xcb
    jp ne,bad_end

    set 4,(xix)
    ld c,(xix)
    cp c,0xdb
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