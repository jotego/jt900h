    ; CPL
    maxmode on
    relaxed on
    org 0

    ld a,0x10
    ld w,3
    cp a,w
    jp eq, bad_end
    jp lt, bad_end
    jp le, bad_end
    jp ult, bad_end
    jp ov, bad_end

    ld qh,1
    ld w,0x10
    ld a,0x11
    cp w,a
    jp eq,bad_end
    jp pl,bad_end
    jp nc,bad_end
    jp ov,bad_end

    ld qh,2
    ld a,10
    dec 1,a
    cp a,9
    jp ne,bad_end

    ld qh,3
    ld a,0x80
    ld b,1
    cp a,b
    jp eq,bad_end
    jp nov,bad_end

    ld qh,4
    ld xix,data
    ld a,(xix)
    ld w,0x10
    cp a,w
    jp eq,bad_end
    cp a,(xix)
    jp ne,bad_end

    ld qh,5
    ld wa,(xix)
    ld de,(xix)
    cp wa,de
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end