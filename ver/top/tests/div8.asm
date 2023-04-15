    ; div rr,# with special register coding
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ; 32-bit number divided by 16-bit number
    ld xwa,0x12345678
    div xwa,(xix)
    jp ov,bad_end
    cp wa,0x16f5
    jp ne,bad_end
    cp qwa,0x3d62
    jp ne,bad_end
    or ra3,0x1

    ; 16-bit number divided by 8-bit number
    ld bc,0x1234
    div bc,(xix)
    jp ov,bad_end
    cp c,0x12
    jp ne,bad_end
    cp b,0x58
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