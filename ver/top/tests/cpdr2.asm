    ; cpdr over more than 256 bytes
    maxmode on
    relaxed on
    org 0

    ld xiy,0x2000
    ld bc,0x200

    ; do not find a match, byte steps
    ld qd,1
    ld de,0x201
loop:
    ld (xiy+),de
    djnz bc,loop

    dec 1,xiy
    ld bc,0x200
    ld wa,0
    cpdr a,(xiy-)
    jp ov,bad_end
    jp z,bad_end
    cp bc,0
    jp ne,bad_end
    cp xiy,0x21ff
    jp ne,bad_end

    ; find a match, word steps
    ld xiy,0x2000
    ld bc,0x200

    ld qd,2
    ld de,0
loop2:
    ld (xiy+),de
    inc 1,de
    djnz bc,loop2

    dec 2,xiy
    ld bc,0x200
    ld wa,0x150
    cpdr wa,(xiy-)
    jp nov,bad_end
    jp nz,bad_end
    cp xiy,0x229e
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end