    ; long word write to odd address
    maxmode on
    relaxed on
    org 0

    ; write some data, of which part should not get overwritten
    ld wa,0xbaba
    ld (0xb14),wa
    ld (0xb16),wa
    ld (0xb18),wa
    ld xix,0xb15
    ld xwa,0x12345678

    ld (xix+),xwa
    ld bc,(0xb14)
    cp bc,0x78ba
    jp ne,bad_end

    ld bc,(0xb16)
    cp bc,0x3456
    jp ne,bad_end

    ld bc,(0xb18)
    cp bc,0xba12
    jp ne,bad_end

    ; try with a 16-bit word
    ld wa,0xbaba
    ld (0xb14),wa
    ld (0xb16),wa
    ld (0xb18),wa
    ld xix,0xb15
    ld xwa,0x1234
    ld (xix+),wa

    ld bc,(0xb14)
    cp bc,0x34ba
    jp ne,bad_end

    ld bc,(0xb16)
    cp bc,0xba12
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end