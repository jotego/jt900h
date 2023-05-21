    ; PUSH R
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xsp, stack
    ld a,0xfe
    push a
    ld bc,0xbaca
    push bc
    ld xde,0x12345678
    push xde

    ; Check the values
    incf
    ld xde,(xsp)
    cp xde,0x12345678
    jp ne,bad_end
    add xsp,4

    ld bc,(xsp)
    cp bc,0xbaca
    jp ne,bad_end
    add xsp,2

    ld a,(xsp)
    cp a,0xfe
    jp ne,bad_end
    add xsp,1

    cp xsp, stack
    jp ne,bad_end


    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
stack:
    dw 0,0,0,0,0,0,0,0,0,0
    end