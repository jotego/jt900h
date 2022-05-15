    ; Some indexed addressing
    main section code
    org 0
    ld a,5
    ld xix,data
    ld wa,(data)
    ld bc,(data+2)
    ld de,(xix)
    nop
    nop
    nop
    nop
    nop
    nop
forever:
    ld (0xffff),0xff
    jp forever
data:
    dw 0xcafe,0xbeef,0x1234,0x6789,0xabcd
    end