    ; load using full register names
    main section code
    org 0
    ld xwa0,0x12345678
    ld xbc0,0x9abcdef0
    ld xde0,0x87654321
    ld xhl0,0x0fedcba9

    ld xwa1,0x10110678
    ld xbc1,0x90110ef0
    ld xde1,0x80110321
    ld xhl1,0x00110ba9

    ld xwa2,0x10220678
    ld xbc2,0x90220ef0
    ld xde2,0x80220321
    ld xhl2,0x00220ba9

    ld xwa3,0x10330678
    ld xbc3,0x90330ef0
    ld xde3,0x80330321
    ld xhl3,0x00330ba9

    ld xix,0x12345678
    ld xiy,0x9abcdef0
    ld xiz,0x87654321
    end