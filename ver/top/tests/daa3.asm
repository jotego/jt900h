    ; DAA
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0x08
    add a,01
    daa a
    cp a,0x09
    jp ne,bad_end

    ld a,0x80
    add a,11
    daa a
    cp a,0x91
    jp ne,bad_end

    ld a,0x40
    add a,36
    daa a
    cp a,0x90
    jp eq,bad_end

    include finish.inc
    align 2
data:
    dw 0xcafe,0xbeef,0x1234,0x5678,0x9abc
    end