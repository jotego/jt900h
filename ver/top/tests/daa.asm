    ; DAA
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0x10
    add a,9
    daa a
    cp a,0x19
    jp ne,bad_end
    or ra3,1

    ld c,0x13
    add c,9
    daa c
    cp c,0x22
    jp ne,bad_end
    or ra3,2

    ld de,0x99
    add e,1
    daa e
    adc d,0
    cp de,0x100
    jp ne,bad_end
    or ra3,4

    incf
    ld wa,0x200
    sub a,1
    daa a
    sbc w,0
    cp wa,0x199
    jp ne,bad_end
    or ra3,8

    include finish.inc
    align 2
data:
    dw 0xcafe,0xbeef,0x1234,0x5678,0x9abc
    end