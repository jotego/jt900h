    ; POPSR
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xsp, stack
    ld wa,0x3ff
    push wa
    ld wa,0 ; clears the imm bus
    pop sr

    ld bc,3
    ld wa,0x2ff
    push wa
    ld wa,0 ; clears the imm bus
    pop sr

    ld bc,2
    ld wa,0x100
    push wa
    ld wa,0 ; clears the imm bus
    pop sr
    ld bc,1

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
stack:
    end