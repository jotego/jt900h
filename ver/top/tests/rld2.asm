    maxmode on
    relaxed on
    org 0

    ld xix,data

    ld qe,1
    ld wa,0xf123
    ld (xix),a
    srl 8,wa

    rrd a,(xix)
    jp nov,bad_end
    cp (xix),0x12
    jp ne,bad_end
    cp a,0xf3
    jp ne,bad_end

    rld a,(xix)
    jp ov,bad_end
    cp (xix),0x23
    jp ne,bad_end
    cp a,0xf1
    jp ne,bad_end

    rrd a,(xix)
    cp (xix),0x12
    jp ne,bad_end
    rrd a,(xix)
    cp (xix),0x31
    jp ne,bad_end
    rrd a,(xix)
    cp (xix),0x23
    jp ne,bad_end

    rld a,(xix)
    cp (xix),0x31
    jp ne,bad_end
    rld a,(xix)
    cp (xix),0x12
    jp ne,bad_end
    rld a,(xix)
    cp (xix),0x23
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end