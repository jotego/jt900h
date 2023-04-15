    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ; ORCF-ANDCF #3,(mem) 
    
    ld xix,(data)
    ld xiy,(data+2)
    ld xiz,(data+4)

    orcf 1,(xix)
    jp nc,bad_end
    and a,1

    andcf 0,(xix)
    jp c,bad_end
    or b,1

    orcf 2,(xiy)
    jp c,bad_end
    or w,1

    orcf 7,(xiz)
    jp c,bad_end
    or c,1

    andcf 2,(xix)
    jp c,bad_end
    or e,1

    andcf 7,(xiz)
    jp c,bad_end
    or d,1

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
    end