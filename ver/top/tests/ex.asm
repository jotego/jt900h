    ; ex
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld wa,0x1234
    ex w,a
    cp wa,0x3412
    jp ne,bad_end
    or ra3,1

    ld bc,wa
    ex b,c
    cp bc,0x1234
    jp ne,bad_end
    or ra3,2

    incf
    ld wa,0x1234
    ld bc,0xfea5
    ex wa,bc
    cp wa,0xfea5
    jp ne,bad_end
    cp bc,0x1234
    jp ne,bad_end
    or ra3,4

    include finish.inc
    align 2
data:
    dw 0xcafe,0xbeef,0x1234,0x5678,0x9abc
    end