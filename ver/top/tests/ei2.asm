    ; ei / push SR
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xsp,stack
    ei 2
    push sr
    ld a,(xsp+1)
    cp a,0xa8
    jp ne,bad_end

    ei 7
    incf
    push sr
    ld a,(xsp+1)
    cp a,0xf9
    jp ne,bad_end

    ei 0
    incf
    push sr
    ld a,(xsp+1)
    cp a,0x8a
    jp ne, bad_end
    decf

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
stack:
    dw 0,0,0,0,0,0,0,0,0,0
    end