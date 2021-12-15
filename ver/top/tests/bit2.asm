    ; jump tests
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    bit 0,(xix) ; 0xfe -> bit 0 = 0
    jp ne,bad_end
    or de,1

    bit 1,(xix)
    jp eq,bad_end
    or de,2


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