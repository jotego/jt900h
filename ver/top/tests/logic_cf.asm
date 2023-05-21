    ; Arithmetic operations that read & write to memory
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    jp c,bad_end
    ld bc,0xaa55

    orcf 0,bc
    jp nc,bad_end
    or e,1

    ld a,1
    andcf a,bc
    jp c,bad_end
    or e,2

    lda xix,data
    xorcf 1,(xix)
    jp nc,bad_end
    or e,4

    ld a,0
    andcf a,(xix)
    jp c,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end