    ; write to memory at even/odd addresses
    maxmode on
    relaxed on
    org 0

    ld xix,0x400
    ld xwa,0x12345678

    ; write to even address
    ld xbc,0
    ld (xix),xwa
    ld xbc,(xix)
    cp xbc,xwa
    jp ne,bad_end

    ; write to odd address
    ld xbc,0
    ld (xix+1),xwa
    ld xbc,(xix+1)
    cp xbc,xwa
    jp ne,bad_end

    include finish.inc
    end