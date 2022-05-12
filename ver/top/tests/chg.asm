    ; chg num, dst
    main section code
    org 0
    ld a,0xbf    ; common header

    ; chg #4,r
    ld a,0
    chg 0,a
    chg 2,a
    chg 5,a ; a=0xa5
    chg 7,a
    ld  b,a
    ld  c,a
    sub b,0xa5
    jp ne,bad_end
    or ra3,1

    ; chg #3,(mem)
    incf
    ld xix,data
    ld a,(xix)
    chg 1,(xix)
    ld w,(xix)
    decf
    cp (xix),0xfc
    jp ne,bad_end
    or ra3,2


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