    ; Module decrement 1
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld wa,0x00
    mdec1 4,wa
    ld wa,0x00
    mdec2 4,wa
    ld wa,0x00
    mdec4 8,wa

test_end:
    ld (0xffff),0xff
    jp test_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end