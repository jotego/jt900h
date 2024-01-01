    ; ldir over more than 256 bytes
    maxmode on
    relaxed on
    org 0

    ld xix,0x1000
    ld xiy,0x2000
    ld bc,0x200

    ld wa,0
    ld de,0
loop:
    ld (xix+),wa
    ld (xiy+),de
    inc 1,de
    djnz bc,loop

    ld xix,0x1000
    ld xiy,0x2000
    ld bc,0x200
    ldirw (xix+),(xiy+)

    ld qh,1
    jp ov,bad_end

    ld qh,2
    cp bc,0
    jp ne,bad_end

    ld qh,3
    cp xix,0x1400
    jp ne,bad_end

    ld qh,4
    cp xiy,0x2400
    jp ne,bad_end

    ; check the contents
    ld xix,0x1000
    ld xiy,0x2000
    ld bc,0x400
loop2:
    ld a,(xix+)
    cp a,(xiy+)
    jp ne,bad_end
    djnz bc,loop2

    ld qh,0
    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end