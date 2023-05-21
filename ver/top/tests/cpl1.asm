    ; CPL
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header


    ld wa,0xffff
    cpl wa
    cp wa,0x0000
    jp ne,bad_end

    ld de,0x0000
    cpl de
    cp de,0xffff
    jp ne,bad_end

    ld bc,0x0000
    extz bc
    cp bc,0
    jp ne,bad_end

    ld xbc,0x00000000
    extz xbc
    cp xbc,0
    jp ne,bad_end

    incf

    ld bc,0xff80
    extz bc
    cp bc,0x0080
    jp ne,bad_end

    ld xhl,0x12348000
    extz xhl
    cp xhl,0x00008000
    jp ne,bad_end

    decf

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end