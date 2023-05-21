    ; PUSH<W> #
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xsp, stack
    pushw 0x1234
    ld wa,(xsp)
    cp wa,0x1234
    jp ne, bad_end

    push 0xca
    ld b,(xsp)
    cp b,0xca
    jp ne,bad_end

    ld xde,stack
    sub xde,3
    cp xsp,xde
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
stack:
    end