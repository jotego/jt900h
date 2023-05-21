    ; CPL
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld de,0x5555
    cpl de
    ld wa,0xaaaa
    sub wa,de
    jp ne,bad_end

    incf
    ld de,0x55be
    cpl d
    nop
    nop
    ld a,0xaa
    sub a,d
    decf
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end