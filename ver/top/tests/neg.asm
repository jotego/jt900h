    ; Arithmetic operations that read & write to memory
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0x23
    neg a
    add a,0x23
    jp ne,bad_end
    ld bc,1
    neg bc
    cp bc,0xffff
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end