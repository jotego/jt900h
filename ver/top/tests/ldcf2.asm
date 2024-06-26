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

    ; LDCF #3,(mem)
    ld xix,data
    ld e,(xix)
    ldcf 0,(xix)
    jp c, bad_end
    ldcf 1,(xix)
    jp nc, bad_end
    or ra3,1

    ; LDCF A,(mem)
    ld A,0
    ldcf A,(xix)
    jp c, bad_end
    ld A,1
    ldcf A,(xix)
    jp nc, bad_end
    or ra3,2

    include finish.inc
    end