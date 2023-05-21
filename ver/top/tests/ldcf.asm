    ; Load carry flag
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header
    jp test

data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
test:
    ; LDCF #4, r
    ld wa,0x115
    ldcf 0,a

    ld b,0
    adc b,0
    cp b,1
    jp ne,bad_end

    ldcf 1,a
    jp c,bad_end

    ldcf 8,wa
    jp nc,bad_end
    or ra3,1

    ; LDCF A,r
    ld bc,0xa55
    ld A,1
    ldcf A,c
    jp c,bad_end

    ld A,11
    ldcf A,bc
    jp nc,bad_end
    or ra3,2

    include finish.inc
    end