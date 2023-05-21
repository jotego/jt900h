    ; ei / push SR
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xsp, stack
    ei 1
    push sr
    ld a,(xsp+1)
    cp a,0x98
    jp ne,bad_end

    ei 4
    incf
    push sr
    ld a,(xsp+1)
    cp a,0xc9
    jp ne, bad_end

    ei 2
    incf
    push sr
    ld a,(xsp+1)
    cp a,0xaa
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
stack:
    dw 0,0,0,0,0,0,0,0,0,0
    end