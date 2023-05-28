    ; ADD (mem),R
    maxmode on
    relaxed on
    org 0
    nop
    nop
    jr t,odd_addr
    push xbc
    push xix
    push xiy
odd_addr:
    push xwa    ; this push may not be executed because of the jump to and odd address
    nop         ; many nops to recovers the code flow if the PC fails
    nop
    nop
    nop
    cp xsp,$100
    jp eq,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end