    maxmode on
    relaxed on
    org 0

    ld qe,1
    ld xwa,0xffc000
    sll 2,wa
    jp nc,bad_end
    jp nz,bad_end

    ld qe,2
    ld xwa,0xffc000
    sll 2,qwa
    jp c,bad_end
    jp z,bad_end
    cp qwa,0x3fc
    jp ne,bad_end

    ld qe,3
    ld wa,1
    rcf
    sll 16,wa
    jp nc,bad_end
    jp nz,bad_end
    cp wa,0
    jp ne,bad_end

    ld qe,3
    ld xwa,0x1
    sll 4,xwa
    cp xwa,0x10
    jp ne,bad_end

    ld qe,4
    sll 7,xwa
    cp xwa,0x800
    jp ne,bad_end

    ld qe,5
    sll 4,xwa
    cp xwa,0x8000
    jp ne,bad_end
    jp c,bad_end

    ld qe,6
    sll 16,xwa
    cp xwa,0x80000000
    jp ne,bad_end
    jp c,bad_end

    ld qe,7
    sll 1,xwa
    jp nc,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end