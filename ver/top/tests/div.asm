    ; div RR,r
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ; 16-bit number divided by 8-bit number
    ld wa,1230
    ld b,23
    div wa,b
    jp ov,bad_end
    or ra3,1

    cp a,53
    jp ne,bad_end
    or ra3,2

    cp w,11
    jp ne,bad_end
    or ra3,4

    ; 16-bit / 8-bit with overflow
    incf
    ld wa,1000
    ld b,2
    div wa,b
    jp nov,bad_end
    or ra3,8

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