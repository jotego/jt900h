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

    incf
    pop xde
    pop bc
    pop a

    ; in different order
    push xde
    push a
    push bc

    incf
    pop bc
    pop a
    pop xde

    LDF 0
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

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0, 0,0,0,0, 0,0,0,0
stack:
    dw 0,0,0,0, 0,0,0,0
    end