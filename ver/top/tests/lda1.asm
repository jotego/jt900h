    ; Some indexed addressing fetching from RAM
    maxmode on
    relaxed on
    org 0

    ; (r32+r8) signed
    ld xwa,0x12345678
    ld e,0x23
    lda xbc,(xwa+e)
    exts de
    exts xde
    add xwa,xde
    cp xbc,xwa
    jp ne,bad_end

    ld xwa,0x12345678
    ld e,-0x23
    lda xbc,(xwa+e)
    exts de
    exts xde
    add xwa,xde
    cp xbc,xwa
    jp ne,bad_end

    ; (r32+r16) signed
    ld xwa,0x12345678
    ld de,0x23
    lda xbc,(xwa+de)
    exts xde
    add xwa,xde
    cp xbc,xwa
    jp ne,bad_end

    ld xwa,0x12345678
    ld de,-0x23
    lda xbc,(xwa+de)
    exts xde
    add xwa,xde
    cp xbc,xwa
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end