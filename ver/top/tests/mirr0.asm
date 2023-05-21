    ; Arithmetic operations that read & write to memory
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld wa,0x0000
    mirr wa
    ld de,wa
    cp wa,0x0000
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end