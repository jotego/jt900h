    ; SBC (mem),R - SBC R,(mem)
    maxmode on
    relaxed on
    org 0

    ld xix, data

    ld WA,0xCAFD
    scf
    SBC (xix),wa
    jp ne,bad_end
    cpw (xix),0
    jp ne,bad_end

    add xix,2
    ld WA,0xbef0
    scf
    SBC wa,(xix)
    jp ne,bad_end
    cpw (xix),0xbeef
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end