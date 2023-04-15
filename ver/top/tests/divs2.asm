    ; divs RR,# positive / negative numbers
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ; 32-bit number divided by 16-bit number
    ld xwa,0x1234567
    divs xwa,-0x1234
    jp ov,bad_end
    cp wa,-0x1000
    jp ne,bad_end
    cp qwa,0x567
    jp ne,bad_end
    or ra3,0x1

    ; 16-bit number divided by 8-bit number
    ld bc,0x123
    divs bc,-0x12
    jp ov,bad_end
    cp c,-0x10
    jp ne,bad_end
    cp b,0x3
    jp ne,bad_end
    or ra3,0x2

end_loop:
    ldf 0
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0xcafe,0xbeef,0x1234,0x5678,0x9abc
    end