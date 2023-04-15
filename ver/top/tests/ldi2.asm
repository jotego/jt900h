    ; LDD
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xiy,data
    ld xix,copy
    ld bc,4

    ldiw (xix+),(xiy+)
    ldiw (xix+),(xiy+)
    ldiw (xix+),(xiy+)
    ldiw (xix+),(xiy+)
    jp ov,bad_end

    cp bc,0
    jp ne,bad_end

    ; check the copy
    ld bc,4
    ld xiy,data+3*2
    ld xix,copy+3*2
loop:
    ld wa,(xiy)
    sub xiy,2
    cpd wa,(xix-)
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
copy:
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
    end