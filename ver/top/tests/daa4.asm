    ; DAA
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld b,0x00
    add b,2
    daa b
    cp b,0x09
    jp eq,bad_end

    ld b,0x88
    add b,11
    daa b
    cp b,0x99
    jp ne,bad_end

    ld b,0x00
    add b,02
    daa b
    cp b,0x02
    jp ne,bad_end

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
    align 2
data:
    dw 0xcafe,0xbeef,0x1234,0x5678,0x9abc
    end