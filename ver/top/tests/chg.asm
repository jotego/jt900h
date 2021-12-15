    ; chg on a register
    main section code
    org 0
    ld a,0xbf    ; common header

    ld a,0
    chg 0,a
    chg 2,a
    chg 5,a ; a=0xa5
    chg 7,a
    ld  b,a
    ld  c,a
    sub b,0xa5
    jp ne,bad_end

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end