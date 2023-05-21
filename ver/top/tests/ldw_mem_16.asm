    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,(data+2)
    ld xwa,0x1234

    ld (xix),(65535)
    ld (xde),(4095)
    ld (xbc),(255)
    ld (xwa),(15)

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end