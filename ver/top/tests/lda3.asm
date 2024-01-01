    ; Some indexed addressing fetching from RAM
    maxmode on
    relaxed on
    org 0

    ; (#8)
    lda xbc,(0x23)
    cp xbc,0x23
    jp ne,bad_end

    ; (#16)
    lda xbc,(0x2300)
    cp xbc,0x2300
    jp ne,bad_end

    ; (#24)
    lda xbc,(0x230000)
    cp xbc,0x230000
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end