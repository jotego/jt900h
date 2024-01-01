    ; LDDR2, uses byte transfers instead of words
    maxmode on
    relaxed on
    org 0

    ld a,0xbf    ; common header

    ld xhl,data
    ld xde,0x400
    ld bc,8

    ldirb (xde+),(xhl+)
    jp ov,bad_end

    cp bc,0
    jp ne,bad_end

    ; check the 0x400
    ld bc,4
    ld xhl,data+3*2
    ld xde,0x400+3*2
loop:
    ld wa,(xhl)
    sub xhl,2
    cpd wa,(xde-)
    jp ne,bad_end
    cp bc,0
    jp ne,loop

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
    end