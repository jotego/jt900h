    ; load to memory
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xiy, data
    ld a,0x34
    ld (xiy),a
    ld b,(xiy)
    cp b,a
    jp ne,bad_end

    ld wa,0x0fea
    ld (xiy),wa
    ld de,(xiy)
    cp de,0x0fea
    jp ne,bad_end

    incf
    ld xde,0x12345678
    ld (xiy),xde
    ld xbc,(xiy)
    cp xbc,0x12345678
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end