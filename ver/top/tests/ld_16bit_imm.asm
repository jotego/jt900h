    maxmode on
    relaxed on
    org 0
    ; check register addressing
    ld wa,0x1234
    ld bc,0x5678
    ld de,0x9abc
    ld hl,0xdef0

    ld ix,0x0123
    ld iy,0x4567
    ld iz,0x89ab
    ld sp,0xcdef
    ld (0xffff),0xff
    end