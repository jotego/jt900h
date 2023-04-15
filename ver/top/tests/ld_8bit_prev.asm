    maxmode on
    relaxed on
    org 0
    ; check register in previous bank
    ld a',0xe0
    ld w',0xe1
    ld c',0xe4
    ld b',0xe5
    ld e',0xe8
    ld d',0xe9
    ld l',0xec
    ld h',0xed

    ld ixl,0xf0
    ld ixh,0xf1
    ld iyl,0xf4
    ld iyh,0xf5
    ld izl,0xf8
    ld izh,0xf9
    ld spl,0xfc
    ld sph,0xfd
    nop
    ld (0xffff),0xff
    end