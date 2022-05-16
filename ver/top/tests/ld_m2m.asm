    ; ld<w> (#16),(mem)
    main section code
    org 0
    ld a,0xbf    ; common header
data2 equ 0x700

    ld xix,data

    ; 16-bit write
    ldw (data2),(xix)
    ld wa,(xix)
    cp wa,(data2)
    jp ne,bad_end
    or ra3,1

    ; 8-bit write
    ldb (data2),(xix+2)
    ld b,(xix+2)
    cp b,(data2)
    jp ne,bad_end
    or ra3,2

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