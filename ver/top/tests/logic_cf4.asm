    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ld a,4
    ld bc,4

    orcf a,(xix)     ; value in xix -> fe
    jp nc,bad_end
    rcf
    or e,1

    orcf a,(xix+2)   ; value in xix+2 -> ef
    jp c, bad_end
    or c, 1

    xorcf a,(xix+bc) ; vale in xix+bc (xix+4) -> ff
    jp nc,bad_end
    or e,a

    ld c,1

    xorcf a,(xix+)   ; value in xix -> ca; xix=xix+1
    jp nc,bad_end
    or c,a

    cp xix,data+1
    jp ne,bad_end

    ld xwa,data+2
    ldw (xwa),0xa5
    ld bc,(xwa)
    rcf
    xorcf 2,(xwa+)
    jp nc,bad_end
    sll de

    cp xwa,data+3
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end