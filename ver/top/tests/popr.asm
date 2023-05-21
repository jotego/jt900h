    ; POP r
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xsp, stack
    ld a,0xca
    ld bc,0xcafe
    ld xde,0x12345678
    push a
    push bc
    push xde

    pop xde1
    pop rbc1
    pop ra1

    ; in different order
    push xde
    push a
    push bc

    pop rbc2
    pop ra2
    pop xde2

    cp a,ra1
    jp ne,bad_end
    cp a,ra2
    jp ne,bad_end
    cp bc,rbc1
    jp ne,bad_end
    cp bc,rbc2
    jp ne,bad_end
    cp xde,xde2
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0, 0,0,0,0, 0,0,0,0
stack:
    dw 0,0,0,0, 0,0,0,0
    end