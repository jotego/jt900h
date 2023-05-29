    ; SUB (mem),imm
    maxmode on
    relaxed on
    org 0
    ld xix,data
    ld wa,0
    sub (xix+4),0  ; 0xffff-0
    ld bc,(xix+4)
    cp bc,0xffff
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end