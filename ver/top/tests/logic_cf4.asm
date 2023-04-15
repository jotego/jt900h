    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,(data) 
    ld a,4
    ld bc,4

    orcf a,(xix)     ; value in xix -> fe
    jp c,bad_end
    or e,1
    
    orcf a,(xix+2)   ; value in xix+2 -> ef
    jp nc, bad_end
    or c, 1

    xorcf a,(xix+bc) ; vale in xix+bc (xix+4) -> ff
    jp nc,bad_end
    or e,a

    ld c,1

    xorcf a,(xix+)   ; value in xix -> ca; xix=xix+1
    jp c,bad_end
    or c,a

    xorcf 3,(xwa)
    jp c,bad_end
    or a,1

    incf

    xorcf 2,(xwa)
    jp c,bad_end
    or a,5

    decf
    
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