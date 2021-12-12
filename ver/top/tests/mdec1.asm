    ; Module decrement 1
    main section code
    org 0
    ld a,0xbf    ; common header

    ld wa,0x1f
    mdec1 4,wa
    ld b,a
    mdec1 4,wa
    ld c,a
    mdec1 4,wa
    ld d,a
    mdec1 4,wa
    ld e,a
    mdec1 4,wa
    ld h,a
test_end:
    ld (0xffff),0xff
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end