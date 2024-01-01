    ; TSET
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ; TSET #4,r
    ld a,2
    tset 1,a
    jp z,bad_end
    cp a,2
    jp ne,bad_end

   ; TSET #4,r
    ld a,0x00
    tset 0,a
    cp wa,1
    jp ne,bad_end

    ;TSET #3,(mem)
    ld (0xfc),0x00
    ld (0xfd),0x00
    ld (0xfe),0x00
    ld (0xff),0x00
    ld (0x100),0x00
    ld (0x101),0x00
    ld (0x102),0x00
    tset 1,(0xff)
    jp nz,bad_end
    ld xbc,(0xff)
    cp (0xff),0x02
    jp ne,bad_end

    ; TSET #3,(#16)
    ldw (0xfff),0x5678
    ldw (0xfff+2),0x1234
    tset 0,(0xfff)
    jp nz,bad_end
    ld xde,(0xfff)
    cp xde,0x12345679
    jp ne,bad_end
    cpb (0xfff),0x79
    jp ne,bad_end

end_loop:
    ldf 0
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end