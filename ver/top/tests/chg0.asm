    ; chg num, dst
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ; chg #3,(mem)
    ld xix,0x00000000
    ld a,(xix)
    chg 1,(xix)
    ld w,(xix)
    cp (xix),0x21
    jp eq,bad_end
    or ra3,1

    ; chg #3,(mem)
    incf
    ld xiy,(0x00)
    ld a,(xiy)
    chg 0,(xiy)
    ld w,(xiy)
    xor a,w
    cp a,1
    jp ne,bad_end
    or ra3,2
    decf

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end