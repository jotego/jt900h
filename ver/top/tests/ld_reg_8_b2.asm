    maxmode on
    relaxed on
    org 0
    ld wa,0xbf    ; common header

    ld qiy,0x1116
    cp qiy,0x1111
    jp z,bad_end
    ld wa,qiy

    ld qiz,0x1117
    cp qiz,0x1117
    jp nz,bad_end
    ld bc,qiz

    ld qsp,0x1118
    cp qsp,0x1113
    jp z,bad_end
    ld de,qsp

    ex wa,bc
    ex bc,de
    ex de,wa
    ex bc,de

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end