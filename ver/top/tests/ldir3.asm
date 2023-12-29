    ; ldir over more than 256 bytes
    maxmode on
    relaxed on
    org 0

    ld xix,0x1000
    ld xiy,0
    ld bc,0x400

    ldir (xix+),(xiy+)
    jp ov,bad_end
    cp bc,0
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end