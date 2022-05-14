    ; div rr,# with special register coding
    main section code
    org 0
    ld a,0xbf    ; common header

    ; 16-bit number divided by 8-bit number
    ld ix,37000
    div ix,224
    jp ov,bad_end
    cp ixl,165    ; 0xA5
    jp ne,bad_end
    cp ixh,40     ; 0x28
    jp ne,bad_end
    or ra3,0x1

    ld rwa2,37000
    div rwa2,224
    jp ov,bad_end
    cp ra2,165    ; 0xA5
    jp ne,bad_end
    cp rw2,40     ; 0x28
    jp ne,bad_end
    or ra3,0x2

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
    dw 0xcafe,0xbeef,0x1234,0x5678,0x9abc
    end