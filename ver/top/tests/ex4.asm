    ; ex
    maxmode on
    relaxed on
    org 0

    ld a,0x34
    ldw (0x0500),0x12
    ld bc,(0x0500)
    ex (0x0500),a
    ld e,(0x0500)

    incf
    ld a,0x34
    ldw (0xffff00),0x12
    ld bc,(0xffff00)
    ex (0xffff00),a
    ld e,(0xffff00)
    decf

    include finish.inc
data:
    dw 0xcafe,0xbeef,0x1234,0x5678,0x9abc
    end