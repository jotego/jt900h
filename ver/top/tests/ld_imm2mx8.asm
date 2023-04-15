    ; ld<w> (#8),#
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,0xf0

    ; 16-bit write
    ldw (0xf0),0x1234
    ld wa,(xix)
    cp wa,0x1234
    jp ne,bad_end
    or ra3,1

    ; 8-bit write
    ldb (0xf0),0xba
    ld b,(xix)
    cp b,0xba
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
data2:
    dw 0x0000,0x0000,0x0000,0x0000,0x0000
    end