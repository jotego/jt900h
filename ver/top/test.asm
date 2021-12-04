    main section code
    org 0
    ld w,0xff
    ld a,0xff
    ld b,0xff
    ld c,0xff
    ld d,0xff
    ld e,0xff
    ld h,0xff
    ld l,0xff
    nop
    ld ixl,0xff
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