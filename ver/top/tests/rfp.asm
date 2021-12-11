    ; control of the rfp
    main section code
    org 0
    ld wa,0x1234    ; common header
    ; actual test:
    ld wa,0x0000
    ld bc,0x0011
    ld de,0x0022
    ld hl,0x0033
    decf
    ld wa,0x3000
    ld bc,0x3011
    ld de,0x3022
    ld hl,0x3033
    decf
    ld wa,0x2000
    ld bc,0x2011
    ld de,0x2022
    ld hl,0x2033
    incf
    incf
    incf
    ld wa,0x1000
    ld bc,0x1011
    ld de,0x1022
    ld hl,0x1033
    nop
    nop
    nop
    nop
forever:
    jp forever
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end