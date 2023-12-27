    ; Some indexed addressing fetching from RAM
    maxmode on
    relaxed on
    org 0

    ; (r32)
    ld xwa,0x12345678
    lda xbc,(xwa)
    cp xbc,xwa
    jp ne,bad_end

    inc 1,xbc
    lda xde,(xbc)
    cp xde,xbc
    jp ne,bad_end

    inc 1,xde
    lda xhl,(xde)
    cp xde,xhl
    jp ne,bad_end

    inc 1,xhl
    lda xix,(xhl)
    cp xhl,xix
    jp ne,bad_end

    inc 1,xix
    lda xiy,(xix)
    cp xix,xiy
    jp ne,bad_end

    inc 1,xiy
    lda xiz,(xiy)
    cp xiy,xiz
    jp ne,bad_end

    inc 1,xiy
    lda xsp,(xiy)
    cp xiy,xsp
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end