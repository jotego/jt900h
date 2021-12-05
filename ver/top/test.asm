    main section code
    org 0
    ld w,0xf0
    ld a,0xf1
    ld b,0xf2
    ld c,0xf3
    ld d,0xf4
    ld e,0xf5
    ld h,0xf6
    ld l,0xf7
    nop
    ld ixl,0xbe
    nop
    ld a,b
    ld ra2,b
    nop
    ld a,0xff
    ld wa,0x1234
    ld xwa,0x12345678
    nop
    ld ra0,0xff
    ld rwa0,0x1234
    ld xwa0,0x12345678
    end