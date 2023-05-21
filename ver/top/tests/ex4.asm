    ; ex
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0x34
    ld (0x0500),0x12
    ld bc,(0x0500)
    ex (0x0500),a
    ld e,(0x0500)

    incf
    ld a,0x34
    ld (0xffffff),0x12
    ld bc,(0xffffff)
    ex (0xffffff),a
    ld e,(0xffffff)
    decf

    include finish.inc
data:
    dw 0xcafe,0xbeef,0x1234,0x5678,0x9abc
    end