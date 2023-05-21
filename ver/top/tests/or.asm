    ; OR (mem),R  OR (mem),#
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,data
    ; OR (mem),#8
    ld a,1
    or (xix),3
    ld w,(xix)
    cp w,0xff
    jp ne,bad_end
    or ra3,1

    ; OR (mem),#16
    ld a,0
    orw (xix+2),0x10f0
    ld wa,(xix+2)
    cp wa,0x33f4
    jp ne,bad_end
    or ra3,2

    ; OR (mem),r
    incf
    ld wa,0x5533
    or (xix+6),wa
    ld bc,(xix+6)
    cp bc,0x5737
    jp ne,bad_end
    or ra3,4

    ; OR R,r
    incf
    ld a,3
    ld w,12
    or w,a
    cp w,15
    jp ne,bad_end
    or ra3,8

    include finish.inc
data:
    dw 0xcafe,0x2304,0xffff,0x1234,0xcccc
    end