    ; LDD
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xhl,data+3*2
    ld xde,copy+3*2
    ld bc,4

    lddw (xde-),(xhl-)
    lddw (xde-),(xhl-)
    lddw (xde-),(xhl-)
    lddw (xde-),(xhl-)
    jp ov,bad_end

    cp bc,0
    jp ne,bad_end

    ; check the copy
    ld bc,4
    ld xhl,copy+3*2
    ld wa,0x2233
    cpdr wa,(xhl-)
    jp ne,bad_end
    cp bc,1
    jp ne,bad_end

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
    dw 0x0011,0x2233,0x4455,0x6677,0x8899,0x0000,0x0000,0x0000
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
copy:
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
    end