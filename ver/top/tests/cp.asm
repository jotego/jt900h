    ; CPL
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0x10
    ld w,3
    cp a,w
    jp eq, bad_end

    or b,1
    ld w,0x10
    cp w,a
    jp ne,bad_end

    or b,2
    cp a,9
    jp eq,bad_end

    or b,4
    cp a,0x10
    jp ne,bad_end

    or b,8
    ld xix,data
    ld a,(xix)
    ld w,0x10
    cp a,w
    jp eq,bad_end

    or b,0x10
    ld a,(xix)
    ld w,9
    cp a,w
    jp eq,bad_end

    or b,0x20
    ld wa,(xix)
    ld de,(xix)
    cp wa,de
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end