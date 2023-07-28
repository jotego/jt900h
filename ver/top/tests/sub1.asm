 ; SUB 
    maxmode on
    relaxed on
    org 0
    ld xwa,0x7f
    ld xbc,0xff

    sub a,c
    cp a,0x80
    jp ne,bad_end


    ; Sub 16 bits
    ld xwa,0x7fff
    ld xbc,0xffff
    
    sub wa,bc
    cp wa,0x8000
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end