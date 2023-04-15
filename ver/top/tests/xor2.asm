    ; XOR (mem),R  XOR (mem),#
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ; XOR (mem),#8
    ld a,1
    xor (xix),3
    ld w,(xix)
    cp w,0xfd
    jp ne,bad_end
    xor ra3,1

    ; XOR (mem),#16
    ld a,0
    orw (xix+2),0x1050
    ld wa,(xix+2)
    cp wa,0x3354
    jp ne,bad_end
    xor ra3,2

    ; XOR (mem),r
    incf
    ld wa,0x5533
    xor (xix+6),wa
    ld bc,(xix+6)
    cp bc,0x4707
    jp ne,bad_end
    xor ra3,4

    ; XOR R,r
    incf
    ld a,3
    ld w,0x81
    xor w,a
    cp w,0x82
    jp ne,bad_end
    xor ra3,8

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0xcafe,0x2304,0xffff,0x1234,0xcccc
    end