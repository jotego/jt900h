    ; POP<W> (mem)
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xsp,0x600
    ld xix,0x400

    ; Set known values to the RAM
    ld xwa,0
    ld (xix),xwa
    ld xwa,0x12345678
    ld (xsp),xwa
    sub xwa,xwa

    ld a,(xsp)
    ld xiy,xsp
    popb (xix)
    cpb (xix),0x78
    jp ne,bad_end
    sub xiy,xsp
    cp xiy,-1
    jp ne,bad_end

    ld w,(xix)
    or ra3,1

    inc 1,xsp
    inc 2,xix
    ld xiy,xsp
    popw (xix)
    cpw (xix),0x1234
    jp ne,bad_end
    sub xiy,xsp
    cp xiy,-2
    jp ne,bad_end

    ld bc,(xix)
    or ra3,2

    include finish.inc
    align 2
    end