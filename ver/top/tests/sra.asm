    maxmode on
    relaxed on
    org 0

    ; SRA #4,r
    ld qe,1
    ld xwa,0x89abcdef
    sra 2,a
    jp pl,bad_end
    jp ov,bad_end
    jp nc,bad_end
    cp a,0xfb
    jp ne,bad_end

    ld qe,2
    sra 16,wa
    jp nc,bad_end
    jp nov,bad_end
    cp wa,0xffff
    jp ne,bad_end

    ld qe,3
    and wa,0x7fff
    sra 14,wa
    jp nc,bad_end
    jp ov,bad_end
    cp wa,1
    jp ne,bad_end

    ld qe,4
    cp qwa,0x89ab
    jp ne,bad_end

    ; SRA A,r
    ld qe,5
    ld a,4
    sra a,qwa
    jp nc,bad_end
    jp ov,bad_end
    cp qwa,0xf89a
    jp ne,bad_end

    ld qe,6
    ld  a,0xf0
    sra a,qwa
    cp qwa,0xffff
    jp ne,bad_end

    ld qe,7
    and qwa,0x7fff
    ld  a,4
    sra a,qwa
    cp qwa,0x7ff
    jp ne,bad_end

    ; SRA<W> (mem)
    ld qe,8
    ld xix,data
    rcf
    sraw (xix)
    jp c,bad_end
    jp nov,bad_end
    cpw (xix),0xe57f
    jp ne,bad_end

    ld qe,9
    andw (xix),0x7fff
    rcf
    sraw (xix)
    jp nc,bad_end
    jp nov,bad_end
    cpw (xix),0x32bf
    jp ne,bad_end

    ld qe,0x10
    srab (xix)
    jp nc,bad_end
    cpb (xix),0xdf
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end