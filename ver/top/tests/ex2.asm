    ; ex (mem),r
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ld wa,0x1234
    ex (xix),a
    cp a,0xfe
    jp ne,bad_end
    cp (xix),0x34
    jp ne,bad_end

    ld qh,1
    ld b,(xix)
    cp (xix),0x34
    jp ne,bad_end

    ld qh,2
    incf
    ld bc,(xix+2)
    ld de,0xfea5

    ld qh,3
    ld wa,de
    ex (xix+2),wa
    cp wa,bc
    jp ne,bad_end

    ld qh,4
    ld wa,(xix+2)
    cp wa,de
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0x1234,0x5678,0x9abc
    end