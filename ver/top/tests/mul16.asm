    ; Unsigned multiplying (16 bits)
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld wa,0x1223
    ld bc,0xaf56
    mul xwa,bc
    cp xwa,0x1223*0xaf56
    jp ne,bad_end

    ld bc,0xaf56
    mul xbc,wa
    cp xbc,0xaf56*0x04c2
    jp ne,bad_end

    ld de,0x3c58
    mul xde,bc
    cp xde,0x3c58*0x372c
    jp ne,bad_end

    ld hl,0x7fca
    mul xhl,de
    cp xhl,0x7fca*0x4720
    jp ne,bad_end

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
    end