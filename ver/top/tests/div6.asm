    ; div rr,#
    main section code
    org 0
    ld a,0xbf    ; common header

    ; 16-bit number divided by 8-bit number
    ld wa,37000
    div wa,224
    jp ov,bad_end
    cp a,165    ; 0xA5
    jp ne,bad_end
    cp w,40     ; 0x28
    jp ne,bad_end
    or ra3,0x1

    ; 32-bit number divided by 16-bit number
    ld xix,564200
    div xix,7890
    jp ov,bad_end
    or ra3,0x2
    cp ix,71
    jp ne,bad_end
    or ra3,0x4
    cp qix,4010
    jp ne,bad_end
    or ra3,0x8


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