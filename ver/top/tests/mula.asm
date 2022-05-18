    ; MULA: dst=dst+(XDE)*(XHL); XHL-=2
    ; dst is 32 bits
    ; (XDE) and (XHL), signed 16 bits
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xhl,0x402
    ld xde,0x600
    ldw (xhl),12432
    ldw (xhl-2),-24000
    ldw (xde),3
    ld xwa,54

    mula xwa
    cp xhl,0x400
    jp ne,bad_end
    or ra3,1

    cp xwa,37350
    jp ne,bad_end
    or ra3,2

    mula xwa
    jp pl,bad_end   ; minus flag must be set
    jp ov,bad_end   ; no overflow
    cp xhl,0x3fe
    jp ne,bad_end
    cp xwa,-34650
    jp ne,bad_end
    or ra3,4

end_loop:
    ld hl,0xbabe
    ldb (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
    align 2
    end