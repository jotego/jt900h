    ; DAA
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0x80
    add a,10
    daa a
    cp a,0x90
    jp ne,bad_end

    ld a,0x80
    add a,01
    daa a
    cp a,0x81
    jp ne,bad_end

    ld a,0x40
    add a,16
    daa a
    cp a,0x90
    jp eq,bad_end

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