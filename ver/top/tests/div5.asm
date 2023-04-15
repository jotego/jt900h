    ; div RR,r overflow test
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ; 16-bit number divided by 8-bit number
    ld wa,37000
    ld de,2
    div wa,e
    jp nov,bad_end
    or ra3,0x1

    ; 32-bit number divided by 16-bit number
    ld xix,564200
    div xix,de
    jp nov,bad_end
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