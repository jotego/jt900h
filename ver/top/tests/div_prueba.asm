    ; div RR,r
    main section code
    org 0
    ld a,0xbf    ; common header

    ld sp,0xffff
    div wa,a

    div wa,14

    ld sp,0x0488
    div wa,(data)

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