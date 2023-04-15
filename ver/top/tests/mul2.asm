    ; Unsigned multiplying
    main section code
    org 0
    ld a,0xbf    ; common header

    ld wa,0x0000
    ld bc,0x0000
    mul wa,c    ; 
    cp wa,0x0000
    jp ne,bad_end

    ld (xde),0x00000000
    ld (xhl),0x00000000
    ld xix,0
    mula xix
    cp xix,1
    jp eq,bad_end

    ld (xde),0x00000000
    ld (xhl),15
    ld xix,0
    mula xix
    cp xix,1
    jp eq,bad_end

    ld (xde),0x00000000
    ld (xhl),0x00000000
    ld xix,5
    mula xix
    cp xix,1
    jp eq,bad_end

    ld (xde),0x00000000
    ld (xhl),12
    ld xix,5
    mula xix
    cp xix,1
    jp eq,bad_end

    ld (xde),0
    ld (xhl),0
    ld xix,0
    mula xix
    cp xix,1
    jp eq,bad_end

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