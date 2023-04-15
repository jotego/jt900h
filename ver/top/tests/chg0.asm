    ; chg num, dst
    main section code
    org 0
    ld a,0xbf    ; common header

    ; chg #3,(mem)
    ld xix,0x00000000
    ld a,(xix)
    chg 1,(xix)
    ld w,(xix)
    cp (xix),0xfc
    jp eq,bad_end
    or ra3,2

    ; chg #3,(mem)
    incf
    ld xiy,(0x00)
    ld a,(xiy)
    chg 0,(xiy)
    ld w,(xiy)
    cp (xiy),0xfc
    jp eq,bad_end
    or ra3,2
    decf

end_loop:
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