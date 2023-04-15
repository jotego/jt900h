    ; ex (mem),r
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ld wa,0x1234
    ex (xix),a
    cp a,0xfe
    jp ne,bad_end
    or ra3,1

    ld b,(xix)
    cp (xix),0x34
    jp ne,bad_end
    or ra3,2

    incf
    ld bc,(xix+2)
    ld de,0xfea5

    ld wa,de
    ex (xix+2),wa
    cp wa,bc
    jp ne,bad_end
    or ra3,4

    ld wa,(xix+2)
    cp wa,de
    jp ne,bad_end
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