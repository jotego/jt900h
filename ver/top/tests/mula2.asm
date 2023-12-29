    ; MULA
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xde,0x1000
    ld xhl,0x2000

    ld qb,1
    ldw (xde),0
    ldw (xhl),0
    ld xix,0
    mula xix
    jp nz,bad_end
    jp mi,bad_end
    jp ov,bad_end
    cp xhl,0x2000-2
    jp ne,bad_end

    ld qb,2
    ldw (xde),2
    ldw (xhl),15
    ld xix,3
    mula xix
    jp mi,bad_end
    jp ov,bad_end
    cp xix,33
    jp ne,bad_end
    cp xhl,0x2000-4
    jp ne,bad_end

    ld qb,3
    ldw (xde),-315
    ldw (xhl),10
    ld xix,100000
    mula xix
    jp mi,bad_end
    jp ov,bad_end
    cp xix,100000-3150
    jp ne,bad_end
    cp xhl,0x2000-6
    jp ne,bad_end

    ld qb,4
    ldw (xde),-315
    ldw (xhl),1000
    ld xix,100000
    mula xix
    jp pl,bad_end
    jp ov,bad_end
    cp xix,100000-315000
    jp ne,bad_end
    cp xhl,0x2000-8
    jp ne,bad_end

    ld qb,5             ; overflow check
    ldw (xde),315
    ldw (xhl),1000
    ld xix,0x7fffffff
    mula xix
    jp pl,bad_end
    jp nov,bad_end
    cp xhl,0x2000-10
    jp ne,bad_end

    ld qb,5
    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
    end