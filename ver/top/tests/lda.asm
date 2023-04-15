    ; Some indexed addressing fetching from RAM
    maxmode on
    relaxed on
    org 0
    ld  hl,0x5005
    lda xiy,data
    ld  wa,(xiy)
    ld  bc,(xiy+2)
    ld xde,(xiy)
    nop
    nop
    nop
    nop
    nop
forever:
    ld (0xffff),0xff
    jp forever
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end