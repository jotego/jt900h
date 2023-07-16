    ; ex
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    neg ix          ; Zero and Negative to 1
    ex f,f'
    jp c,bad_end
    or b,15

    scf
    ex f,f'

    ccf
    andcf 1,b       ; Carry flag to 1
    ex f,f'
    jp nc,bad_end

    ld xwa,0x000000
    bit 2,wa       ; Half carry flag to 1
    ex f,f'

    ld a,0xff
    ld c,0xff
    or a,c
    ex f,f'

    rcf
    ex f,f'

    sub b,a
    ex f,f'

    ld a,1

    include finish.inc
data:
    dw 0xcafe,0xbeef,0x1234,0x5678,0x9abc
    end