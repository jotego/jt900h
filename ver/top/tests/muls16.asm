    ; Unsigned multiplying (16 bits)
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld wa,0x1223
    ld bc,0xaf56
    muls xwa,bc
    cp xwa,0xfa4904c2
    jp ne,bad_end
    or ra1,1

    ld bc,0xaf56
    muls xbc,wa
    cp xbc,0xfe80372c
    jp ne,bad_end
    or ra1,2

    ld de,0xffff
    muls xde,bc
    cp xde,0xffffc8d4
    jp ne,bad_end
    or ra1,4

    ld hl,0xffff
    muls xhl,hl
    cp xhl,1
    jp ne,bad_end
    or ra1,8

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
    end