    ; cpir over more than 256 bytes
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

    ld xiy,0x2000
    ld bc,0x200
    ld wa,0
    cpir a,(xiy+)
    jp ov,bad_end
    jp z,bad_end
    cp bc,0
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

    ld xiy,0x2000
    ld bc,0x200
    ld wa,0x150
    cpir wa,(xiy+)
    jp nov,bad_end
    jp nz,bad_end
    cp xiy,0x2000+0x150*2+2
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end