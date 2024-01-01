    ; Some indexed addressing fetching from RAM
    maxmode on
    relaxed on
    org 0

    ; (r32+d8) signed
    ld xwa,0x12345678
    lda xbc,(xwa+0x23)
    add xwa,0x23
    cp xbc,xwa
    jp ne,bad_end

    ld xwa,0x12345678
    lda xbc,(xwa-0x23)
    sub xwa,0x23
    cp xbc,xwa
    jp ne,bad_end

    ; (r32+d16) signed
    ld xwa,0x12345678
    lda xbc,(xwa+0x2300)
    add xwa,0x2300
    cp xbc,xwa
    jp ne,bad_end

    ld xwa,0x12345678
    lda xbc,(xwa-0x2300)
    sub xwa,0x2300
    cp xbc,xwa
    jp ne,bad_end


    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end